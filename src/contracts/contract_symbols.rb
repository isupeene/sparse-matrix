module ContractSymbols
	PRECONDITION_SUFFIX = "_precondition"
	POSTCONDITION_SUFFIX = "_postcondition"
	INVARIANT_SUFFIX = "_invariant"

	def split_method_name(method_name)
		if ['?', '!', '='] === method_name[-1]
			return method_name[0...-1], method_name[-1]
		else
			return method_name, ""
		end
	end

	def precondition_name(method_name)
		root_name, suffix = split_method_name(method_name)
		return root_name + PRECONDITION_SUFFIX + suffix
	end

	def postcondition_name(method_name)
		root_name, suffix = split_method_name(method_name)
		return root_name + POSTCONDITION_SUFFIX + suffix
	end

	def invariant_name(method_name)
		root_name, suffix = split_method_name(method_name)
		return root_name + INVARIANT_SUFFIX + suffix
	end
end
