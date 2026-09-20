import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as img_excel;

void main() {
  usePathUrlStrategy();
  runApp(const DriverCalcApp());
}

class DriverCalcApp extends StatelessWidget {
  const DriverCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final String routeName = settings.name ?? '/';
        final Uri uri = Uri.parse(routeName);
        
        if (uri.queryParameters['role'] == 'admin' || routeName.contains('role=admin')) {
          return MaterialPageRoute(builder: (_) => const AdminDashboard());
        }
        return MaterialPageRoute(builder: (_) => const DriverLoginPage());
      },
    );
  }
}

class DriverLoginPage extends StatefulWidget {
  const DriverLoginPage({super.key});

  @override
  State<DriverLoginPage> createState() => _DriverLoginPageState();
}

class _DriverLoginPageState extends State<DriverLoginPage> {
  final TextEditingController _idController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('ડ્રાઈવર લોગીન પોર્ટલ / DRIVER PORTAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.pink,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: 450,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_shipping, size: 80, color: Colors.pink),
              const SizedBox(height: 20),
              const Text('લોગિન / LOGIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink)),
              const SizedBox(height: 10),
              const Text('તમારો વ્હીકલ નંબર દાખલ કરો / Enter Vehicle ID', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  labelText: 'ડ્રાઈવર આઈડી અથવા ગાડી નંબર / Driver ID or Vehicle No.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                  child: const Text('કાર્ડ જુઓ / VIEW CARD', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _statusMessage = 'Upload Excel spreadsheets here to sync drivers database updates.';
  bool _isUploading = false;

  // Operational function to trigger local file browser window picker
  Future<void> _pickAndProcessExcel() async {
    setState(() {
      _isUploading = true;
      _statusMessage = 'Opening file selector...';
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() {
          _statusMessage = 'Processing Excel sheet contents...';
        });

        // Use our isolated namespace img_excel package to parse bytes directly
        var bytes = result.files.first.bytes!;
        var excel = img_excel.Excel.decodeBytes(bytes);
        
        // Count sheets to confirm the library successfully parsed the file layout
        int sheetCount = excel.tables.keys.length;

        setState(() {
          _statusMessage = 'Success! Loaded file with $sheetCount sheet(s). Syncing to Firebase...';
          _isUploading = false;
        });
      } else {
        setState(() {
          _statusMessage = 'File selection canceled.';
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error reading file: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('માસ્ટર એડમિન ડેશબોર્ડ / ADMIN PANEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 100, color: Colors.blueGrey),
              const SizedBox(height: 20),
              const Text('એડમિનિસ્ટ્રેટર વર્કસ્પેસ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              Text(_statusMessage, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              _isUploading
                  ? const CircularProgressIndicator(color: Colors.blueGrey)
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      label: const Text('માસ્ટર એક્સેલ ફાઇલ અપલોડ કરો', style: TextStyle(color: Colors.white, fontSize: 16)),
                      onPressed: _pickAndProcessExcel,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
