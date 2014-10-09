require_relative 'vector_builder'
require_relative '../vector'

# Builder to create vectors from Ruby's Matrix class
class CompleteVectorBuilder < VectorBuilder
	# Create vector from array of values
	def self.[](*values)
		Vector[*values]
	end

	# Converts VectorBuilder into an immutable Vector
	def to_vec
		Vector.elements(Array.new(size) { |i|
			self[i]
		}, false)
	end

	register :complete
end
