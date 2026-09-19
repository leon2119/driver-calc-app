import "package:flutter/material.dart";
import "package:file_picker/file_picker.dart";
import "package:excel/excel.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_database/firebase_database.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyYourActualAPIKeyHere_ExampleOnly",
      authDomain: "://firebaseapp.com",
      databaseURL: "https://firebaseio.com",
      projectId: "driver-muster-system",
      storageBucket: "://appspot.com",
      messagingSenderId: "123456789012",
      appId: "1:123456789012:web:abcdef1234567890"
    ),
  );
  runApp(const IntegratedMusterSystemApp());
}

class IntegratedMusterSystemApp extends StatelessWidget {
  const IntegratedMusterSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Uri uri = Uri.base;
    final String? roleParam = uri.queryParameters["role"];

    if (roleParam == "admin") {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "ટ્રાન્સપોર્ટ મસ્ટર સિસ્ટમ (એડમિન)",
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), 
          useMaterial3: true
        ),
        home: const AdminDashboardScreen(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "ટ્રાન્સપોર્ટ મસ્ટર સિસ્ટમ",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink), 
        useMaterial3: true
      ),
      home: const DriverGatewayScreen(),
    );
  }
}
class DriverGatewayScreen extends StatefulWidget {
  const DriverGatewayScreen({super.key});

  @override
  State<DriverGatewayScreen> createState() => _DriverGatewayScreenState();
}

class _DriverGatewayScreenState extends State<DriverGatewayScreen> {
  final TextEditingController _idController = TextEditingController();
  bool _isLoading = true;
  String? _savedDriverId;

