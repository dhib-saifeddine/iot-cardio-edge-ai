import 'package:firebase_database/firebase_database.dart';
import '../models/heart_data_model.dart';
import 'dart:async';
import 'dart:math';

/// [MedicalDataService] est un service singleton qui centralise la récupération
/// des données de santé depuis Firebase pour les partager entre les différents écrans.
class MedicalDataService {
  // Instance unique (Singleton)
  static final MedicalDataService _instance = MedicalDataService._internal();
  factory MedicalDataService() => _instance;
  static MedicalDataService get instance => _instance;

  MedicalDataService._internal();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(
    'sensors/vitals',
  );

  // Liste pour stocker l'historique des points de données (pour les graphes).
  final List<double> _historyBpm = [];
  final List<double> _historyStatus = [];

  /// [vitalsStream] retourne un flux direct depuis Firebase. Chaque nouvel abonné
  /// recevra immédiatement la valeur actuelle stockée dans la base de données.
  Stream<HeartDataModel> get vitalsStream {
    return _dbRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return HeartDataModel(
          bpm: 0,
          spO2: 100,
          temperature: 37.0,
          status: "Aucune donnée",
        );
      }

      // Conversion sécurisée des données Firebase.
      final Map<Object?, Object?> data =
          event.snapshot.value as Map<Object?, Object?>;
      final model = HeartDataModel.fromMap(data);

      // Mise à jour de l'historique pour le graphe (évite les doublons via une logique interne).
      if (model.bpm > 0) {
        if (_historyBpm.isEmpty || _historyBpm.last != model.bpm.toDouble()) {
          _historyBpm.add(model.bpm.toDouble());
          if (_historyBpm.length > 50) _historyBpm.removeAt(0);
        }
      }

      // Mise à jour de l'historique de statut (0 = Stable, 1 = Anomalie)
      double riskValue = 0.0;
      String s = model.status.toLowerCase();
      if (!(s.contains("normal") || s == "stable" || s == "stable")) {
        riskValue = 1.0;
      }

      // On ajoute toujours le point de statut pour construire la tendance temporelle
      _historyStatus.add(riskValue);
      if (_historyStatus.length > 50) _historyStatus.removeAt(0);

      return model;
    });
  }

  /// Retourne un flux de données spécifique à un patient sans casser le flux original
  Stream<HeartDataModel> getVitalsStreamForPatient(String patientId) {
    if (patientId == "patient_real") {
      // Pour le patient réel, on renvoie directement le flux de l'ESP32.
      return vitalsStream;
    } else {
      // Pour les autres/test, on cible un noeud différent
      DatabaseReference testRef = FirebaseDatabase.instance.ref('test_sensors/vitals');
      return testRef.onValue.map((event) {
        if (event.snapshot.value == null) {
           return HeartDataModel(
             bpm: 72,
             spO2: 98,
             temperature: 36.6,
             status: "Stable (Test)",
           );
        }
        final Map<Object?, Object?> data = event.snapshot.value as Map<Object?, Object?>;
        return HeartDataModel.fromMap(data);
      });
    }
  }


  List<double> get historyBpm => List.unmodifiable(_historyBpm);
  List<double> get historyStatus => List.unmodifiable(_historyStatus);

  void dispose() {
    // Pas besoin de fermer le stream Firebase ici, il est géré par les StreamBuilders.
  }

  /// Récupère l'historique sur 24h d'un patient. 
  /// S'il n'y a pas de données, génère 24 points factices (un par heure).
  Future<List<Map<String, dynamic>>> fetchPatientHistory(String patientId) async {
    final historyRef = FirebaseDatabase.instance.ref('history/$patientId');
    final snapshot = await historyRef.get();
    
    List<Map<String, dynamic>> history = [];
    
    if (snapshot.exists && snapshot.value != null) {
      final dataObj = snapshot.value;
      if (dataObj is Map) {
        dataObj.forEach((key, value) {
          if (value is Map) {
            history.add({
              'timestamp': value['timestamp'],
              'bpm': (value['bpm'] ?? 0).toDouble(),
              'spO2': (value['spO2'] ?? 0).toDouble(),
              'temperature': (value['temperature'] ?? 0).toDouble(),
            });
          }
        });
      }
      
      // Trier par timestamp
      history.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
      
      return history;
    }
    
    // Si vide, génère des données factices sur 24h pour la démonstration
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    Random rand = Random();
    
    for (int i = 0; i < 24; i++) {
      DateTime pointTime = startOfDay.add(Duration(hours: i));
      history.add({
        'timestamp': pointTime.millisecondsSinceEpoch,
        'bpm': 70.0 + rand.nextDouble() * 20.0,     // 70 - 90
        'spO2': 94.0 + rand.nextDouble() * 5.0,     // 94 - 99
        'temperature': 36.5 + rand.nextDouble() * 1.3, // 36.5 - 37.8
      });
    }
    
    return history;
  }
}
