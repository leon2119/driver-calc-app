import 'package:flutter/material.dart';

void main() {
  runApp(const DriverReadOnlyMusterApp());
}

class DriverReadOnlyMusterApp extends StatelessWidget {
  const DriverReadOnlyMusterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ડ્રાઈવર મસ્ટર કાર્ડ',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: const DriverMusterCardScreen(),
    );
  }
}

class DriverMusterCardScreen extends StatefulWidget {
  const DriverMusterCardScreen({super.key});

  @override
  State<DriverMusterCardScreen> createState() => _DriverMusterCardScreenState();
}

class _DriverMusterCardScreenState extends State<DriverMusterCardScreen> {
  // Hardcoded mockup data representing what is synced from your Daily Excel file upload
  final String factoryNumber = "GJ 10 TD 003";
  final String driverNameGujarati = "હરીશ કસરાયા";
  final String currentMonth = "સપ્ટેમ્બર ૨૦૨૬";

  // Data Map populated via backend Excel sync: { Day: DailyRecord }
  final Map<int, DayRecord> _monthlyData = {
    1: DayRecord(isPresent: "3", advance: ""),
    3: DayRecord(isPresent: "2", advance: ""),
    // Remaining days will default to blank strings mimicking clean data fields
  };

  // Aggregated calculations drawn straight from structural database inputs
  double get totalPay => 14500.00; 
  double get totalAdvance => 2000.00;
  double get finalBalance => totalPay - totalAdvance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'મારું મસ્ટર કાર્ડ (Read-Only)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.pink.shade700,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Card(
          color: const Color(exportPinkColor), // Matching the physical pink card tone
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "MUSTER CARD / મસ્ટર કાર્ડ",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Top Meta Details
                _buildInfoRow("ગાડી નંબર / Factory No:", factoryNumber),
                _buildInfoRow("ડ્રાઈવરનું નામ / Worker Name:", driverNameGujarati),
                _buildInfoRow("મહિનો / Month:", currentMonth),
                const SizedBox(height: 15),

                // Main 31-Day Two-Column Grid Setup
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildMusterTableColumn(1, 16)),
                    const SizedBox(width: 4),
                    Expanded(child: _buildMusterTableColumn(17, 31)),
                  ],
                ),

                const Divider(height: 30, thickness: 2, color: Colors.black87),

                // Financial Footer Summary Boxes
                _buildFooterMetricRow("કુલ પગા૨ / TOTAL PAY", "₹ ${totalPay.toStringAsFixed(2)}"),
                _buildFooterMetricRow("એડવાન્સ / ADVANCE", "₹ ${totalAdvance.toStringAsFixed(2)}"),
                _buildFooterMetricRow("બાકી રકમ / BALANCE", "₹ ${finalBalance.toStringAsFixed(2)}", isBold: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black87, width: 1.5))),
              child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusterTableColumn(int startDay, int endDay) {
    return Table(
      border: TableBorder.all(color: Colors.black87, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(1.2), // Date
        1: FlexColumnWidth(1.5), // Present / Breakdown / Trip status
        2: FlexColumnWidth(1.5), // Advance
      },
      children: [
        // Table Sub-Header
        const TableRow(
          decoration: BoxDecoration(color: Colors.black12),
          children: [
            TableCell(child: Center(child: Text('તારીખ\n(Date)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
            TableCell(child: Center(child: Text('હાજરી\n(Pres)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
            TableCell(child: Center(child: Text('એડવાન્સ\n(Adv)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
          ],
        ),
        // Generating Row Blocks
        ...List.generate((endDay - startDay) + 1, (index) {
          int currentDay = startDay + index;
          DayRecord record = _monthlyData[currentDay] ?? DayRecord(isPresent: "", advance: "");

          return TableRow(
            children: [
              TableCell(
                child: Container(
                  height: 32,
                  color: Colors.black.withOpacity(0.05),
                  alignment: Alignment.center,
                  child: Text("$currentDay", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              TableCell(
                child: Container(
                  height: 32,
                  alignment: Alignment.center,
                  child: Text(record.isPresent, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 16)),
                ),
              ),
              TableCell(
                child: Container(
                  height: 32,
                  alignment: Alignment.center,
                  child: Text(record.advance, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildFooterMetricRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 14 : 12, color: Colors.black87)),
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87),
              color: isBold ? Colors.yellow.shade100 : Colors.white70,
            ),
            alignment: Alignment.centerRight,
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 16 : 14, color: isBold ? Colors.red.shade900 : Colors.black)),
          ),
        ],
      ),
    );
  }
}

class DayRecord {
  final String isPresent; // Displays presents, breakdown hours, or trips written in text string format
  final String advance;
  DayRecord({required this.isPresent, required this.advance});
}

const int exportPinkColor = 0xFFFFB2D1; // Accurate digital color tone matching physical card template
