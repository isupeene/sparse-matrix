require 'matrix'
require_relative 'contracts/vector_contract'

# Extend functionality of Ruby's Vector class
class Vector
	alias +@ clone

	# Return vector multiplied by -1
	def -@
		map{ |x| -x }
	end

	alias old_multiply *

	# Call inner_product for * if it is one of our classes
	def *(x)
		x.is_a?(VectorContract) ? inner_product(x) : old_multiply(x)
	end

	# Take the complex conjugate of the Vector
	def conjugate
		map{ |x| x.conj }
	end

	# Define our vectors to be able to be equal to Ruby's vector
	def ==(other)
		other.is_a?(VectorContract) &&
		other.size == size &&
		zip(other).all? { |x, y| x == y }
	end

	alias conj conjugate

	include VectorContract
end
