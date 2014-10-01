require_relative 'matrix'
require_relative 'contracts/matrix_builder_contract'

class CompleteMatrixBuilder

	def initialize(row_size, column_size)
		@row_size = row_size
		@column_size = column_size

		@rows = Hash.new { |h, k|
			# NOTE: This is a bit inefficient, because we create a new
			# default hash every time a non-existing element is
			# accessed.  It would be more efficient to use the same
			# default hash for all accesses, and only create a new
			# one when an element needs to be set.
			h[k] = Hash.new { 0 }
		}
	end

	attr_reader :row_size
	attr_reader :column_size

	def [](i, j)
		@rows[i][j]
	end

	def []=(i, j, value)
		@rows[i][j] = value
	end

	def to_mat
		Matrix.build(row_size, column_size){ |i, j| @rows[i][j] }
	end

	def ==(other)
		other.kind_of?(MatrixBuilderContract) &&
		row_size == other.row_size &&
		column_size == other.column_size &&
		row_size.times{|i| column_size.times{|j| self[i, j] = other[i, j] }}
	end

	include MatrixBuilderContract
end
