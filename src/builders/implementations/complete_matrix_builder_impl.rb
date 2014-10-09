require_relative 'matrix_builder_impl'
require_relative '../complete_vector_builder'
require_relative '../../matrix'
require_relative '../../contracts/matrix_builder_contract'

# Builder implementationto create the default Matrix class
class CompleteMatrixBuilderImpl < MatrixBuilderImpl

	# Creates a matrix with the values currently stored in the builder
	def to_mat
		Matrix.build(row_size, column_size){ |i, j| self[i, j] }
	end

	# For telling the MatrixBuilderImpl which type of VectorBuilder to use
	def builder_type
		:complete # Doesn't really matter, as we don't use the vectors anyway
	end

	register :complete
end
