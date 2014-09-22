require 'test/unit'
require './contracts/contract_symbols'

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
	end

	def require_preconditions(type)
		override_matching_instance_methods(type, PRECONDITION_SUFFIX) \
		do |instance, contract, method, *args|
			instance.invariant
			contract.bind(instance).call(*args)
			method.bind(instance).call(*args)
		end
	end

	def require_postconditions(type)
		override_matching_instance_methods(type, POSTCONDITION_SUFFIX) \
		do |instance, contract, method, *args|
			result = method.bind(instance).call(*args)
			contract.bind(instance).call(*args << result)
			instance.invariant
			result
		end
	end

	def require_method_invariants(type)
		override_matching_instance_methods(type, INVARIANT_SUFFIX) \
		do |instance, contract, method, *args|
			result = nil
			contract.bind(instance).call(*args) {
				result = method.bind(instance).call(*args)
			}
			result
		end
	end

	def override_matching_instance_methods(type, primary_suffix)
		["", "?", "!", "="].each do |secondary_suffix|
			matching_instance_methods(
				type,
				primary_suffix + secondary_suffix
			) \
			do |contract, method|
				type.send(:define_method, method.name) \
				do |*args|
					yield self, contract, method, *args
				end
			end
		end
	end

	def matching_instance_methods(type, contract_suffix)
		type.instance_methods.select {
			|m| m.to_s.end_with?(contract_suffix)
		}.each \
		do |contract|
			method = type.instance_method(method_name(contract.to_s))
			yield type.instance_method(contract), method
		end
	end

	# Dynamically add new contracts to the derived module.
	# This enables a module that extends the Contract module to
	# define keyword-style contracts for its own use.
	# An example of this, 'const', is defined below.

	def add_invariant_contract(method_name, &block)
		invariant_method_name = invariant_name(method_name)

		if method_defined?(invariant_method_name)
			original_method = instance_method(invariant_method_name)
			define_method(invariant_method_name) do |*args, &b|
				block.call(self, *args) {
					original_method.bind(self).call(*args, &b)
				}
			end
		else
			define_method(invariant_method_name) do |*args, &b|
				block.call(self, *args, &b)
			end
		end
	end

	def add_precondition_contract(method_name, &block)
		add_pre_or_postcondition_contract(
			method_name, precondition_name(method_name), &block
		)
	end

	def add_postcondition_contract(method_name, &block)
		add_pre_or_postcondition_contract(
			method_name, postcondition_name(method_name), &block
		)
	end

	def add_pre_or_postcondition_contract(method_name, contract_name, &block)
		if method_defined?(contract_name)
			original_method = instance_method(contract_name)
			define_method(contract_name) do |*args|
				block.call(self, *args)
				original_method.bind(self).call(*args)
			end
		else
			define_method(contract_name) do |*args|
				block.call(self, *args)
			end
		end
	end

	def const(method_name)
		add_invariant_contract(method_name) do |instance, *args, &block|
			old_value = instance.clone
			block.call
			assert_equal(
				old_value, instance,
				"const method #{instance.class.name}.#{method_name} " \
				"modified instance.\n"
			)
		end
	end
end

