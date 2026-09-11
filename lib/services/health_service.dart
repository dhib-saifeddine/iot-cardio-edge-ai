import 'package:firebase_database/firebase_database.dart';
import '../models/heart_data_model.dart';

class HealthService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Flux de données en temps réel (sera utilisé dans l'étape suivante)
  Stream<HeartDataModel> getHealthDataStream() {
    return _dbRef.child('patient_data').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        return HeartDataModel.fromMap(data);
      }
      return HeartDataModel(
        bpm: 0,
        spO2: 0,
        temperature: 0.0,
        status: "Normal",
      );
    });
  }

  // Simulation d'envoi de SMS (Placeholder pour l'étape SMS/GPS)
  Future<void> sendEmergencySMS(String message, double lat, double long) async {
    // La logique avec 'telephony' sera implémentée ici
    print("Envoi SMS d'urgence: $message à ($lat, $long)");
  }
}
