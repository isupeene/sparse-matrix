require_relative 'contracts/contract_decorator'
require_relative 'contracts/vector_contract'
require_relative 'implementations/sparse_vector_impl'

class SparseVector
	include ContractDecorator
	include VectorContract

	undef_method :==
	undef_method :to_s
	undef_method :inspect
	undef_method :hash
	undef_method :eql?
	undef_method :is_a?
	undef_method :kind_of?
	undef_method :instance_of?

	def initialize(*args, &block)
		super(SparseVectorImpl.send(:new, *args, &block))
	end
end
