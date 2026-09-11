import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../models/heart_data_model.dart';
import '../services/medical_data_service.dart';

/// [PatientDashboardScreen] est l'écran principal de suivi pour le patient.
/// Cet écran affiche en temps réel les données de santé (BPM, SpO2, Température)
/// récupérées depuis Firebase Realtime Database.
class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({Key? key}) : super(key: key);

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> with SingleTickerProviderStateMixin {
  // Référence vers le service de données médicales partagé.
  final MedicalDataService _dataService = MedicalDataService.instance;

  late AnimationController _sosController;

  @override
  void initState() {
    super.initState();
    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sosController.dispose();
    super.dispose();
  }

  /// Gère l'appel d'urgence SOS avec confirmation.
  void _handleSOS() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D3B4C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Confirmation SOS",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Souhaitez-vous vraiment envoyer un appel d'urgence?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Annuler",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Appel d'urgence envoyé!"),
                    backgroundColor: Colors.red,
                  ),
                );
                // Le reste de votre logique Firebase/SMS se trouve ici
              },
              child: const Text(
                "Confirmer",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody:
          true, // Permet au contenu de s'étendre derrière la barre de navigation.
      body: Container(
        // Dégradé de fond personnalisé pour un effet premium médical.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade700, Colors.cyan.shade300],
          ),
        ),
        child: SafeArea(
          bottom: false,
          // Utilisation du StreamBuilder pour une mise à jour réactive (Real-time).
          // Il écoute le flux de données Firebase et reconstruit l'UI à chaque changement.
          child: StreamBuilder<HeartDataModel>(
            stream: _dataService.vitalsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        "Synchronisation Firebase...",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(child: Text("Erreur: ${snapshot.error}"));
              }

              // Utilisation du snapshot.data garanti par la vérification précédente.
              final HeartDataModel currentData = snapshot.data!;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(), // Section d'en-tête (Avatar, Titre).
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Affichage du statut détecté par l'IA (Alerte ou Normal).
                          _buildStatusCard(currentData.status),
                          const SizedBox(height: 20),
                          // Carte principale pour le rythme cardiaque (BPM).
                          _buildMetricCard(
                            title: "Fréquence Cardiaque",
                            value: currentData.bpm.toString(),
                            unit: "BPM",
                            accentColor: Colors.redAccent.shade100, // Pastel red
                            iconData: Icons.favorite,
                          ),
                          const SizedBox(height: 20),
                          // Ligne contenant les deux cartes secondaires : Oxygène et Température.
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCardSmall(
                                  title: "Oxygène",
                                  value: currentData.spO2.toString(),
                                  unit: "%",
                                  accentColor: Colors.lightBlueAccent, // Pastel blue
                                  iconData: Icons.water_drop,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMetricCardSmall(
                                  title: "Temp.",
                                  value: currentData.temperature.toStringAsFixed(1),
                                  unit: "°C",
                                  accentColor: Colors.orangeAccent, // Pastel orange
                                  iconData: Icons.thermostat,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const SizedBox(
                            height: 100,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.15).animate(
            CurvedAnimation(parent: _sosController, curve: Curves.easeInOut),
          ),
          child: FloatingActionButton.large(
            onPressed: _handleSOS,
            backgroundColor: Colors.redAccent,
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.emergency, color: Colors.white, size: 40),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Construit l'en-tête avec les icônes de profil et de notifications.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icône Profil avec interaction par SnackBar.
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Profil en cours de construction"),
                    ),
                  );
                },
                child: const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
              ),
              // Icône Notifications avec interaction par SnackBar.
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notifications")),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Comment allez-vous\naujourd'hui ?",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required Color accentColor,
    required IconData iconData,
  }) {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // FittedBox pour s'assurer que les grands nombres ne dépassent pas.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: GoogleFonts.inter(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          unit,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(iconData, size: 60, color: accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCardSmall({
    required String title,
    required String value,
    required String unit,
    required Color accentColor,
    required IconData iconData,
  }) {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Icon(
                iconData,
                size: 60,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget affichant le statut de santé analysé par l'IA (Alerte ou Normal).
  Widget _buildStatusCard(String status) {
    bool isAlert = status.toLowerCase() == "alert" || 
                   status.toLowerCase() == "alerte" || 
                   status.toLowerCase() == "malade";
                   
    String displayStatus = isAlert ? "Attention requise" : "État stable";
    Color statusColor = isAlert ? Colors.orangeAccent : Colors.greenAccent;

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAlert ? Icons.warning_rounded : Icons.check_circle_rounded,
                color: statusColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Analyse de Santé",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    displayStatus,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), // Adjusted to 0.2
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.3), // Changed to 0.3
              width: 0.5, // Thin border 0.5
            ),
          ),
          child: child,
        ),
      ),
    );
  }

}
