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
  // Expanded layout to 8 Rows with pre-set permanent rates from your profile
  late final List<RowData> _topRows = [
    RowData(rate: 1033.0),
    RowData(rate: 350.0),
    RowData(rate: 1000.0),
    RowData(rate: 550.0),
    RowData(), // 5th row
    RowData(), // 6th row
    RowData(), // 7th row
    RowData(), // 8th row
  ];

  // Expanded layout to 5 Rows for Deductions
  late final List<RowData> _bottomRows = List.generate(5, (_) => RowData());

  double get _topTotal => _topRows.fold(0, (sum, row) => sum + row.result);
  double get _bottomTotal => _bottomRows.fold(0, (sum, row) => sum + row.result);
  double get _finalAmount => _topTotal - _bottomTotal;

  // Clear function that leaves the first 4 default rates intact
  void _clearInputs() {
    setState(() {
      // Clear all 8 top rows
      for (int i = 0; i < _topRows.length; i++) {
        _topRows[i].valueController.clear();
        _topRows[i].value = 0.0;
        
        // Only clear the rate field if it is NOT one of the first 4 permanent rates
        if (i >= 4) {
          _topRows[i].rateController.clear();
          _topRows[i].rate = 0.0;
        }
      }
      
      // Clear all 5 bottom deduction rows completely
      for (var row in _bottomRows) {
        row.valueController.clear();
        row.rateController.clear();
        row.value = 0.0;
        row.rate = 0.0;
      }
    });
  }

  @override
  void dispose() {
    for (var row in _topRows) {
      row.dispose();
    }
    for (var row in _bottomRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Allocation Calc'),
        backgroundColor: Colors.blueAccent,
        actions: [
          TextButton(
            onPressed: _clearInputs,
            child: const Text(
              'CLEAR',
              style: TextStyle(
                color: Colors.redAccent, 
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader("Earnings / Main Allocation (8 Rows)", Colors.green),
            ...List.generate(8, (index) => _buildCalculationRow(_topRows[index])),
            const SizedBox(height: 10),
            _buildTotalBadge("Top 8 Rows Total:", _topTotal, Colors.green),

            const Divider(height: 40, thickness: 2, color: Colors.grey),

            _buildSectionHeader("Deductions / Expenses (5 Rows)", Colors.red),
            ...List.generate(5, (index) => _buildCalculationRow(_bottomRows[index])),
            const SizedBox(height: 10),
            _buildTotalBadge("Bottom 5 Rows Total:", _bottomTotal, Colors.red),

            const SizedBox(height: 30),

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

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

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

  Widget _buildCalculationRow(RowData row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: row.valueController,
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
          Expanded(
            child: TextFormField(
              controller: row.rateController,
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

class RowData {
  double value;
  double rate;
  
  final TextEditingController valueController;
  final TextEditingController rateController;

  RowData({this.value = 0.0, this.rate = 0.0})
      : valueController = TextEditingController(text: value > 0 ? value.toString() : ''),
        rateController = TextEditingController(text: rate > 0 ? rate.toStringAsFixed(0) : '');

  double get result => value * rate;

  void dispose() {
    valueController.dispose();
    rateController.dispose();
  }
}
