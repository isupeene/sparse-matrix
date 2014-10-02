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
		create_generic_postcondition_failure(type)

		add_contract_evaluation_methods(type)
	end

	# Adds the contract evaluation guards to the target class,
	# which is necessary for avoiding deep recursion when
	# evaluating contracts.
	def add_contract_evaluation_methods(type)
		class << type
			attr_accessor :evaluating_contract

			def evaluate_contract
				unless self.evaluating_contract
					self.evaluating_contract = true
					begin
						yield
					ensure
						self.evaluating_contract = false
					end
				end
			end
		end
	end

	# Decorates all instance methods of the target type with
	# the class invariant.
	def require_class_invariant(type)
		type.instance_methods.each do |symbol|
			method = type.instance_method(symbol)
			
			type.send(:define_method, symbol) do |*args, &block|
				type.evaluate_contract{ invariant }
				result = method.bind(self).call(*args, &block)
				type.evaluate_contract{ invariant }
				result
			end
		end
	end

	# Identifies all precondition methods in the target type,
	# and decorates the appropriate methods with them.
	def require_preconditions(type)
		override_matching_instance_methods(type, PRECONDITION_SUFFIX) \
		do |instance, contract, method, *args, &block|
			type.evaluate_contract {
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
			type.evaluate_contract {
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
			if type.evaluating_contract
				method.bind(instance).call(*args, &block)
			else
				result = nil
				type.evaluating_contract = true
				# NOTE: The method invariant cannot be passed the same
				# block that is passed to the function, since it
				# needs to be passed this block which evaluates
				# the function an assigns it to result.
				# As a result, method invariants may not see the
				# block arguments to the function under contract.
				begin
					contract.bind(instance).call(*args) {
						type.evaluating_contract = false
						result = method.bind(instance).call(*args, &block)
						type.evaluating_contract = true
					}
				ensure
					type.evaluating_contract = false
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

	# Dynamically add new contracts to the derived module.
	# This enables a module that extends the Contract module to
	# define keyword-style contracts for its own use.
	# An example of this, 'const', is defined below.

	# Adds the specified block as a method invariant for the
	# specified method.
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

	# Adds the specified block as a precondition for the
	# specified method.
	def add_precondition_contract(method_name, &block)
		add_pre_or_postcondition_contract(
			method_name, precondition_name(method_name), &block
		)
	end

	# Adds the specified block as a postcondition for the
	# specified method.
	def add_postcondition_contract(method_name, &block)
		add_pre_or_postcondition_contract(
			method_name, postcondition_name(method_name), &block
		)
	end

	# Factors out the commonalities between adding pre- and postconditions.
	# Don't get confused because the block is always being called before
	# the original method - the original method is just another contract,
	# not the actual function under contract.
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
	
	def create_generic_postcondition_failure(type)
		name = "generic_postcondition_failure"
		unless type.method_defined?(name)
			type.send(:define_method, name) do |method_name, result, *args|
				if args.length == 0
					"#{method_name} returned an incorrect result.\n" \
					"Returned #{result} for the following #{type.class}:\n" \
					"#{self}"
				else
					"#{method_name} returned an incorrect result.\n" \
					"Returned #{result} for the following #{type.class} and args:\n" \
					"#{type.class}: #{self}; Arguments: #{args}"
				end
			end
		end
	end

	# Adds a method invariant specifying that the instance is not
	# changed by the execution of a function.
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

	# Checks to make sure that the value is of the specified type.
	def satisfies_type_restriction?(value, type)
		if type.is_a?(Module)
			return value.kind_of?(type)
		else
			return value.is_a?(type)
		end
	end

	# Ensures that the specified operation can be executed
	# between the two specified values using coercion.
	#
	# TODO: It's probably more elegant and idiomatic to pass
	# symbols around, and call to_s on them when necessary,
	# rather than passing strings around and calling to_sym.
	def can_execute_with_coercion?(op, value, instance)
		begin
			op.to_sym.to_proc.call(*value.coerce(instance))
			return true
		rescue
			return false
		end
	end

	# Adds a precondition to the specified method requiring that
	# the args are of the specified types.  An array of types (or
	# preferably, contracts) are specified for each type.  An empty
	# array indicates no type restrictions.
	def require_argument_types(method_name, *types)
		add_precondition_contract(method_name) do |instance, *args|
			args.each.with_index do |arg, i|
				assert(
					types.empty? ||
					types[i].any? { |type|
						satisfies_type_restriction?(arg, type)
					},
					"Argument #{i} to #{method_name} must be of\n" \
					"one of the following types or satisfy one of\n" \
					"the following contracts: #{types}.\n" \
					"Got #{arg.class}"
				)
			end
		end
	end

	# Like require_argument_types, except only a single array of types
	# (for the single operand) is specified, and if the type does not
	# satisfy the conditions, it will still pass if the operation will
	# succeed using coercion.
	def require_operand_types(op_name, *types)
		add_precondition_contract(op_name) do |instance, operand|
			assert(
				types.any? { |type|
					satisfies_type_restriction?(operand, type)
				} ||
				can_execute_with_coercion?(op_name, operand, instance),
				"The operand to #{op_name} must belong to one of the\n" \
				"following types or satisfy one of the\n" \
				"following contracts: #{types}, or be coercible\n" \
				"into a compatible type. Got #{operand.class}"
			)
		end
	end

	# Checks to see if a value can be cloned in a useful way.
	def cloneable(value)
		begin
			return value.clone == value
		rescue
			return false
		end
	end

	# Checks all args to see if they are clonable, and
	# returns the cloneable args alongside the cloned args.
	def clone_if_possible(args, arg_indices)
		cloneable_args = arg_indices
			.map{ |i| args[i] }
			.select{ |x| cloneable(x) }

		return cloneable_args, cloneable_args.map{ |x| x.clone }
	end

	# Adds a method invariant to the specified method that ensures that
	# the arguments at all the specified indices are not altered by
	# execution of the method.
	def const_arguments(method_name, *arg_indices)
		add_invariant_contract(method_name) do |instance, *args, &block|
			arg_indices = arg_indices.empty? ?
				(0...args.length).to_a :
				arg_indices

			cloneable_args, cloned_args =
				clone_if_possible(args, arg_indices)

			block.call

			assert_equal(
				cloned_args,
				cloneable_args,
				"The following args were supposed to remain const\n" \
				"during #{method_name}: #{cloneable_args}.\n" \
				"They were modified to #{cloned_args} instead."
			)
		end
	end
end

