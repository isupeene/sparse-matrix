require_relative '../matrix'
require_relative 'matrix_builder'
require_relative '../contracts/contract_decorator'
require_relative '../contracts/matrix_builder_contract'
require_relative 'implementations/complete_matrix_builder_impl'

class CompleteMatrixBuilder
	include ContractDecorator
	include MatrixBuilderContract

	def initialize(*args, &block)
		#super.register :complete
		super(CompleteMatrixBuilderImpl.send(:new, *args, &block))
	end
	
	def builder_type
		:complete
	end
	
	def self.method_missing(symbol, *args, &block)
		Matrix.public_send(symbol, *args, &block)
	end

	include MatrixBuilderContract
end
