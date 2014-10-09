require 'matrix'
require_relative 'contracts/matrix_contract'

class Matrix
	alias +@ clone

	def -@
		map{ |x| -x }
	end

	def ==(other)
		other.is_a?(MatrixContract) &&
		other.row_size == row_size &&
		other.column_size == column_size &&
		zip(other).all?{ |x, y| x == y }
	end

	include MatrixContract
end
