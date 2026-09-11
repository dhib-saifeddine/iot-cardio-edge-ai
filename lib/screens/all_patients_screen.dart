import 'package:flutter/material.dart';
import 'dart:ui';

class AllPatientsScreen extends StatelessWidget {
  const AllPatientsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data for the patient list
    final List<Map<String, dynamic>> patients = [
      {
        "name": "Ahmed Ben Ali",
        "id": "PA-001",
        "status": "Stable",
        "bpm": "72",
        "spo2": "98%",
      },
      {
        "name": "Sami Toumi",
        "id": "PA-002",
        "status": "Urgence",
        "bpm": "115",
        "spo2": "89%",
      },
      {
        "name": "Mariem Isaoui",
        "id": "PA-003",
        "status": "Stable",
        "bpm": "68",
        "spo2": "97%",
      },
      {
        "name": "Yassin Mansour",
        "id": "PA-004",
        "status": "Stable",
        "bpm": "75",
        "spo2": "99%",
      },
      {
        "name": "Leila Dridi",
        "id": "PA-005",
        "status": "Urgence",
        "bpm": "102",
        "spo2": "91%",
      },
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Gestion des Patients",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade700, Colors.cyan.shade300],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${patients.length} Patients Monitored",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(Icons.filter_list, color: Colors.white70),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    final bool isUrgent = patient['status'] == "Urgence";

                    return _buildPatientListItem(patient, isUrgent);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientListItem(Map<String, dynamic> patient, bool isUrgent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.person,
                    color: isUrgent ? Colors.redAccent.shade100 : Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(patient['status'], isUrgent),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildVitalMini(
                      Icons.favorite,
                      patient['bpm'],
                      Colors.pinkAccent,
                    ),
                    const SizedBox(height: 8),
                    _buildVitalMini(
                      Icons.opacity,
                      patient['spo2'],
                      Colors.blueAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isUrgent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isUrgent
                ? Colors.redAccent.withOpacity(0.2)
                : Colors.greenAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isUrgent
                  ? Colors.redAccent.withOpacity(0.5)
                  : Colors.greenAccent.withOpacity(0.5),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color:
              isUrgent
                  ? Colors.redAccent.shade100
                  : Colors.greenAccent.shade100,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVitalMini(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
