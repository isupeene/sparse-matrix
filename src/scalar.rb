require_relative 'contracts/matrix_contract'
require_relative 'contracts/vector_contract'

# Class like Numeric but knows how to do basic arithmetic on matrices and vectors
class Scalar
	# Create new Scalar with value
	def initialize(value)
		@value = value
	end

	# Multiply Scalar by argument. Can multiply it by matrices, vectors or numerics.
	def *(x)
		if x.is_a?(Numeric)
			@value * x
		elsif x.is_a?(MatrixContract) || x.is_a?(VectorContract)
			@value == 1 ? x.clone : x * @value
		else
			a, b = x.coerce(@value)
			a * b
		end
	end

	# Divide Scalar by argument. Can divide it by matricesor numerics.
	def /(x)
		if x.is_a?(Numeric)
			@value / x
		elsif x.is_a?(MatrixContract)
			@value == 1 ? x.inverse : x.inverse * @value
		elsif x.is_a?(VectorContract)
			raise TypeError
		else
			a, b = x.coerce(@value)
			a / b
		end
	end
	
	# Subtract argument from Scalar. Can subtract by numerics.
	def -(x)
		if x.is_a?(Numeric)
			@value - x
		elsif x.is_a?(MatrixContract) || x.is_a?(VectorContract)
			raise TypeError
		else
			a, b = x.coerce(@value)
			a - b
		end
	end

	# Add argument to Scalar. Can add by numerics.
	def +(x)
		if x.is_a?(Numeric)
			@value + x
		elsif x.is_a?(MatrixContract) || x.is_a?(VectorContract)
			raise TypeError
		else
			a, b = x.coerce(@value)
			a + b
		end
	end

	# Scalar to power of argument. Argument must be numeric.
	def **(x)
		if x.is_a?(Numeric)
			@value ** x
		elsif x.is_a?(MatrixContract) || x.is_a?(VectorContract)
			raise TypeError
		else
			a, b = x.coerce(@value)
			a ** b
		end
	end
end
