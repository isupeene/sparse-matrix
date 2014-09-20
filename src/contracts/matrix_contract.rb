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
		assert square?
        end

        def diagonal_postcondition?(result)
                assert_equal(
			each_with_index.all?{ |x, i, j| i == j || x == 0 },
			result
		)
        end

	alias diagonal_invariant? const
end
