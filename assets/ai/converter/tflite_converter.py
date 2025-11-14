import tensorflow as tf

# Paths for classifier and segmenter
classifier_saved_model_dir = r"assets\ai\models\mobilenetv2_51classes_savedmodel"
classifier_tflite_file = r"assets\ai\models\mobilenetv2_51classes_quant.tflite"

segmenter_saved_model_dir = r"assets\ai\models\unet_segmentation_savedmodel"  # Update if different
segmenter_tflite_file = r"assets\ai\models\unet_segmentation_quant.tflite"

# Convert classifier to TFLite with quantization
converter = tf.lite.TFLiteConverter.from_saved_model(classifier_saved_model_dir)
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # Enable quantization
tflite_model = converter.convert()

# Save classifier TFLite model
with open(classifier_tflite_file, "wb") as f:
    f.write(tflite_model)

print(f"Classifier TFLite quantized model saved at: {classifier_tflite_file}")

# Convert segmenter to TFLite with quantization (if segmenter SavedModel exists)
try:
    converter_seg = tf.lite.TFLiteConverter.from_saved_model(segmenter_saved_model_dir)
    converter_seg.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_seg = converter_seg.convert()

    # Save segmenter TFLite model
    with open(segmenter_tflite_file, "wb") as f:
        f.write(tflite_seg)

    print(f"Segmenter TFLite quantized model saved at: {segmenter_tflite_file}")
except Exception as e:
    print(f"Segmenter conversion failed: {e}. Ensure segmenter SavedModel exists.")
