require_relative 'matrix_builder'
require_relative 'sparse_vector_builder'
require_relative '../tridiagonal_matrix'
require_relative '../sparse_matrix'
require_relative '../contracts/matrix_builder_contract'

class SparseMatrixBuilder < MatrixBuilder
	def self.[](*rows)
		rows = rows.map(&:to_ary)

		new(rows.size, rows.size > 0 ? rows.first.size : 0) { |builder|
			rows.each.with_index { |row, i|
				row.each.with_index{ |x, j| builder[i, j] = x }
			}
		}.to_mat
	end

	def self.diagonal(*values)
		new(values.length, values.length) { |builder|
			values.each.with_index{ |x, i| builder[i, i] = x }
		}.to_mat
	end

	def self.scalar(n, value)
		new(n, n) { |b| n.times { |i| b[i, i] = value } }.to_mat
	end

	def self.rows(rows)
		self[*rows]
	end

	def self.columns(columns)
		new(columns.size > 0 ? columns.first.size : 0, columns.size) { |b|
			columns.each.with_index { |column, j|
				column.each.with_index{ |x, i| b[i, j] = x }
			}
		}.to_mat
	end

	def self.zero(n)
		# TODO: Optimized zero-matrix class
		new(n, n).to_mat
	end

	def self.column_vector(column)
		new(column.length, 1) { |builder|
			column.each.with_index{ |x, i| builder[i, 0] = x }
		}.to_mat
	end

	def self.row_vector(row)
		new(1, row.length) { |builder|
			row.each.with_index{ |x, j| builder[0, j] = x }
		}.to_mat
	end

	def self.identity(n)
		# TODO: Optimized identity matrix class.
		scalar(n, 1)
	end

	def self.I(n)
		identity(n)
	end

	def self.unit(n)
		I(n)
	end

	def builder_type
		:sparse
	end

	def to_mat
		tridiagonal? ?
			TridiagonalMatrix.send(:new, self) :
			SparseMatrix.send(:new, self)
	end

	# Required by SparseMatrix.new
	def row(i)
		rows.row(i)
	end

	def tridiagonal?
		row_size == column_size &&
		each_with_index.all?{ |x, i, j| x == 0 || (i - j).abs <= 1 }
	end

	register :sparse

	include MatrixBuilderContract
end
