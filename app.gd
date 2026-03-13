extends Node2D

func gcdi(a: int, b: int) -> int:
	while b:
		var t = b
		b = a % b
		a = t
	return a

func as_decimal(f: Vector2i) -> float:
	return f.x / float(f.y)
	
func simplify(f: Vector2i) -> Vector2i:
	var gcd = abs(gcdi(f.x, f.y))
	return Vector2i(f.x/gcd, f.y/gcd)
	
func as_text(f: Vector2i) -> String:
	var simple = simplify(f)
	if simple.y > 1:
		return str(simple.x)+"/"+str(simple.y)
	else:
		return str(simple.x)

func to_fraction(dec: float, max_denominator: int = 1000) -> Vector2i:
	# remove negatives
	var sign = 1
	if dec < 0:
		dec *= -1
		sign = -1
	
	var numerator = 0
	var denominator = 1
	
	var found = false
	while denominator <= max_denominator:
		numerator = round(dec * denominator)
		var frac = numerator / float(denominator)
		if is_equal_approx(dec, frac):
			found = true
			break
		denominator += 1
	
	if !found:
		assert(false, "Not a fraction with denominator < "+str(max_denominator))
	
	return simplify(Vector2i(sign * numerator, denominator))
	
func multiple_of_pi(f: float) -> Vector2i:
	return to_fraction(f/PI)

func as_text_multiple_of_pi(f: float) -> String:
	var m = multiple_of_pi(f)
	if m.y != 1:
		return str(m.x)+"π/"+str(m.y)
	else:
		return str(m.x)+"π"
		
func tokens_to_float(tokens: Array[String]) -> float:
	var result = 1.0
	var inverse = false
	for token in tokens:
		if !inverse:
			match token:
				"π": result *= PI
				"√2": result *= sqrt(2)
				"√3": result *= sqrt(3)
				"-": result *= -1
				"/": inverse = !inverse
				_: result *= float(token)
		else:
			match token:
				"π": result /= PI
				"√2": result /= sqrt(2)
				"√3": result /= sqrt(3)
				"-": result /= -1
				"/": inverse = !inverse
				_: result /= float(token)
	return result

func tokens_to_string(tokens: Array[String]) -> String:
	if len(tokens) == 0:
		return "..."
	var output = ""
	for token in tokens:
		match token:
			"π": output += "π "
			"√2": output += "√2 "
			"√3": output += "√3 "
			"-": output += "-"
			"/": output += "/ "
			_: output += "* "+token+" "
	if output.begins_with("* "):
		output = output.substr(2)
	output = output.replace("/ *", "/").replace("-*", "-")
	return output
	
func coord_as_str(f: float) -> String:
	if is_equal_approx(f, 1.0/2.0): return "1/2"
	else: if is_equal_approx(f, -1.0/2.0): return "-1/2"
	else: if is_equal_approx(f, sqrt(2)/2.0): return "√2/2"
	else: if is_equal_approx(f, -sqrt(2)/2.0): return "-√2/2"
	else: if is_equal_approx(f, sqrt(3)/2.0): return "√3/2"
	else: if is_equal_approx(f, -sqrt(3)/2.0): return "-√3/2"
	else: if is_equal_approx(f, 0.0): return "0"
	else: if is_equal_approx(f, 1.0): return "1"
	else: if is_equal_approx(f, -1.0): return "-1"
	
	else: assert(false, "Not the right type of number."); return ""

func tan_as_str(f: float) -> String:
	if is_equal_approx(f, 0.0): return "0"
	else: if is_equal_approx(f, sqrt(3)/3): return "√3/3"
	else: if is_equal_approx(f, -sqrt(3)/3): return "-√3/3"
	else: if is_equal_approx(f, sqrt(3)): return "√3"
	else: if is_equal_approx(f, -sqrt(3)): return "-√3"
	else: if is_equal_approx(f, 1): return "1"
	else: if is_equal_approx(f, -1): return "-1"
	
	else: assert(false, "Not the right type of number."); return ""

enum Answer {
	COORD, #sin/cos
	TAN,
	RAD
}

var angles: Array[float] = [
	0.0, PI/6, PI/4, PI/3, PI/2, 2*PI/3, 3*PI/4, 5*PI/6, PI,
	7*PI/6, 5*PI/4, 4*PI/3, 3*PI/2, 5*PI/3, 7*PI/4, 11*PI/6,
]

var coords: Array[float] = [
	0.0, 
	1.0, sqrt(3)/2, 1.0/2, sqrt(2)/2,
]

func rand_index(a: Array, rng: RandomNumberGenerator):
	return a[rng.randi_range(0,len(a)-1)]
	
func in_sin_domain(n) -> bool: return true
func in_sin_range(n) -> bool: return -1 <= n or n <= 1

func in_asin_domain(n) -> bool: return in_sin_range(n)
func in_asin_range(n) -> bool: return -PI/2 <= n or n <= PI/2

