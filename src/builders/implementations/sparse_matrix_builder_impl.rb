require_relative 'matrix_builder_impl'
require_relative '../sparse_vector_builder'
require_relative '../../tridiagonal_matrix'
require_relative '../../sparse_matrix'
require_relative '../../contracts/matrix_builder_contract'

class SparseMatrixBuilderImpl < MatrixBuilderImpl

	def builder_type
		:sparse
	end

	def to_mat
		tridiagonal? ?
			TridiagonalMatrix.send(:new, self) :
			SparseMatrix.send(:new, self)
	end

	# Required by SparseMatrix.new
	def row(i)
		rows.row(i)
	end

	def tridiagonal?
		row_size == column_size &&
		each_with_index.all?{ |x, i, j| x == 0 || (i - j).abs <= 1 }
	end
	
	register :sparse

	include MatrixBuilderContract
end
