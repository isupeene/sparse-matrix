require_relative 'vector_builder'
require_relative '../vector'

class CompleteVectorBuilder < VectorBuilder
	def self.[](*values)
		Vector[*values]
	end

	def to_vec
		Vector.elements(Array.new(size) { |i|
			self[i]
		}, false)
	end

	register :complete
end
