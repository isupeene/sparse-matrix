require_relative '../contracts/contract_decorator'
require_relative '../contracts/matrix_builder_contract'
require_relative 'implementations/matrix_builder_impl'

# Derived class must implement to_mat, indicating how the builder
# will be transformed into a matrix, and builder_type, indicating
# which underlying VectorBuilder to use.  Additionally, the derived
# class must register itself by calling register with a symbol.
class MatrixBuilder
	include ContractDecorator
	include MatrixBuilderContract

	undef_method :==
	undef_method :to_s
	undef_method :inspect
	undef_method :hash
	undef_method :eql?
	undef_method :is_a?
	undef_method :kind_of?
	undef_method :instance_of?
	
	def initialize(*args, &block)
		puts args
		super(*args)
	end


	def MatrixBuilder.create(type, *args, &block)
		MatrixBuilderImpl.builders[type].send(:new, *args, &block)
	end
	
end