func in_cos_domain(n) -> bool: return true
func in_cos_range(n) -> bool: return -1 <= n or n <= 1

func in_acos_domain(n) -> bool: return in_cos_range(n)
func in_acos_range(n) -> bool: return 0.0 <= n or n <= PI

func in_tan_domain(n) -> bool: return !is_equal_approx(0.0, abs(cos(n)))
func in_tan_range(n) -> bool: return true

func in_atan_domain(n) -> bool: return true
func in_atan_range(n) -> bool: return -PI/2 < n or n < PI/2

func rand_get_from(a: Array[float], fn: Callable, rng: RandomNumberGenerator):
	var b = rng.randi_range(0, 1)
	var rsign = 1
	if b == 0:
		rsign = -1

	var n = rand_index(a, rng) * rsign
	while !fn.call(n):
		b = rng.randi_range(0, 1)
		rsign = 1
		if b == 0:
			rsign = -1
		n = rand_index(a, rng) * rsign
	return n

func make_question(rng: RandomNumberGenerator):
	# 0 give angle for coordinate -> ans is rad
	# 1 give sin for angle        -> ans is coord
	# 2 give cos for angle        -> ans is coord
	# 3 give tan for angle        -> ans is tan
	# 4 give asin from coordinate -> ans is rad
	# 5 give acos from coordinate -> ans is rad
	# 6 give atan from coordinate -> ans is rad
	match rng.randi_range(1,6):
		1:
			var angle = rand_get_from(angles, in_sin_domain, rng)
			question_text = "sin("+as_text_multiple_of_pi(angle)+")"
			answer = sin(angle)
			answer_type = Answer.COORD
		2:
			var angle = rand_get_from(angles, in_cos_domain, rng)
			question_text = "cos("+as_text_multiple_of_pi(angle)+")"
			answer = cos(angle)
			answer_type = Answer.COORD
		3:
			var angle = rand_get_from(angles, in_tan_domain, rng)
			question_text = "tan("+as_text_multiple_of_pi(angle)+")"
			answer = tan(angle)
			answer_type = Answer.TAN
		4:
			var coord = rand_get_from(coords, in_asin_domain, rng)
			question_text = "arcsin("+coord_as_str(coord)+")"
			answer = asin(coord)
			answer_type = Answer.RAD
		5:
			var coord = rand_get_from(coords, in_acos_domain, rng)
			question_text = "arccos("+coord_as_str(coord)+")"
			answer = acos(coord)
			answer_type = Answer.RAD
		6:
			var coord = rand_get_from(coords, in_atan_domain, rng)
			question_text = "arctan("+coord_as_str(coord)+")"
			answer = atan(coord)
			answer_type = Answer.RAD
		
		
			
	
	%Question.text = question_text+" = ?"
			
	

var tokens: Array[String] = []
var rng = RandomNumberGenerator.new()

var question_text = ""
var answer = 0.0
var answer_type: Answer = Answer.RAD

func _ready() -> void:
	rng.randomize()
	update_tokens()
	make_question(rng)
	
func update_tokens() -> void:
	%RenderedAnswer.text = "? = "+tokens_to_string(tokens)

func _on_b_0_pressed() -> void:
	tokens.append("0");update_tokens()

func _on_b_1_pressed() -> void:
	tokens.append("1");update_tokens()

func _on_b_2_pressed() -> void:
	tokens.append("2");update_tokens()

func _on_b_3_pressed() -> void:
	tokens.append("3");update_tokens()

func _on_b_4_pressed() -> void:
	tokens.append("4");update_tokens()

func _on_b_5_pressed() -> void:
	tokens.append("5");update_tokens()

func _on_b_6_pressed() -> void:
	tokens.append("6");update_tokens()

func _on_b_7_pressed() -> void:
	tokens.append("7");update_tokens()
	
func _on_b_11_pressed() -> void:
	tokens.append("11");update_tokens()

func _on_bpi_pressed() -> void:
	tokens.append("π");update_tokens()

func _on_brt_2_pressed() -> void:
	tokens.append("√2");update_tokens()

func _on_brt_3_pressed() -> void:
	tokens.append("√3");update_tokens()

func _on_bdiv_pressed() -> void:
	tokens.append("/");update_tokens()

func _on_bneg_pressed() -> void:
	tokens.append("-");update_tokens()

func _on_skip_pressed() -> void:
	tokens = [];update_tokens()
	make_question(rng)

func _on_clear_pressed() -> void:
	tokens = [];update_tokens()

func _on_submit_pressed() -> void:
	# check answer
	if len(tokens) > 0:
		var response = tokens_to_float(tokens)
		if is_equal_approx(response, answer):
			%Question.text = "Correct!"
		else:
			var answer_text = ""
			match answer_type:
				Answer.TAN:
					answer_text = tan_as_str(answer)
				Answer.COORD:
					answer_text = coord_as_str(answer)
				Answer.RAD:
					answer_text = as_text_multiple_of_pi(answer)
			%Question.text = "Incorrect, the correct answer is "+answer_text
