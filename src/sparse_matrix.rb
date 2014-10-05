require "contracts/MatrixContract"

Class SparseMatrix
	
	def initialize(row_size, column_size)
		@row_size = row_size
		@column_size = column_size
		@nonzero_values = []
		@col_ind = []
		@row_ptr = [0]
	end
	
	def build(row_size, column_size)
		initialize(row_size, column_size)
		row_size.times { |i| 
			row_count = 0
			column_size.times { |j| 
				value = yield i, j
				unless value == 0
					@nonzero_values.push(value)
					@col_ind.push(j)
					row_count += 1
				end
			}
			@row_ptr.push(@row_ptr.last + row_count)
		}
	end
	
	def build_from_hash(row_size, column_size, h)
		initialize(row_size, column_size)
		h.keys.sort.each { |i|
			h[i].keys.sort.each { |j|
				@nonzero_values.push(h[i][j])
				@col_ind.push(j)
			}
			@row_ptr.push(@row_ptr.last + a[i].keys.count)
		}
	end
	
end