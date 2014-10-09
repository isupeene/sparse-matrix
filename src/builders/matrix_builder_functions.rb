module MatrixBuilderFunctions
	def [](*rows)
		rows = rows.map(&:to_ary)

		new(rows.size, rows.size > 0 ? rows.first.size : 0) { |builder|
			rows.each.with_index { |row, i|
				row.each.with_index{ |x, j| builder[i, j] = x }
			}
		}.to_mat
	end

	def diagonal(*values)
		new(values.length, values.length) { |builder|
			values.each.with_index{ |x, i| builder[i, i] = x }
		}.to_mat
	end

	def scalar(n, value)
		new(n, n) { |b| n.times { |i| b[i, i] = value } }.to_mat
	end

	def rows(rows)
		self[*rows]
	end

	def columns(columns)
		new(columns.size > 0 ? columns.first.size : 0, columns.size) { |b|
			columns.each.with_index { |column, j|
				column.each.with_index{ |x, i| b[i, j] = x }
			}
		}.to_mat
	end

	def zero(n)
		# TODO: Optimized zero-matrix class
		new(n, n).to_mat
	end

	def column_vector(column)
		new(column.length, 1) { |builder|
			column.each.with_index{ |x, i| builder[i, 0] = x }
		}.to_mat
	end

	def row_vector(row)
		new(1, row.length) { |builder|
			row.each.with_index{ |x, j| builder[0, j] = x }
		}.to_mat
	end

	def identity(n)
		# TODO: Optimized identity matrix class.
		scalar(n, 1)
	end

	def I(n)
		identity(n)
	end

	def unit(n)
		I(n)
	end
end
