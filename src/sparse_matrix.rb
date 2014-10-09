require_relative 'contracts/contract_decorator'
require_relative 'contracts/matrix_contract'
require_relative 'implementations/sparse_matrix_impl'

# Class to create a sparse matrix implementation and decorate it with contracts
class SparseMatrix
	include ContractDecorator
	include MatrixContract

	undef_method :==
	undef_method :to_s
	undef_method :inspect
	undef_method :hash
	undef_method :eql?
	undef_method :is_a?
	undef_method :kind_of?
	undef_method :instance_of?

	# Create implementation and decorate it with contracts
	def initialize(*args, &block)
		super(SparseMatrixImpl.send(:new, *args, &block))
	end
end
