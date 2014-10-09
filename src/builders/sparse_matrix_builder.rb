require_relative 'matrix_builder'
require_relative 'sparse_vector_builder'
require_relative 'matrix_builder_functions'
require_relative '../contracts/contract_decorator'
require_relative '../contracts/matrix_builder_contract'
require_relative 'implementations/sparse_matrix_builder_impl'

class SparseMatrixBuilder 
	include ContractDecorator
	include MatrixBuilderContract
	extend MatrixBuilderFunctions

	def initialize(*args, &block)
		super(SparseMatrixBuilderImpl.send(:new, *args, &block))
	end
	
	def builder_type
		:sparse
	end
end
