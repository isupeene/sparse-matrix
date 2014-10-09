require 'test/unit'
require_relative 'contract_symbols'

module Contract
	include Test::Unit::Assertions
	include ContractSymbols

	# This method enters the scope of any module which extends Contract
	# and will be called when that module is included in the target class.
	# Ensures that all contracts are checked in the target class.
	def included(type)
		require_method_invariants(type)
		require_preconditions(type)
		require_postconditions(type)
		require_class_invariant(type)
	end

	@@evaluating_contract = false
	def self.evaluate
		unless @@evaluating_contract
			begin
				@@evaluating_contract = true
				yield
			ensure
				@@evaluating_contract = false
			end
		end
	end

	# Decorates all instance methods of the target type with
	# the class invariant.
	def require_class_invariant(type)
		type.instance_methods.each do |symbol|
			method = type.instance_method(symbol)
			
			type.send(:define_method, symbol) do |*args, &block|
				Contract.evaluate{ invariant } unless symbol == :initialize
				result = method.bind(self).call(*args, &block)
				Contract.evaluate{ invariant }
				result
			end
		end
	end

	# Identifies all precondition methods in the target type,
	# and decorates the appropriate methods with them.
	def require_preconditions(type)
		override_matching_instance_methods(type, PRECONDITION_SUFFIX) \
		do |instance, contract, method, *args, &block|
			Contract.evaluate {
				contract.bind(instance).call(*args, &block)
			}
			method.bind(instance).call(*args, &block)
		end
	end

	# Identifies all postcondition methods in the target type,
	# and decorates the appropriate methods with them.
	def require_postconditions(type)
		override_matching_instance_methods(type, POSTCONDITION_SUFFIX) \
		do |instance, contract, method, *args, &block|
			result = method.bind(instance).call(*args, &block)
			Contract.evaluate {
				contract.bind(instance).call(*args << result, &block)
			}
			result
		end
	end
	
	# Identifies all method invariants in the target type,
	# and decorates the appropriate methods with them.
	def require_method_invariants(type)
		override_matching_instance_methods(type, INVARIANT_SUFFIX) \
		do |instance, contract, method, *args, &block|
			if @@evaluating_contract
				method.bind(instance).call(*args, &block)
			else
				result = nil
				@@evaluating_contract = true
				# NOTE: The method invariant cannot be passed the same
				# block that is passed to the function, since it
				# needs to be passed this block which evaluates
				# the function an assigns it to result.
				# As a result, method invariants may not see the
				# block arguments to the function under contract.
				begin
					contract.bind(instance).call(*args) {
						@@evaluating_contract = false
						result = method.bind(instance).call(*args, &block)
						@@evaluating_contract = true
					}
				ensure
					@@evaluating_contract = false
				end
				result
			end
		end
	end

	# Identifies instance methods matching the specified pattern,
	# and replaces them with the code in the specified block.
	# The original method will be passed to the override block as a block.
	def override_matching_instance_methods(type, primary_suffix, &override)
		["", "?", "!", "="].each do |secondary_suffix|
			matching_instance_methods(
				type,
				primary_suffix + secondary_suffix
			) \
			do |contract, method|
				type.send(:define_method, method.name) \
				do |*args, &block|
					override.call(
						self, contract, method, *args, &block
					)
				end
			end
		end
	end

	# Yields a sequence of instance methods in the target type
	# matching the specified pattern.
	def matching_instance_methods(type, contract_suffix)
		type.instance_methods.select {
			|m| m.to_s.end_with?(contract_suffix)
		}.each \
		do |contract|
			method = type.instance_method(method_name(contract.to_s))
			yield type.instance_method(contract), method
		end
	end
end
