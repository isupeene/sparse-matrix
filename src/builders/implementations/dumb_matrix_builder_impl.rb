require_relative 'sparse_matrix_builder_impl'
require_relative '../../dumb_matrix'

class DumbMatrixBuilderImpl < SparseMatrixBuilderImpl
	alias to_smart_mat to_mat

	def to_mat
		DumbMatrix.send(:new, self)
	end

	register :dumb
end
