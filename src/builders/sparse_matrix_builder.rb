require_relative 'matrix_builder'
require_relative 'sparse_vector_builder'
require_relative '../contracts/contract_decorator'
require_relative '../contracts/matrix_builder_contract'
require_relative 'implementations/sparse_matrix_builder_impl'

class SparseMatrixBuilder 
	include ContractDecorator
	include MatrixBuilderContract

	def initialize(*args, &block)
		super(SparseMatrixBuilderImpl.send(:new, *args, &block))
	end
	
	def builder_type
		:sparse
	end

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
end
