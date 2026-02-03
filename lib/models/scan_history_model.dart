class ScanHistoryModel {
  final String id;
  final String imagePath;
  final String? diseaseKey;
  final String diseaseName;
  final double confidence;
  final String? plantType;
  final String? notes;
  final bool isTreated;
  final int timestamp;

  ScanHistoryModel({
    required this.id,
    required this.imagePath,
    this.diseaseKey,
    required this.diseaseName,
    required this.confidence,
    this.plantType,
    this.notes,
    this.isTreated = false,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'disease_key': diseaseKey,
      'disease_name': diseaseName,
      'confidence': confidence,
      'plant_type': plantType,
      'notes': notes,
      'is_treated': isTreated ? 1 : 0,
      'timestamp': timestamp,
    };
  }

  factory ScanHistoryModel.fromMap(Map<String, dynamic> map) {
    return ScanHistoryModel(
      id: map['id'] as String,
      imagePath: map['image_path'] as String,
      diseaseKey: map['disease_key'] as String?,
      diseaseName: map['disease_name'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      plantType: map['plant_type'] as String?,
      notes: map['notes'] as String?,
      isTreated: (map['is_treated'] as int? ?? 0) == 1,
      timestamp: map['timestamp'] as int,
    );
  }
}
