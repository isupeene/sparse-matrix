module ContractSymbols
	PRECONDITION_SUFFIX = "_precondition"
	POSTCONDITION_SUFFIX = "_postcondition"
	INVARIANT_SUFFIX = "_invariant"

	# A pair of dictionaries for converting between method roots
	# and contract roots.  They will convert between operators,
	# and the operator codes we've defined, if there is a match.
	# Otherwise, they will return the key that's provided to them.
	CONTRACT_ROOT_TO_METHOD_ROOT = {
		"op_add" => "+",
		"op_subtract" => "-",
		"op_multiply" => "*",
		"op_divide" => "/",
		"op_modulo" => "%",
		"op_power" => "**",
		"op_equal" => "==",
		"op_greater_than" => ">",
		"op_less_than" => "<",
		"op_greater_than_or_equal" => ">=",
		"op_less_than_or_equal" => "<=",
		"op_compare" => "<=>",
		"op_subsumption" => "===",
		"op_match" => "=~",
		"op_not_match" => "!~",
		"op_element_access" => "[]",
		"op_element_mutation" => "[]=",
		"op_not" => "!",
		"op_complement" => "~",
		"op_unary_plus" => "+@",
		"op_unary_minus" => "-@",
		"op_and" => "&",
		"op_or" => "|",
		"op_exclusive_or" => "^",
		"op_shift_left" => "<<",
		"op_shift_right" => ">>"
	}
	METHOD_ROOT_TO_CONTRACT_ROOT = CONTRACT_ROOT_TO_METHOD_ROOT.invert

	CONTRACT_ROOT_TO_METHOD_ROOT.default_proc = proc { |h, k| k }
	METHOD_ROOT_TO_CONTRACT_ROOT.default_proc = proc { |h, k| k }

	def split_method_name(method_name)
		if ['?', '!', '='] === method_name[-1]
			return method_name[0...-1], method_name[-1]
		else
			return method_name, ""
		end
	end

	def split_contract_name(contract_name)
		if ['?', '!', '='] === method_name[-1]
			contract_name = contract_name[0...-1]
			final_suffix = contract_name[-1]
		else
			final_suffix = ""
		end

		contract_suffix = [
			PRECONDITION_SUFFIX,
			POSTCONDITION_SUFFIX,
			INVARIANT_SUFFIX
		].find{ |suffix| contract_name.end_with?(suffix) }

		contract_root = contract_name[0...-contract_suffix.length]
		
		return contract_root, contract_suffix, final_suffix
	end

	def precondition_name(method_name)
		contract_name(method_name, PRECONDITION_SUFFIX)
	end

	def postcondition_name(method_name)
		contract_name(method_name, POSTCONDITION_SUFFIX)
	end

	def invariant_name(method_name)
		contract_name(method_name, INVARIANT_SUFFIX)
	end

	def contract_name(method_name, contract_suffix)
		method_root, suffix = split_method_name(method_name)
		contract_root = METHOD_ROOT_TO_CONTRACT_ROOT[method_root]
		return contract_root + contract_suffix + suffix
	end

	def method_name(contract_name)
		contract_root, contract_suffix, final_suffix =
			split_contract_name(contract_name)

		method_root = CONTRACT_ROOT_TO_METHOD_ROOT[contract_root]
		return method_root + final_suffix
	end
end
