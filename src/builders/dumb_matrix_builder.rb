require_relative 'implementations/dumb_matrix_builder_impl'
require_relative '../contracts/matrix_builder_contract'
require_relative '../contracts/contract_decorator'
require_relative 'matrix_builder_functions'

class DumbMatrixBuilder
	include ContractDecorator
	include MatrixBuilderContract
	extend MatrixBuilderFunctions

	undef_method :==
	undef_method :to_s
	undef_method :inspect
	undef_method :hash
	undef_method :eql?
	undef_method :is_a?
	undef_method :kind_of?
	undef_method :instance_of?

	def initialize(*args, &block)
		super(DumbMatrixBuilderImpl.send(:new, *args, &block))
	end
end
