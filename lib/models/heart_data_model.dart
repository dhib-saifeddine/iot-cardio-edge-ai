class HeartDataModel {
  final int bpm;
  final int spO2;
  final double temperature;
  final String status;

  HeartDataModel({
    required this.bpm,
    required this.spO2,
    required this.temperature,
    required this.status,
  });

  // Pour Firebase
  factory HeartDataModel.fromMap(Map<dynamic, dynamic> map) {
    return HeartDataModel(
      bpm: (map['bpm'] as num?)?.toInt() ?? 0,
      spO2: (map['spo2'] as num?)?.toInt() ?? 0,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      status: map['ai_status'] ?? map['status'] ?? "Stable",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bpm': bpm,
      'spo2': spO2,
      'temperature': temperature,
      'ai_status': status,
    };
  }
}
