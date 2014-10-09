require_relative 'matrix_builder'
require_relative 'complete_vector_builder'
require_relative '../matrix'
require_relative '../contracts/matrix_builder_contract'

class CompleteMatrixBuilder < MatrixBuilder
	def self.method_missing(symbol, *args, &block)
		Matrix.public_send(symbol, *args, &block)
	end

	def to_mat
		Matrix.build(row_size, column_size){ |i, j| self[i, j] }
	end

	def builder_type
		:complete # Doesn't really matter, as we don't use the vectors anyway
	end

	register :complete

	include MatrixBuilderContract
end
