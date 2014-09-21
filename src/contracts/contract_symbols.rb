module ContractSymbols
	def precondition_suffix
		"_precondition"
	end

	def postcondition_suffix
		"_postcondition"
	end

	def invariant_suffix
		"_invariant"
	end

	def split_method_name(method_name)
		if ['?', '!', '='] === method_name[-1]
			return method_name[0...-1], method_name[-1]
		else
			return method_name, ""
		end
	end

	def precondition_name(method_name)
		root_name, suffix = split_method_name(method_name)
		return root_name + precondition_suffix + suffix
	end

	def postcondition_name(method_name)
		root_name, suffix = split_method_name(method_name)
		return root_name + postcondition_suffix + suffix
	end

	def invariant_name(method_name)
		root_name, suffix = split_method_name(method_name)
		return root_name + invariant_suffix + suffix
	end
end
