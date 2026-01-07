# --Efficiency Tester Scene Main Script--
# Author: Fletcher Green

#-----------------------------------------------------------------------
# Section: Declarations
#-----------------------------------------------------------------------

extends Control

@export var slf_out_file: String # The name of the output files.
@export var slf_gguf_path: String # The path to the GGUF file to test with.

@onready var slf_model = $NobodyWhoModel # NobodyWhoModel child node.
@onready var slf_chat = $NobodyWhoChat # NobodyWhoChat child node.

var slf_test_num: int = 2 # The test number in the sequence. (Starts at 2 because I'm lazy)
var slf_start_time: int # Data member to hold the time the prompt started.
var slf_data_file: FileAccess # File data type to write response time.
var slf_output_file: FileAccess # File data type to write model output.

#-----------------------------------------------------------------------
# Section: Functions
#-----------------------------------------------------------------------

# --_ready Function--
# Description: Runs when a node and all of its children are ready. Creates the output files
#              necessary and starts the test function.
# Getting Output Files: Godot does not like writing files into the main file system.
#                       you can get the output files from this path on your computer:
#                       %APPDATA%\Godot\app_userdata\llm-efficiency-tester\
func _ready() -> void:
	slf_model.model_path = slf_gguf_path # Set the model node's path data member.
	
	# Create the paths for output files.
	var data_file_path = "user://" + slf_out_file + ".csv"
	var output_file_path = "user://" + slf_out_file + ".txt"
	
	# Initilise the file data types.
	slf_data_file = FileAccess.open(data_file_path, FileAccess.WRITE)
	slf_output_file = FileAccess.open(output_file_path, FileAccess.WRITE)
	
	# Call the test function.
	Test_LLM(slf_test_num)

# --Test_LLM Function--
# Description: Creates a prompt with a number of tokens dependent on the specific test number.
#              The prompt is an expression for the LLM to solve which will simplify to one.
#              Expressions have the following form: (1_1+1_2+...+1_n)/n.
# test_num: The test number in the sequence of total tests.
func Test_LLM(test_num: int) -> void:
		var num_tokens: int = (test_num * 2) - 1 # Calculate the number of tokens the test needs.
		
		# Form the expression for the LLM to calculate
		var prompt_str: String = "(1"
		for i in range(0, test_num - 1):
			prompt_str += "+1"
		prompt_str += ")/"
		prompt_str += str(test_num)
		
		# Write the first part of the line to CSV.
		slf_data_file.store_string(str(num_tokens))
		slf_data_file.store_string(", ")
		
		# Record the current time and prompt the LLM.
		slf_start_time = Time.get_ticks_usec()
		slf_chat.ask(prompt_str)

# --_on_nobody_who_chat_response_finished Function--
# Description: Records LLM output and elapsed time. Then, increments the test number
#              and calls the test function again. Stops execution if the test number reaches
#              the limit.
# response: The response given by the LLM.
func _on_nobody_who_chat_response_finished(response: String) -> void:
	slf_test_num += 1 # Increment test number.
	
	# Store data in files.
	slf_data_file.store_string(str(Time.get_ticks_usec() - slf_start_time))
	slf_data_file.store_string("\n")
	slf_output_file.store_string(response)
	slf_output_file.store_string("\n")
	
	# Stop after about 50 tests. Else run test again with new test number.
	if slf_test_num > 50:
		print("Tests complete. Check output files.")
		slf_data_file.close()
		slf_output_file.close()
	else:
		Test_LLM(slf_test_num)
