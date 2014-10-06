require_relative 'contract'
require_relative 'contracts'
require 'matrix'

module VectorContract
	extend Contract
	include Test::Unit::Assertions

	def invariant
		assert(size >= 0, "Size is invalid.")
		assert(count == size, "Number of elements is less than it should be.")
		assert(all?{ |x| x.is_a?(Numeric) }, "Non-number elements present in vector.")
		
	end

	####################
	# Common Contracts #
	####################

	# Adds a postcondition to the specified method requiring that the
	# method returns an object satisfying the VectorContract.
	def self.return_vector(method_name)
		add_postcondition_contract(method_name) do |instance, *args, result|
			assert(
				result.class.include?(VectorContract),
				"Method #{method_name} expected to return a vector.\n" \
				"Returned a #{result.class} instead."
			)
		end
	end

	##########
	# Access #
	##########

	def op_element_access_precondition(i)
		assert(
			i.is_a?(Integer),
			"A vector can only be indexed by integer.  Got a #{i.class}."
		)
	end

	def op_element_access_postcondition(i, result)
		if i >= size || i < -size
			assert_equal(
				nil,
				result,
				"Access out of bounds failed to return nil.\n" \
				"Returned #{result} instead."
			)
		else
			assert(
				result.is_a?(Numeric),
				"The value accessed from the vector " \
				"was not numeric.\nIt was a #{result.class}."
			)
		end
	end

	const "[]"

	##############
	# Arithmetic #
	##############

	def op_multiply_precondition(value)
		if value.class.include?(MatrixContract)
			covector.transpose.op_multiply_precondition(value)
		elsif value.class.include?(VectorContract)
			assert_equal(
				size,
				value.size,
				"Two vectors must be the same size to take the\n" \
				"dot product.  vector 1: #{self}, vector 2: #{value}"
			)
		end
	end

	def op_multiply_postcondition(value, result)
		if value.is_a?(Numeric)
			assert(
				result.class.include?(VectorContract),
				"Vector multiplied by a scalar did not " \
				"return a vector.  Returned a #{result.class}."
			)

			assert(
				zip(result).all?{ |x, y| y == value * x },
				"Vector multiplied by a scalar returned " \
				"the wrong result.\n" \
				"vector: #{self}, scalar: #{value}, result: #{result}"
			)
		elsif value.class.include?(MatrixContract)
			covector.transpose.op_multiply_postcondition(value, result)
		elsif value.class.include?(VectorContract)
			inner_product_postcondition(value, result)
		else
			assert_equal(
				:*.to_proc.call(*value.coerce(self)),
				result,
				generic_postcondition_failure(:*, result)
			)
		end
	end

	const "*"
	require_operand_types "*",
		Numeric,
		MatrixContract,
		VectorContract

	def op_divide_precondition(value)
		if value.is_a?(Numeric)
			assert_not_equal(
				0,
				value,
				"Cannot divide by zero."
			)
		end
	end

	def op_divide_postcondition(value, result)
		if value.is_a?(Numeric)
			assert(
				zip(value).all?{ |x, y| y == x / value },
				"Vector division by a scalar " \
				"returned the wrong result.\n" \
				"vector: #{vector}, scalar: #{value}, result: #{result}"
			)
		else
			assert_equal(
				:/.to_proc.call(*value.coerce(self)),
				result,
				generic_postcondition_failure(:/, result)
			)
		end
	end

	const "/"
	return_vector "/"
	require_operand_types "/", Numeric

	def op_add_precondition(value)
		if value.class.include?(VectorContract)
			assert_equal(
				self.size,
				value.size,
				"Dimension mismatch - cannot add two vectors\n" \
				"of different length.\n" \
				"vector 1: #{self}, vector 2: #{value}"
			)
		elsif value.class.include?(MatrixContract)
			Matrix.column_vector(self.to_a).op_add_precondition(value)
		end
	end

	def op_add_postcondition(value, result)
		if value.class.include?(VectorContract)
			assert(
				result.class.include?(VectorContract),
				"Addition of a vector with a vector returned\n" \
				"a non-vector of type #{result.class}"
			)

			assert_equal(
				result.size,
				self.size,
				"Vector addition returned a result\n" \
				"of the wrong size.\n" \
				"vector 1: #{self}, vetor 2: #{value}" \
				"result: #{result}"
			)

			assert(
				result.each.with_index.all? { |x, i|
					x == self[i] + value[i]
				},
				"Vector addition returned the wrong result.\n" \
				"vector 1: #{self}, vector 2: #{value},\n" \
				"result: #{result}"
			)
		elsif value.class.include?(MatrixContract)
			assert(
				result.class.include?(MatrixContract),
				"Addition of a vector with a matrix returned\n" \
				"a non-matrix of type #{result.class}"
			)

			assert_equal(
				1,
				result.column_size,
				"Result of adding a vector and a matrix was\n" \
				"not a column vector.\n" \
				"vector 1: #{self}, vector 2: #{value},\n" \
				"result: #{result}"
			)

			op_add_postcondition(value.column(1), result.column(1))
		end
	end

	const "+"
	require_operand_types "+", VectorContract, MatrixContract

	def op_subtract_precondition(value)
		op_add_precondition(value)
	end

	def op_subtract_postcondition(value, result)
		if value.class.include?(VectorContract) ||
		      value.class.include?(MatrixContract)
			op_add_postcondition(value.collect{ |x| -x }, result)
		end
	end

	const "-"
	require_operand_types "-", VectorContract, MatrixContract

	def op_unary_plus_postcondition(result)
		assert_equal(
			self,
			result,
			generic_postcondition_failure(:+@, result)
		)

		assert_not_same(
			self,
			result,
			"@+ should return a new vector - returned the same one!"
		)
	end

	const "+@"

	def op_unary_minus_postcondition(result)
		assert_equal(
			self.size,
			result.size,
			generic_postcondition_failure(:+@, result)
		)

		assert(
			zip(result).all?{ |x, y| x == -y },
			generic_postcondition_failure(:-@, result)
		)
	end

	const "-@"

	############
	# Equality #
	############

	def op_equal_postcondition(value, result)
		assert_equal(
			value.class.include?(VectorContract) &&
			self.size == value.size &&
			zip(value).all? { |x, y| x == y },
			result,
			"== returned the wrong result for two vectors.\n" \
			"vector 1: #{self}, vector 2: #{self}, result: #{result}"
		)
	end

	const "=="

	####################
	# Vector Functions #
	####################

	def inner_product_postcondition(value, result)
		assert(
			result == zip(value).map{ |x, y| x * y }.reduce(:+),
			"Dot product result was incorrect.\n" \
			"vector 1: #{self}, vector 2: #{value}, " \
			"result: #{result}"
		)
	end

	const "inner_product"
	require_argument_types "inner_product", [VectorContract]

	def magnitude_postcondition(result)
		assert_equal(
			Math.sqrt(map{ |x| x * 2 }.reduce(:+)),
			result,
			generic_postcondition_failure(:magnitude, result)
		)
	end

	const "magnitude"

	def normalize_precondition
		assert(
			magnitude > 0,
			"can't normalize a zero vector"
		)
	end

	def normalize_postcondition(result)
		assert_equal(
			1,
			result.magnitude,
			generic_postcondition_failure(:normalize, result)
		)
	end

	const "normalize"
	return_vector "normalize"

	def size_postcondition(result)
		assert_equal(
			count,
			result,
			generic_postcondition_failure(:size, result)
		)
	end

	const "size"

	def conjugate_postcondition(result)
		assert_equal(
			self.size,
			result.size,
			generic_postcondition_failure(:conjugate, result)
		)

		assert(
			zip(result).all? { |x, y| y == x.conj },
			generic_postcondition_failure(:conjugate, result)
		)
	end

	const "conjugate"

	##############
	# Conversion #
	##############

	def covector_postcondition(result)
		assert(
			result.class.include?(MatrixContract),
			"Covector returned a #{result.class} instead of a matrix."
		)

		assert_equal(
			1,
			result.row_size,
			generic_postcondition_failure(:covector, result)
		)

		assert_equal(
			self,
			result.row(0),
			generic_postcondition_failure(:covector, result)
		)
	end

	const "covector"

	def to_a_postcondition(result)
		assert(
			result.is_a?(Array),
			"to_a didn't return an array???  Returned a #{result.class}"
		)

		assert(
			zip(result).all?{ |x, y| x == y },
			generic_postcondition_failure(:to_a, result)
		)
	end

	const "to_a"

	def coerce_precondition(value)
		assert(
			value.is_a?(Numeric),
			"#{self.class} can't be coerced into #{other.class}"
		)
	end

	def coerce_postcondition(value, result)
		other, me = *result
		assert_nothing_raised(
			generic_postcondition_failure(:coerce, result)
		) { other * me }
	end

	const "coerce"
end
