require_relative 'matrix_contract'

# It's dumb, because nobody should need mutable matrices when
# you have a proper builder pattern.
module DumbMatrixContract
	include MatrixContract

	def op_element_mutation_precondition(i, j, value)
		op_element_access_precondition(i, j)

		assert(
			i >= -row_size && i < row_size &&
			j >= -column_size && i < column_size,
			"Indices were out of range.\n" \
			"#{i} and #{j} for matrix of size #{row_size}, #{column_size}"
		)

		assert(
			value.is_a?(Numeric),
			"Matrices can only contain numeric values. " \
			"Got a #{value.class}"
		)
	end

	def op_element_mutation_postcondition(i, j, value)
		assert_equal(
			self[i, j],
			value,
			"[]= didn't set the value properly."
		)
	end
end
