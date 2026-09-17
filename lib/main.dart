import 'package:flutter/material.dart';

void main() {
  runApp(const DriverCalcApp());
}

class DriverCalcApp extends StatelessWidget {
  const DriverCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CalculationScreen(),
    );
  }
}

class CalculationScreen extends StatefulWidget {
  const CalculationScreen({super.key});

  @override
  State<CalculationScreen> createState() => _CalculationScreenState();
}

class _CalculationScreenState extends State<CalculationScreen> {
  // Store dynamic data for 5 top rows and 3 bottom rows
  final List<RowData> _topRows = List.generate(5, (_) => RowData());
  final List<RowData> _bottomRows = List.generate(3, (_) => RowData());

  // Calculates the sums and final final amount
  double get _topTotal => _topRows.fold(0, (sum, row) => sum + row.result);
  double get _bottomTotal => _bottomRows.fold(0, (sum, row) => sum + row.result);
  double get _finalAmount => _topTotal - _bottomTotal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Allocation Calc'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SECTION 1: TOP 5 ROWS ---
            _buildSectionHeader("Earnings / Main Allocation (5 Rows)", Colors.green),
            ...List.generate(5, (index) => _buildCalculationRow(_topRows[index])),
            const SizedBox(height: 10),
            _buildTotalBadge("Top 5 Rows Total: ", _topTotal, Colors.green),

            const Divider(height: 40, thickness: 2, color: Colors.grey),

            // --- SECTION 2: BOTTOM 3 ROWS ---
            _buildSectionHeader("Deductions / Expenses (3 Rows)", Colors.red),
            ...List.generate(3, (index) => _buildCalculationRow(_bottomRows[index])),
            const SizedBox(height: 10),
            _buildTotalBadge("Bottom 3 Rows Total: ", _bottomTotal, Colors.red),

            const SizedBox(height: 30),

            // --- FINAL RESULT CARD ---
            Card(
              color: Colors.blue.shade900,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      "FINAL AMOUNT DUE",
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "\$${_finalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "(Top Total - Bottom Total)",
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontStyle: FontStyle.italic),
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

  // Component to build Section Headings
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // Component to display Sub-Totals
  Widget _buildTotalBadge(String label, double val, Color color) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(
          "$label \$${val.toStringAsFixed(2)}",
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
        ),
      ),
    );
  }

  // Horizontal Grid Layout for a Single Row (Box 1, Box 2, Box 3)
  Widget _buildCalculationRow(RowData row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Box 1: Value Input
          Expanded(
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (val) {
                setState(() {
                  row.value = double.tryParse(val) ?? 0.0;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // Box 2: Rate Input
          Expanded(
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Rate',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (val) {
                setState(() {
                  row.rate = double.tryParse(val) ?? 0.0;
                });
              },
            ),
          ),
          const SizedBox(width: 8),

          // Box 3: Read-only Multiplication Result
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400),
              ),
              alignment: Alignment.center,
              child: Text(
                row.result > 0 ? row.result.toStringAsFixed(2) : "0.00",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data Model to handle values per row cleanly
class RowData {
  double value = 0.0;
  double rate = 0.0;
  double get result => value * rate;
}
