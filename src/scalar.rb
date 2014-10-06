require_relative 'contracts/matrix_contract'
require_relative 'contracts/vector_contract'

class Scalar
	def initialize(value)
		@value = value
	end

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
