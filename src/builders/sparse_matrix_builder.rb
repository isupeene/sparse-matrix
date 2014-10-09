require_relative 'matrix_builder'
require_relative 'sparse_vector_builder'
require_relative '../contracts/contract_decorator'
require_relative '../contracts/matrix_builder_contract'
require_relative 'implementations/sparse_matrix_builder_impl'

# Builder that creates an implementation builder and decorates it with the contracts
class SparseMatrixBuilder 
	include ContractDecorator
	include MatrixBuilderContract

	# Create a sparse matrix builder implementation that is decorated with the ContractDecorator
	def initialize(*args, &block)
		super(SparseMatrixBuilderImpl.send(:new, *args, &block))
	end

	# Create decorated sparse matrix builder from array of row arrays
	def self.[](*rows)
		rows = rows.map(&:to_ary)

		new(rows.size, rows.size > 0 ? rows.first.size : 0) { |builder|
			rows.each.with_index { |row, i|
				row.each.with_index{ |x, j| builder[i, j] = x }
			}
		}.to_mat
	end

	# Create decorated sparse matrix builder from array of diagonal values
	def self.diagonal(*values)
		new(values.length, values.length) { |builder|
			values.each.with_index{ |x, i| builder[i, i] = x }
		}.to_mat
	end

	# Create decorated sparse matrix builder of size nxn with diagonal equalling value
	def self.scalar(n, value)
		new(n, n) { |b| n.times { |i| b[i, i] = value } }.to_mat
	end

	# Create decorated sparse matrix builder from array of array of row arrays
	def self.rows(rows)
		self[*rows]
	end

	# Create decorated sparse matrix builder array of columns
	def self.columns(columns)
		new(columns.size > 0 ? columns.first.size : 0, columns.size) { |b|
			columns.each.with_index { |column, j|
				column.each.with_index{ |x, i| b[i, j] = x }
			}
		}.to_mat
	end

	# Create decorated sparse matrix builder of size n of all zeros
	def self.zero(n)
		# TODO: Optimized zero-matrix class
		new(n, n).to_mat
	end

	# Create decorated sparse matrix builder from a single column
	def self.column_vector(column)
		new(column.length, 1) { |builder|
			column.each.with_index{ |x, i| builder[i, 0] = x }
		}.to_mat
	end

	# Create decorated sparse matrix builder from a single row
	def self.row_vector(row)
		new(1, row.length) { |builder|
			row.each.with_index{ |x, j| builder[0, j] = x }
		}.to_mat
	end

	# Create decorated sparse matrix builder for identity matrix of size n
	def self.identity(n)
		# TODO: Optimized identity matrix class.
		scalar(n, 1)
	end

	# Create decorated sparse matrix builder for identity matrix of size n
	def self.I(n)
		identity(n)
	end

	# Create decorated sparse matrix builder for identity matrix of size n
	def self.unit(n)
		I(n)
	end
end
