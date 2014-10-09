require_relative '../contracts/contract_decorator'
require_relative '../contracts/matrix_builder_contract'
require_relative 'implementations/matrix_builder_impl'

# Creates a matrix builder implementation and decorates it with contracts
class MatrixBuilder
	include ContractDecorator
	include MatrixBuilderContract

	# Creates a matrix of the given type by using the implementation
	def MatrixBuilder.create(type, *args, &block)
		MatrixBuilderImpl.builders[type].send(:new, *args, &block)
	end
	
end
