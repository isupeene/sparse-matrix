require 'matrix'
require_relative 'contracts/matrix_contract'

# Adding onto matrix class
class Matrix
	alias +@ clone

	# Returns matrix with all elements * -1
	def -@
		map{ |x| -x }
	end

	# Redefine == so our matrices can be checked for equality
	# against the Ruby library matrices
	def ==(other)
		other.is_a?(MatrixContract) &&
		other.row_size == row_size &&
		other.column_size == column_size &&
		zip(other).all?{ |x, y| x == y }
	end
end
