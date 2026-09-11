import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/heart_data_model.dart';
import '../services/medical_data_service.dart';
import 'all_patients_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final String patientId;

  const DoctorDashboardScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final Color deepBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);

  final MedicalDataService _dataService = MedicalDataService.instance;
  int _selectedChartIndex = 0; // 0: BPM, 1: SpO2, 2: Temp

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Tableau de Bord",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      "Espace Praticien - Dr. Sarah",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: const Icon(Icons.medical_services, color: Colors.white),
            ),
          ),
        ],
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
        child: StreamBuilder<HeartDataModel>(
          stream: _dataService.getVitalsStreamForPatient(widget.patientId),
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
                      "Récupération des données patient...",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientHeaderCard(),
                    const SizedBox(height: 20),
                    _buildVitalsCard(data),
                    const SizedBox(height: 20),
                    _buildInteractiveChartCard(),
                    const SizedBox(height: 20),
                    _buildRealTimeAnalysis(data),
                    const SizedBox(height: 20),
                    _buildSosButton(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPatientHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientId == "patient_real" ? "Ahmed Ben Ali" : "Patient de Test",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  "ID: #${widget.patientId} • Monitoring Actif",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.greenAccent.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "CONNECTÉ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard(HeartDataModel data) {
    return _buildGlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildVitalItem(
            "BPM",
            "${data.bpm}",
            Icons.favorite,
            Colors.red,
          ),
          _buildVitalItem(
            "SpO2",
            "${data.spO2}%",
            Icons.opacity,
            Colors.blue,
          ),
          _buildVitalItem(
            "Temp",
            "${data.temperature.toStringAsFixed(1)}°C",
            Icons.device_thermostat,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label, 
          style: GoogleFonts.inter(
            color: Colors.grey.shade700, 
            fontSize: 12, 
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInteractiveChartCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dataService.fetchPatientHistory("patient_demo"), // Dummy patient ID
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildGlassCard(
            padding: const EdgeInsets.all(20),
            child: const SizedBox(
              height: 300,
              width: double.infinity,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
              ),
            ),
          );
        }

        final data = snapshot.data ?? [];

        return _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Toggle Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tendances 24h",
                    style: GoogleFonts.inter(
                      color: deepBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ToggleButtons(
                      isSelected: [
                        _selectedChartIndex == 0,
                        _selectedChartIndex == 1,
                        _selectedChartIndex == 2,
                      ],
                      onPressed: (index) {
                        setState(() {
                          _selectedChartIndex = index;
                        });
                      },
                      color: Colors.grey.shade500,
                      selectedColor: Colors.white,
                      fillColor: _getChartColor(_selectedChartIndex),
                      borderRadius: BorderRadius.circular(12),
                      renderBorder: false,
                      constraints: const BoxConstraints(minHeight: 36, minWidth: 60),
                      children: const [
                        Text("BPM", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text("SpO2", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text("Temp", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Chart
              SizedBox(
                height: 200,
                width: double.infinity,
                child: _buildLineChart(data),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getChartColor(int index) {
    if (index == 0) return Colors.redAccent;
    if (index == 1) return Colors.blueAccent;
    return Colors.orangeAccent;
  }

  Widget _buildLineChart(List<Map<String, dynamic>> rawData) {
    List<FlSpot> spots = [];
    
    for (var point in rawData) {
      if (point['timestamp'] == null) continue;
      
      DateTime time = DateTime.fromMillisecondsSinceEpoch(point['timestamp']);
      
      // Filtrer pour n'afficher qu'un point toutes les 15 minutes environ,
      // utile si on a beaucoup de points réels.
      // (Si on a peu de points comme les 24 factices, ils passeront car "time.minute == 0").
      if (rawData.length > 50 && time.minute % 15 != 0) {
        continue;
      }
      
      double minutesSinceMidnight = time.hour * 60.0 + time.minute;
      double val = 0;
      
      if (_selectedChartIndex == 0) val = (point['bpm'] ?? 0).toDouble();
      else if (_selectedChartIndex == 1) val = (point['spO2'] ?? 0).toDouble();
      else val = (point['temperature'] ?? 0).toDouble();
      
      spots.add(FlSpot(minutesSinceMidnight, val));
    }

    // Assurer l'ordonnancement des X
    spots.sort((a, b) => a.x.compareTo(b.x));

    double dataMinY = spots.isEmpty ? 0 : spots.first.y;
    double dataMaxY = spots.isEmpty ? 100 : spots.first.y;
    for (var spot in spots) {
      if (spot.y < dataMinY) dataMinY = spot.y;
      if (spot.y > dataMaxY) dataMaxY = spot.y;
    }

    double minY = dataMinY;
    double maxY = dataMaxY;

    List<HorizontalLine> horizontalLines = [];

    if (_selectedChartIndex == 0) {
      if (minY > 40) minY = 40; 
      if (maxY < 110) maxY = 110;
      horizontalLines.add(HorizontalLine(
        y: 100,
        color: Colors.redAccent.withOpacity(0.5),
        strokeWidth: 1,
        dashArray: [5, 5],
      ));
      horizontalLines.add(HorizontalLine(
        y: 50,
        color: Colors.redAccent.withOpacity(0.5),
        strokeWidth: 1,
        dashArray: [5, 5],
      ));
    } else if (_selectedChartIndex == 1) {
      if (minY > 85) minY = 85; 
      if (maxY <= 100) maxY = 100;
      horizontalLines.add(HorizontalLine(
        y: 90,
        color: Colors.redAccent.withOpacity(0.5),
        strokeWidth: 1,
        dashArray: [5, 5],
      ));
    } else {
      minY = 35.0;
      maxY = 40.0;
      horizontalLines.add(HorizontalLine(
        y: 38.5,
        color: Colors.redAccent.withOpacity(0.5),
        strokeWidth: 1,
        dashArray: [5, 5],
      ));
    }

    if (maxY == minY) {
      minY -= 5;
      maxY += 5;
    } else if (_selectedChartIndex != 2) {
      double padding = (maxY - minY) * 0.1;
      minY -= padding;
      maxY += padding;
    }

    final chartColor = _getChartColor(_selectedChartIndex);

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toStringAsFixed(1),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: horizontalLines),
        minY: minY,
        maxY: maxY,
        minX: 0,        // 00:00
        maxX: 1439,     // 23:59 (en minutes)
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 4) > 0 ? ((maxY - minY) / 4) : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 240, // Un label toutes les 4 heures (240 minutes)
              getTitlesWidget: (value, meta) {
                int totalMins = value.toInt();
                int h = totalMins ~/ 60;
                int m = totalMins % 60;
                String timeStr = "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
                // Simplifier les affichages
                if (totalMins > 1440) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    timeStr,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: chartColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  chartColor.withOpacity(0.3),
                  chartColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeAnalysis(HeartDataModel data) {
    bool isBpmNormal = data.bpm >= 60 && data.bpm <= 100;
    bool isSpo2Normal = data.spO2 >= 95;
    bool isTempNormal = data.temperature < 37.5;

    String message;
    IconData statusIcon;
    Color statusColor;

    List<String> warnings = [];
    if (!isBpmNormal) warnings.add("BPM anormal (${data.bpm})");
    if (!isSpo2Normal) warnings.add("SpO2 faible (${data.spO2}%)");
    if (!isTempNormal) warnings.add("Temp élevée (${data.temperature.toStringAsFixed(1)}°C)");

    if (warnings.isEmpty) {
      message = "État Stable : Tous les paramètres sont dans les normes médicales.";
      statusIcon = Icons.check_circle_outline;
      statusColor = Colors.green;
    } else {
      statusIcon = Icons.warning_amber_rounded;
      statusColor = Colors.deepOrange;
      if (warnings.length == 1) {
        message = "Attention : ${warnings.first}. Les autres constantes sont stables.";
      } else {
        message = "Attention : Plusieurs paramètres hors normes (${warnings.join(', ')}).";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0, top: 4.0),
          child: Text(
            "Analyse de l'État en Temps Réel",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        _buildGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14, 
                        color: Colors.black87, 
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  const lat = "34.7471";
                  const lng = "10.7661";

                  // Intent pour l'application Google Maps
                  final googleMapsUri = Uri.parse(
                    "google.navigation:q=$lat,$lng",
                  );
                  // Fallback pour le navigateur
                  final browserUri = Uri.parse(
                    "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Lancement de la navigation vers le patient...",
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  try {
                    // Tente d'ouvrir l'application native Google Maps
                    if (await canLaunchUrl(googleMapsUri)) {
                      await launchUrl(googleMapsUri);
                    } else {
                      // Fallback sur le navigateur si l'app n'est pas installée
                      await launchUrl(
                        browserUri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  } catch (e) {
                    // En cas d'erreur, force l'ouverture dans le navigateur
                    await launchUrl(
                      browserUri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                icon: const Icon(Icons.explore, size: 18),
                label: const Text("Naviguer vers Domicile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSosButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text("Alerte SOS"),
                    content: const Text(
                      "Voulez-vous déclencher une intervention d'urgence ?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Annuler"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Mise à jour de Firebase : sensors/vitals/sos_active: true
                          FirebaseDatabase.instance
                              .ref('sensors/vitals')
                              .update({'sos_active': true});

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.green,
                              content: Text(
                                "Protocole d'urgence activé. Alerte envoyée aux secours et au dispositif patient.",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          "DÉCLENCHER",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "DÉCLENCHER SOS URGENCE",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<double> data;
  GraphPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint =
        Paint()
          ..color = const Color(0xFF0D47A1).withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

    final path = Path();
    final double step = size.width / (data.length - 1);

    double maxVal = 120;
    double minVal = 40;

    for (int i = 0; i < data.length; i++) {
      double val = data[i];
      if (val > maxVal) val = maxVal;
      if (val < minVal) val = minVal;

      double x = i * step;
      double y =
          size.height - ((val - minVal) / (maxVal - minVal) * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