  @override
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  Future<void> _checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString("saved_driver_id");
    if (savedId != null && savedId.isNotEmpty) {
      setState(() {
        _savedDriverId = savedId;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndLogin() async {
    String inputId = _idController.text.trim().toLowerCase().replaceAll(" ", "_");
    if (inputId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("કૃપા કરીને આઈડી અથવા ગાડી નંબર લખો"), 
          backgroundColor: Colors.red
        )
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("saved_driver_id", inputId);
    setState(() {
      _savedDriverId = inputId;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("saved_driver_id");
    _idController.clear();
    setState(() {
      _savedDriverId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.pink))
      );
    }

    if (_savedDriverId != null) {
      return DriverReadOnlyScreen(driverId: _savedDriverId!, onLogout: _logout);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("ટ્રાન્સપોર્ટ મસ્ટર કાર્ડ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.pink.shade700,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.local_shipping, size: 64, color: Colors.pink),
                  const SizedBox(height: 16),
                  const Text("લૉગિન / LOGIN", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("માહિતી જોવા માટે તમારો ડ્રાઈવર આઈડી અથવા ગાડી નંબર નાખો", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: "ડ્રાઈવર આઈડી / ગાડી નંબર",
                      hintText: "દા.ત. GJ10TD003",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveAndLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("કાર્ડ જુઓ / VIEW CARD", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, String>> _parsedDailyRows = [];
  bool _isProcessing = false;
  String? _fileName;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("drivers");

  Future<void> _pickAndParseDailyFile() async {
    setState(() => _isProcessing = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ["xlsx", "xls"], withData: true);
      if (result != null && result.files.first.bytes != null) {
        _fileName = result.files.first.name;
        var excel = Excel.decodeBytes(result.files.first.bytes!);
        List<Map<String, String>> tempRows = [];
        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet != null && sheet.maxRows > 0) {
            List<String> headers = sheet.rows.first.map((cell) => cell?.value?.toString().trim() ?? "").toList();
            for (int i = 1; i < sheet.maxRows; i++) {
              Map<String, String> rowData = {};
              for (int j = 0; j < headers.length; j++) {
                if (j < sheet.rows[i].length) {
                  rowData[headers[j]] = sheet.rows[i][j]?.value?.toString().trim() ?? "";
                }
              }
              if (rowData.values.any((e) => e.isNotEmpty)) tempRows.add(rowData);
            }
          }
          break; 
        }
        setState(() => _parsedDailyRows = tempRows);
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _syncDataToInternet() async {
    if (_parsedDailyRows.isEmpty) return;
    setState(() => _isProcessing = true);
    try {
      for (var row in _parsedDailyRows) {
        String rawId = row["driver_id"] ?? "";
        String dayStr = row["date_day"] ?? ""; 
        if (rawId.isEmpty || dayStr.isEmpty) continue;
        String cleanId = rawId.toLowerCase().replaceAll(" ", "_");
        await _dbRef.child(cleanId).child("meta").set({
          "factory_no": row["factory_no"] ?? "GJ 10 TD 003",
          "driver_name": row["driver_name_guj"] ?? "ડ્રાઈવર",
          "month": row["month_year"] ?? "સપ્ટેમ્બર ૨૦૨૬",
          "total_pay": row["total_pay"] ?? "0.00",
          "advance": row["total_advance"] ?? "0.00",
        });
        await _dbRef.child(cleanId).child("days").child(dayStr).set({
          "present_status": row["present_status"] ?? "",
          "advance_entry": row["day_advance"] ?? "",
        });
      }
      _showSnackBar("ઇન્ટરનેટ પર ડેટા સિંક થઈ ગયો!", Colors.green);
    } catch (e) {
      _showSnackBar("Sync Error: $e", Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ટ્રાન્સપોર્ટ માસ્ટર એડમિન પેનલ (Cloud Sync)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade900, centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text("હાજરી એક્સેલ ફાઈલ અપલોડ કરો", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickAndParseDailyFile,
                      icon: const Icon(Icons.file_upload), label: Text(_fileName ?? "એક્સેલ શીટ પસંદ કરો (.xlsx)"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_parsedDailyRows.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _syncDataToInternet,
                icon: const Icon(Icons.bolt),
                label: const Text("લાઇવ અપડેટ કરો / SYNC DATA TO DRIVERS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: _parsedDailyRows.isEmpty 
                  ? const Center(child: Text("કોઈ ડેટા લોડ થયો નથી."))
                  : ListView.builder(
                      itemCount: _parsedDailyRows.length,
                      itemBuilder: (context, idx) {
                        final r = _parsedDailyRows[idx];
                        return ListTile(
                          title: Text("ડ્રાઈવર: ${r["driver_name_guj"]} (ID: ${r["driver_id"]})"),
                          subtitle: Text("તારીખ: ${r["date_day"]} | હાજરી: ${r["present_status"]} | એડવાન્સ: ₹${r["day_advance"]}"),
                          trailing: const Icon(Icons.check_circle, color: Colors.green),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
class DriverReadOnlyScreen extends StatelessWidget {
  final String driverId;
  final VoidCallback onLogout;
  const DriverReadOnlyScreen({super.key, required this.driverId, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref("drivers/$driverId").onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.pink)));
        }
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.pink.shade700, actions: [IconButton(onPressed: onLogout, icon: const Icon(Icons.logout, color: Colors.white))]),
            body: const Center(child: Text("કાર્ડ મળ્યું નથી.\nકૃપા કરીને આઈડી તપાસો અને ફરી લૉગિન કરો.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          );
        }
        final Map<dynamic, dynamic> driverData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final Map<dynamic, dynamic> meta = driverData["meta"] ?? {};
        final Map<dynamic, dynamic> days = driverData["days"] ?? {};
        double totalPay = double.tryParse(meta["total_pay"]?.toString() ?? "0") ?? 0.0;
        double advance = double.tryParse(meta["advance"]?.toString() ?? "0") ?? 0.0;
        double balance = totalPay - advance;
        return Scaffold(
          backgroundColor: Colors.grey.shade200,
          appBar: AppBar(
            title: Text("${meta["driver_name"] ?? "મારું"} મસ્ટર કાર્ડ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.pink.shade700, 
            centerTitle: true,
            actions: [IconButton(onPressed: onLogout, icon: const Icon(Icons.logout, color: Colors.white), tooltip: "બીજું આઈડી નાખો")],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              color: const Color(0xFFFFB2D1), elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), color: Colors.black87,
                        child: const Text("MUSTER CARD / મસ્ટર કાર્ડ (ફક્ત વાંચવા માટે)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text("ગાડી નંબર: ${meta["factory_no"] ?? ""}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("નામ: ${meta["driver_name"] ?? ""}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("મહિનો: ${meta["month"] ?? ""}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 15),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDaysTable(1, 16, days)),
                        const SizedBox(width: 4),
                        Expanded(child: _buildDaysTable(17, 31, days)),
                      ],
                    ),
                    const Divider(height: 30, color: Colors.black),
                    _buildFooterMetric("કુલ પગા૨ / TOTAL PAY", "₹ ${totalPay.toStringAsFixed(2)}"),
                    _buildFooterMetric("એડવાન્સ / ADVANCE", "₹ ${advance.toStringAsFixed(2)}"),
                    _buildFooterMetric("બાકી રકમ / BALANCE", "₹ ${balance.toStringAsFixed(2)}", isBold: true),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDaysTable(int start, int end, Map<dynamic, dynamic> daysData) {
    return Table(
      border: TableBorder.all(color: Colors.black87),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Colors.black12),
          children: [
            TableCell(child: Center(child: Text("તારીખ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
            TableCell(child: Center(child: Text("હાજરી", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
            TableCell(child: Center(child: Text("એડવાન્સ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
          ],
        ),
        ...List.generate((end - start) + 1, (idx) {
          int targetDay = start + idx;
          var dayRecord = daysData[targetDay.toString()] ?? {};
          return TableRow(
            children: [
              TableCell(child: Container(height: 28, color: Colors.black12, alignment: Alignment.center, child: Text("$targetDay", style: const TextStyle(fontWeight: FontWeight.bold)))),
              TableCell(child: Container(height: 28, alignment: Alignment.center, child: Text(dayRecord["present_status"]?.toString() ?? "", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)))),
              TableCell(child: Container(height: 28, alignment: Alignment.center, child: Text(dayRecord["advance_entry"]?.toString() ?? "", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildFooterMetric(String title, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 13 : 11)),
          Container(
            width: 120, padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(border: Border.all(color: Colors.black), color: isBold ? Colors.yellow.shade100 : Colors.white70),
            alignment: Alignment.centerRight, child: Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: isBold ? Colors.red.shade900 : Colors.black)),
          )
        ],
      ),
    );
  }
}
