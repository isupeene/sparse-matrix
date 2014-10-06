require_relative "contracts/matrix_contract"

class SparseMatrix
	
	def initialize(row_size, column_size, nonzero_values, col_ind, row_ptr)
		@row_size = row_size
		@column_size = column_size
		@nonzero_values = nonzero_values
		@col_ind = col_ind
		@row_ptr = row_ptr
	end
	
	def self.build(row_size, column_size)
		nonzero_values, col_ind, row_ptr = [], [], [0]
		row_size.times { |i| 
			row_count = 0
			column_size.times { |j| 
				value = yield i, j
				puts value
				unless value == 0
					nonzero_values.push(value)
					col_ind.push(j)
					row_count += 1
				end
			}
			row_ptr.push(row_ptr.last + row_count)
		}
		new row_size, column_size, nonzero_values, col_ind, row_ptr
	end
	
	def self.build_from_hash(row_size, column_size, h)
		nonzero_values, col_ind, row_ptr = [], [], [0]
		h.keys.sort.each { |i|
			h[i].keys.sort.each { |j|
				nonzero_values.push(h[i][j])
				col_ind.push(j)
			}
			row_ptr.push(row_ptr.last + a[i].keys.count)
		}
		new row_size, column_size, nonzero_values, col_ind, row_ptr
	end
	
end
