require_relative 'implementations/dumb_matrix_impl'
require_relative 'contracts/dumb_matrix_contract'

class DumbMatrix
	include ContractDecorator
	include DumbMatrixContract

	undef_method :==
	undef_method :to_s
	undef_method :inspect
	undef_method :hash
	undef_method :eql?
	undef_method :is_a?
	undef_method :kind_of?
	undef_method :instance_of?

	def initialize(*args, &block)
		super(DumbMatrixImpl.send(:new, *args, &block))
	end
end
