require 'matrix'
require_relative 'contracts/vector_contract'

class Vector
	alias +@ clone

	def -@
		map{ |x| -x }
	end

	alias old_multiply *

	def *(x)
		x.is_a?(VectorContract) ? inner_product(x) : old_multiply(x)
	end

	def conjugate
		map{ |x| x.conj }
	end

	def ==(other)
		other.is_a?(VectorContract) &&
		other.size == size &&
		zip(other).all? { |x, y| x == y }
	end

	alias conj conjugate

	include VectorContract
end
