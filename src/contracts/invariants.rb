require 'test/unit'

module Invariants
	include Test::Unit::Assertions

	def const(*args)
		temp = clone
		yield
		assert_equal(
			temp, self,
			"The object was altered by a const method.\n" \
			"Before: #{temp}\n" \
			"After: #{self}"
		)
	end
end

