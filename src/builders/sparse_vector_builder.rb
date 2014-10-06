require_relative 'vector_builder'
require_relative '../sparse_vector'

class SparseVectorBuilder < VectorBuilder
	def self.[](*values)
		new(values.length){ |b|
			values.each.with_index{ |x, i| b[i] = x }
		}.to_vec
	end

	def to_vec
		SparseVector.new(self)
	end

	# Required by SparseVector.new
	def transpose
		@values.size == 0 ? [[], []] : @values.to_a.sort.transpose 
	end

	register :sparse
end
