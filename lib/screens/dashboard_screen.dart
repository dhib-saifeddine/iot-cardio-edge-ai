import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/heart_data_model.dart';
import '../widgets/monitoring_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  HeartDataModel _currentData = HeartDataModel(
    bpm: 72,
    spO2: 98,
    temperature: 36.6,
    status: "Normal",
  );

  final List<FlSpot> _bpmSpots = [];
  int _timerCount = 0;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    // Initialiser des données pour le graphique
    for (int i = 0; i < 10; i++) {
      _bpmSpots.add(FlSpot(i.toDouble(), 70.0 + (i % 3)));
    }
    _timerCount = 10;

    // Simuler des mises à jour en temps réel pour le graphique
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _timerCount++;
          double newValue = 65.0 + (DateTime.now().second % 15);
          _bpmSpots.add(FlSpot(_timerCount.toDouble(), newValue));
          if (_bpmSpots.length > 20) _bpmSpots.removeAt(0);
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _simulateCriticalData() {
    setState(() {
      _currentData = HeartDataModel(
        bpm: 110,
        spO2: 92,
        temperature: 38.5,
        status: "Alert",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isBpmCritical = _currentData.bpm > 100 || _currentData.bpm < 50;
    final bool isSpO2Critical = _currentData.spO2 < 95;
    final bool isTempCritical = _currentData.temperature > 38.0;

    // Définir les pages
    final List<Widget> pages = [
      _buildHomeContent(isBpmCritical, isSpO2Critical, isTempCritical),
      const Center(child: Text("Historique des relevés")),
      const Center(child: Text("Profil Patient")),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: Text(
          'VitalWatch IoT',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.blue.shade900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.circle,
              color: _isConnected ? Colors.green : Colors.red,
              size: 12,
            ),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Historique',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(
    bool isBpmCritical,
    bool isSpO2Critical,
    bool isTempCritical,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tableau de bord",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                onPressed: _simulateCriticalData,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),

          MonitoringCard(
            title: "Fréquence Cardiaque",
            value: _currentData.bpm.toString(),
            unit: "BPM",
            icon: Icons.favorite,
            baseColor: Colors.pink,
            isCritical: isBpmCritical,
          ),

          // Graphique BPM Temps Réel
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _bpmSpots,
                    isCurved: true,
                    color: Colors.pink.shade300,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.pink.shade300.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: MonitoringCard(
                  title: "SpO2",
                  value: _currentData.spO2.toString(),
                  unit: "%",
                  icon: Icons.water_drop,
                  baseColor: Colors.blue,
                  isCritical: isSpO2Critical,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MonitoringCard(
                  title: "Temp.",
                  value: _currentData.temperature.toStringAsFixed(1),
                  unit: "°C",
                  icon: Icons.thermostat,
                  baseColor: Colors.orange,
                  isCritical: isTempCritical,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              "URGENCE SOS",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
