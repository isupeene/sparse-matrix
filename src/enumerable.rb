module Enumerable
	def unfold(seed)
		drop(1).reduce([seed]) { |result|
			result << (yield result[-1])
		}
	end
end
