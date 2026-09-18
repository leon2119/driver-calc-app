import "package:flutter/material.dart";
import "package:file_picker/file_picker.dart";
import "package:excel/excel.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_database/firebase_database.dart";
import "dart:typed_data";
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: const FirebaseOptions(apiKey: "AIzaSyKey", authDomain: "://firebaseapp.com", databaseURL: "https://firebaseio.com", projectId: "d", storageBucket: "://appspot.com", messagingSenderId: "1", appId: "1"));
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MainRouter()));
}
class MainRouter extends StatelessWidget {
  const MainRouter({super.key});
  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    final dId = uri.queryParameters["driverId"];
    return (uri.queryParameters["role"] == "admin" || dId == null) ? const AdminScreen() : DriverScreen(driverId: dId);
  }
}
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}
class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, String>> _rows = [];
  bool _loading = false;
  String? _name;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ADMIN PANEL")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(onPressed: _loading ? null : _loadExcel, child: Text(_name ?? "CHOOSE EXCEL SHEET")),
            const SizedBox(height: 20),
            if (_rows.isNotEmpty) ElevatedButton(onPressed: _loading ? null : _sync, child: const Text("SYNC DATA TO INTERNET")),
          ],
        ),
      ),
    );
  }
  Future<void> _loadExcel() async {
    setState(() => _loading = true);
    try {
      var res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ["xlsx"], withData: true);
      if (res != null && res.files.first.bytes != null) {
        _name = res.files.first.name;
        var ex = Excel.decodeBytes(res.files.first.bytes!);
        List<Map<String, String>> tmp = [];
        for (var t in ex.tables.keys) {
          var s = ex.tables[t];
          if (s != null && s.maxRows > 0) {
            List<String> hd = s.rows.map((c) => c?.value?.toString().trim() ?? "").toList();
            for (int i = 1; i < s.maxRows; i++) {
              Map<String, String> data = {};
              for (int j = 0; j < hd.length; j++) {
                if (j < s.rows[i].length) data[hd[j]] = s.rows[i][j]?.value?.toString().trim() ?? "";
              }
              if (data.values.any((e) => e.isNotEmpty)) tmp.add(data);
            }
          }
          break;
        }
        setState(() => _rows = tmp);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }
  Future<void> _sync() async {
    setState(() => _loading = true);
    try {
      var ref = FirebaseDatabase.instance.ref("drivers");
      for (var r in _rows) {
        String id = (r["driver_id"] ?? "").toLowerCase().replaceAll(" ", "_");
        String d = r["date_day"] ?? "";
        if (id.isEmpty || d.isEmpty) continue;
        await ref.child(id).child("meta").set({"factory_no": r["factory_no"] ?? "", "driver_name": r["driver_name_guj"] ?? "", "month": r["month_year"] ?? "", "total_pay": r["total_pay"] ?? "0", "advance": r["total_advance"] ?? "0"});
        await ref.child(id).child("days").child(d).set({"present_status": r["present_status"] ?? "", "advance_entry": r["day_advance"] ?? ""});
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SYNCED SUCCESS!")));
    } catch (_) {}
    setState(() => _loading = false);
  }
}
class DriverScreen extends StatelessWidget {
  final String driverId;
  const DriverScreen({super.key, required this.driverId});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref("drivers/$driverId").onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
        if (!snap.hasData || snap.data?.snapshot.value == null) return const Scaffold(body: Center(child: Text("NO CARD FOUND")));
        var data = snap.data!.snapshot.value as Map;
        var meta = data["meta"] ?? {};
        var days = data["days"] ?? {};
        return Scaffold(
          backgroundColor: Colors.pink.shade50,
          appBar: AppBar(title: Text("${meta["driver_name"] ?? ""} MUSTER CARD"), backgroundColor: Colors.pink),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text("Factory No: ${meta["factory_no"] ?? ""}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Month: ${meta["month"] ?? ""}"),
                const SizedBox(height: 10),
                Table(
                  border: TableBorder.all(),
                  children: [
                    const TableRow(children: [Center(child: Text("Day")), Center(child: Text("Pres")), Center(child: Text("Adv"))]),
                    ...List.generate(31, (i) {
                      var dIdx = (i + 1).toString();
                      var r = days[dIdx] ?? {};
                      return TableRow(children: [Center(child: Text(dIdx)), Center(child: Text(r["present_status"] ?? "")), Center(child: Text(r["advance_entry"] ?? ""))]);
                    })
                  ],
                ),
                const SizedBox(height: 20),
                Text("TOTAL PAY: ?${meta["total_pay"] ?? "0"}"),
                Text("ADVANCE: ?${meta["advance"] ?? "0"}"),
              ],
            ),
          ),
        );
      },
    );
  }
}
