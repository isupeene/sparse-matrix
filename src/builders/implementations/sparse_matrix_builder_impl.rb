require_relative 'matrix_builder_impl'
require_relative '../sparse_vector_builder'
require_relative '../../tridiagonal_matrix'
require_relative '../../sparse_matrix'
require_relative '../../contracts/matrix_builder_contract'

# Implementation for a builder that builds sparse and tridiagonal matrices
class SparseMatrixBuilderImpl < MatrixBuilderImpl

	# For telling the MatrixBuilderImpl which type of VectorBuilder to use
	def builder_type
		:sparse
	end

	# Creates a matrix with the values currently stored in the builder
	def to_mat
		tridiagonal? ?
			TridiagonalMatrix.send(:new, self) :
			SparseMatrix.send(:new, self)
	end

	# Required by SparseMatrix.new
	# Gets vector of ith row
	def row(i)
		rows.row(i)
	end

	# Determine if current matrix in builder is tridiagonal
	def tridiagonal?
		row_size == column_size &&
		each_with_index.all?{ |x, i, j| x == 0 || (i - j).abs <= 1 }
	end
	
	register :sparse
	
	include MatrixBuilderContract
end
