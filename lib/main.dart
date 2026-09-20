import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:excel/excel.dart' as img_excel;

void main() {
  // Fix the blank screen error by using Hash routing strategy safely on Vercel
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
        // Handle the incoming administrative URL parameters cleanly
        final Uri uri = Uri.parse(settings.name ?? '/');
        if (uri.queryParameters['role'] == 'admin') {
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
        backgroundColor: Colors.pink[700],
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
              Icon(Icons.local_shipping, size: 80, color: Colors.pink[700]),
              const SizedBox(height: 20),
              Text('લોગિન / LOGIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink[900])),
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
                    backgroundColor: Colors.pink[700],
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

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('માસ્ટર એડમિન ડેશબોર્ડ / ADMIN PANEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings, size: 100, color: Colors.blueGrey[700]),
              const SizedBox(height: 20),
              Text('એડમિનિસ્ટ્રેટર વર્કસ્પેસ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
              const SizedBox(height: 10),
              const Text('Upload Excel spreadsheets here to sync drivers database updates.', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text('માસ્ટર એક્સેલ ફાઇલ અપલોડ કરો', style: TextStyle(color: Colors.white, fontSize: 16)),
                onPressed: () {
                  // Operational endpoint call for img_excel parser goes here
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
