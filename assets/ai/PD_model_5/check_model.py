import tensorflow as tf

interpreter = tf.lite.Interpreter(model_path=r"assets/ai/PD_model_5/model_from_savedmodel.tflite")
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input:", input_details)
print("Output:", output_details)
