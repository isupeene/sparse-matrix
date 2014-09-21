require 'test/unit'
require './contract'
require './invariants'

module MatrixContract
	include Invariants
	extend Contract

	def invariant
		# TODO: Class invariant
	end

        ##############
        # Properties #
        ##############
        
        def diagonal_precondition?
		assert(
			square?,
			"#diagonal? can only be called on a square matrix.\n" \
			"This matrix is #{row_size} by #{column_size}"
		)
        end

        def diagonal_postcondition?(result)
                assert_equal(
			each_with_index.all?{ |x, i, j| i == j || x == 0 },
			result,
			"#diagonal? returned an incorrect result.\n" \
			"Returned #{result} for the following matrix:\n" \
			"#{self}"
		)
        end

	alias diagonal_invariant? const
end
