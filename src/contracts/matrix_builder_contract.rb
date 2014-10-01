require_relative 'contract'
require_relative 'matrix_contract'
require 'test/unit'

module MatrixBuilderContract
	extend Contract
	include Test::Unit::Assertions

	def invariant
		# TODO: class invariant
	end

	#########################
	# Common Error Messages #
	#########################

	def generic_postcondition_failure(method_name, result, *args)
		if args.length == 0
			"#{method_name} returned an incorrect result.\n" \
			"Returned #{result} for the following matrix builder:\n" \
			"#{self}"
		else
			"#{method_name} returned an incorrect result.\n" \
			"Returned #{result} for the following matrix " \
			"builder and args:\n" \
			"Builder: #{self}; Arguments: #{args}"
		end
	end 

	##############
	# Properties #
	##############

	def row_size_postcondition(result)
		assert(
			result.is_a?(Integer) && result >= 0,
			generic_postcondition_failure(:row_size, result)
		)
	end

	const "row_size"

	def column_size_postcondition(result)
		assert(
			result.is_a?(Integer) && result >= 0,
			generic_postcondition_failure(:column_size, result)
		)
	end

	const "column_size"

	##################
	# Element Access #
	##################

	def op_element_access_postcondition(i, j, result)
		assert(
			result.is_a?(Numeric),
			generic_postcondition_failure(:[], result)
		)
	end

	require_argument_types "[]", [Integer], [Integer]
	const "[]"

	def op_element_mutation_postcondition(i, j, value, result)
		assert(
			self[i, j] == value,
			"[]= did not properly set element #{i}, #{j}.\n" \
			"Set value to #{value}, but got #{self[i, j]}"
		)

		assert_equal(
			value,
			result,
			generic_postcondition_failure(:[]=, result, value)
		)
	end

	require_argument_types "[]=", [Integer], [Integer], [Numeric]

	############
	# Equality #
	############

	def op_equal_postcondition(value, result)
		assert_equal(
			value.kind_of?(MatrixBuilderContract) &&
			row_size == value.row_size &&
			column_size == value.column_size &&
			row_size.times.all? { |i|
				column_size.times.all? { |j|
					self[i, j] == value[i, j]
				}
			},
			result,
			generic_postcondition_failure(:==, result, value)
		)
	end

	const "=="

	##############
	# Conversion #
	##############

	def to_mat_postcondition(result)
		assert(
			result.kind_of?(MatrixContract),
			"to_mat didn't return a matrix!  Returned a #{result.class}."
		)

		assert(
			row_size == result.row_size &&
			column_size == result.column_size &&
			result.each_with_index.all?{ |x, i, j| x == self[i, j] },
			generic_postcondition_failure(:to_mat, result)
		)
	end

	const "to_mat"
end
