require_relative 'contract_symbols'
require 'test/unit'

module BasicContracts
	include ContractSymbols
	include Test::Unit::Assertions

	def included(type)
		create_generic_postcondition_failure(type)
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
					"Returned #{result} for the following #{type}:\n" \
					"#{self}"
				else
					"#{method_name} returned an incorrect result.\n" \
					"Returned #{result} for the following #{type} and args:\n" \
					"#{type}: #{self}; Arguments: #{args}"
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

