require_relative '../matrix'
require_relative 'matrix_builder'
require_relative '../contracts/contract_decorator'
require_relative '../contracts/matrix_builder_contract'
require_relative 'implementations/complete_matrix_builder_impl'

# Builder to create Matrix library Matrices.
# Decorates CompleteMatrixBuilderImpl with contracts
class CompleteMatrixBuilder
	include ContractDecorator
	include MatrixBuilderContract

	# Create Implementation and decorate with contract decorator
	def initialize(*args, &block)
		super(CompleteMatrixBuilderImpl.send(:new, *args, &block))
	end
	
	# Call Matrix class for any missing methods i.e. constructors
	def self.method_missing(symbol, *args, &block)
		Matrix.public_send(symbol, *args, &block)
	end
end
