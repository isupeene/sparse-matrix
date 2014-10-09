require_relative 'contracts/contract_decorator'
require_relative 'contracts/matrix_contract'
require_relative 'implementations/tridiagonal_matrix_impl'

class TridiagonalMatrix
	include ContractDecorator
	include MatrixContract

	# For some reason, deriving from basic object gives an error
	# including modules, so we have to manually delete all these methods.
	undef_method :==
	undef_method :to_s
	undef_method :inspect
	undef_method :hash
	undef_method :eql?
	undef_method :is_a?
	undef_method :kind_of?
	undef_method :instance_of?

	def initialize(*args, &block)
		super(TridiagonalMatrixImpl.send(:new, *args, &block))
	end
end
