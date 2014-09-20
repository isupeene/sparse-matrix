require 'test/unit'

module MatrixTest 
        include Test::Unit::Assertions

        ##############
        # Properties #
        ##############
        
        def diagonal_precondition
		assert square?
        end

        def diagonal_postcondition(result)
                assert_equal(each_with_index.all?{ |x, i, j| i == j || x == 0 }, result)
        end
end
