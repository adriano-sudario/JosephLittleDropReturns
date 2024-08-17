class_name StringExtension

static func pascal_case_to_snake_case(value: String) -> String:
	var result = ""
	
	for i in value.length():
		var letter = value[i]
		
		if letter == letter.to_upper():
			if i == 0 or letter == "_" or value[i - 1] == "_":
				result += letter.to_lower()
			else:
				result += "_" + letter.to_lower()
		else:
			result += letter
	
	return result
