import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as img_excel;

// Relational memory schema layers linking credentials across data sheets
Map<String, Map<String, dynamic>> _globalDriverMasterData = {}; // Keyed by Vehicle Number
Map<String, Map<String, String>> _globalLoginIdToVehicleRoster = {}; // Keyed by Driver ID (Login ID)

void main() {
  usePathUrlStrategy();
  runApp(const DriverCalcApp());
}

class DriverCalcApp extends StatelessWidget {
  const DriverCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Master Card Engine',
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
  final TextEditingController _loginIdController = TextEditingController();

  void _navigateToCardView() {
    final String enteredLoginId = _loginIdController.text.trim().toUpperCase();
    if (enteredLoginId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કૃપા કરીને આઈડી દાખલ કરો / Please enter Login ID')),
      );
      return;
    }

    // Lookup Engine: Validates if the entered code matches an uploaded Driver ID credential
    if (_globalLoginIdToVehicleRoster.containsKey(enteredLoginId)) {
      final rosterMatch = _globalLoginIdToVehicleRoster[enteredLoginId]!;
      final String linkedVehicle = rosterMatch['vehicleId'] ?? '';
      final String customDriverName = rosterMatch['driverName'] ?? 'UNKNOWN DRIVER';

      // Pull daily log logs using the linked vehicle code resolved from roster mapping
      if (_globalDriverMasterData.containsKey(linkedVehicle)) {
        final dailyData = _globalDriverMasterData[linkedVehicle]!;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverCardViewScreen(
              vehicleNumber: linkedVehicle,
              driverName: customDriverName,
              monthYearText: dailyData['monthText'] ?? 'સપ્ટેમ્બર ૨૦૨૬',
              daysData: Map<int, String>.from(dailyData['days'] ?? {}),
              advancesData: Map<int, String>.from(dailyData['advances'] ?? {}),
              totalPay: dailyData['totalPay'] ?? 0.0,
              advancePay: dailyData['advancePay'] ?? 0.0,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('આઈડી સાચું છે પણ ડેઇલી રિપોર્ટમાં આ ગાડી ($linkedVehicle) નો ડેટા મળ્યો નથી.\nEnsure Daily Report Excel is uploaded.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('આઈડી ખોટું છે: $enteredLoginId \nEnsure Master List is uploaded with this ID.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
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
              const Text('તમારો ડ્રાઈવર આઈડી દાખલ કરો / Enter Your Login ID', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: _loginIdController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_person),
                  labelText: 'ડ્રાઈવર આઈડી / Driver Login ID',
                  hintText: 'e.g. DRV102',
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
                  onPressed: _navigateToCardView,
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
class DriverCardViewScreen extends StatelessWidget {
  final String vehicleNumber;
  final String driverName;
  final String monthYearText;
  final Map<int, String> daysData;
  final Map<int, String> advancesData;
  final double totalPay;
  final double advancePay;

  const DriverCardViewScreen({
    super.key,
    required this.vehicleNumber,
    required this.driverName,
    required this.monthYearText,
    required this.daysData,
    required this.advancesData,
    required this.totalPay,
    required this.advancePay,
  });

  @override
  Widget build(BuildContext context) {
    double balancePay = totalPay - advancePay;

    return Scaffold(
      backgroundColor: const Color(0xFFF9A8CB), 
      appBar: AppBar(
        title: const Text('મારું માસ્ટર કાર્ડ (Read-Only)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFC2185B),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 480,
            margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFBC0DE),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFC2185B), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ડ્રાઈવરનું નામ / Driver Name: $driverName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text('ગાડી નંબર / Vehicle ID: $vehicleNumber', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                Text('મહિનો / Month: $monthYearText', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                const SizedBox(height: 15),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildAttendanceTable(1, 16)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildAttendanceTable(17, 31)),
                  ],
                ),
                
                const SizedBox(height: 25),
                
                _buildSummaryRow('કુલ પગાર / TOTAL PAY', totalPay),
                const SizedBox(height: 8),
                _buildSummaryRow('એડવાન્સ / ADVANCE', advancePay),
                const SizedBox(height: 8),
                _buildSummaryRow('બાકી રકમ / BALANCE', balancePay, isBalance: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTable(int startDay, int endDay) {
    return Table(
      border: TableBorder.all(color: Colors.black87, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(1.1),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          backgroundColor: const Color(0xFFF48FB1),
          children: const [
            Padding(padding: EdgeInsets.all(4), child: Text('તારીખ\n(Date)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            Padding(padding: EdgeInsets.all(4), child: Text('હાજરી\n(Pres)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            Padding(padding: EdgeInsets.all(4), child: Text('એડવાન્સ\n(Adv)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          ],
        ),
        for (int i = startDay; i <= endDay; i++)
          TableRow(
            backgroundColor: Colors.white,
            children: [
              Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text('$i', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  daysData[i] ?? '', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: (daysData[i] == 'ભાથું') ? Colors.red : (daysData[i] == 'આરામ' ? Colors.grey : Colors.purple),
                    fontSize: (daysData[i]?.length ?? 0) > 4 ? 10 : 13,
                  ), 
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(advancesData[i] ?? '', style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
            ],
          )
      ],
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBalance = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        Container(
          width: 170,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isBalance ? const Color(0xFFFFF59D) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black38),
          ),
          alignment: Alignment.centerRight,
          child: Text(
            '₹ ${value.toStringAsFixed(2)}', 
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isBalance ? Colors.red : Colors.black87),
          ),
        )
      ],
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

  final Map<int, String> _gujaratiMonths = {
    1: 'જાન્યુઆરી', 2: 'ફેબ્રુઆરી', 3: 'માર્ચ', 4: 'એપ્રિલ',
    5: 'મે', 6: 'જૂન', 7: 'જુલાઈ', 8: 'ઓગસ્ટ',
    9: 'સપ્ટેમ્બર', 10: 'ઓક્ટોબર', 11: 'નવેમ્બર', 12: 'ડિસેમ્બર'
  };

  String _convertToGujaratiDigits(String input) {
    const eng = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const guj = ['૦', '૧', '૨', '૩', '૪', '૫', '૬', '૭', '૮', '૯'];
    String output = input;
    for (int i = 0; i < eng.length; i++) {
      output = output.replaceAll(eng[i], guj[i]);
    }
    return output;
  }

  Future<void> _pickAndProcessDriverRoster() async {
    setState(() {
      _isUploading = true;
      _statusMessage = 'Opening Master List file selector...';
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.first.bytes != null) {
        var bytes = result.files.first.bytes!;
        var excel = img_excel.Excel.decodeBytes(bytes);
        String targetSheet = excel.tables.keys.first;
        var table = excel.tables[targetSheet];

        if (table != null && table.maxRows > 1) {
          Map<String, Map<String, String>> localLoginRoster = {};
          int loginIdIdx = 0;   
          int vehicleIdx = 1;   
          int driverNameIdx = 2; 

          var headerRow = table.rows.first;
          for (int c = 0; c < headerRow.length; c++) {
            String colName = headerRow[c]?.value?.toString().trim().toUpperCase() ?? '';
            if (colName.contains('LOGIN') || colName.contains('DRIVER ID') || colName.contains('આઈડી')) loginIdIdx = c;
            if (colName.contains('VEHICLE') || colName.contains('NUMBER') || colName.contains('ગાડી')) vehicleIdx = c;
            if (colName.contains('NAME') || colName.contains('DRIVER NAME') || colName.contains('નામ')) driverNameIdx = c;
          }

          for (int r = 1; r < table.rows.length; r++) {
            var row = table.rows[r];
            if (row.isEmpty || row.length <= vehicleIdx) continue;

            String rawLoginId = row[loginIdIdx]?.value?.toString().trim().toUpperCase() ?? '';
            String rawVehicleId = row[vehicleIdx]?.value?.toString().trim().toUpperCase() ?? '';
            String driverName = 'DRIVER';
            
            if (row.length > driverNameIdx && row[driverNameIdx]?.value != null) {
              driverName = row[driverNameIdx]!.value!.toString().trim();
            }

            if (rawLoginId.isNotEmpty && rawVehicleId.isNotEmpty) {
              localLoginRoster[rawLoginId] = {
                'vehicleId': rawVehicleId,
                'driverName': driverName,
              };
            }
          }

          setState(() {
            _globalLoginIdToVehicleRoster = localLoginRoster;
            _statusMessage = 'Success! Loaded ${_globalLoginIdToVehicleRoster.length} Dynamic Driver Login credentials profiles.';
            _isUploading = false;
          });
        }
      } else {
        setState(() {
          _statusMessage = 'Master List file picker canceled.';
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading Master Credentials Sheet: $e';
        _isUploading = false;
      });
    }
  }
  Future<void> _pickAndProcessDailyReport() async {
    setState(() {
      _isUploading = true;
      _statusMessage = 'Opening Daily Log Report file selector...';
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.first.bytes != null) {
        var bytes = result.files.first.bytes!;
        var excel = img_excel.Excel.decodeBytes(bytes);
        String targetSheet = excel.tables.keys.first;
        var table = excel.tables[targetSheet];

        if (table != null && table.maxRows > 1) {
          Map<String, Map<String, dynamic>> temporaryCache = {};
          int dateIdx = 0;
          int vehicleIdx = 1;
          int tripIdx = 2;
          int amountIdx = 9; 
          int driverIdx = 13;
          int remarksIdx = 14;
          int advanceIdx = -1; 

          var headerRow = table.rows.first;
          for (int c = 0; c < headerRow.length; c++) {
            String colName = headerRow[c]?.value?.toString().trim().toUpperCase() ?? '';
            if (colName.contains('DATE')) dateIdx = c;
            if (colName.contains('VEHICLE') || colName.contains('NUMBER')) vehicleIdx = c;
            if (colName.contains('TRIP')) tripIdx = c;
            if (colName.contains('DRIVER') || colName.contains('NAME')) driverIdx = c;
            if (colName.contains('REMARK')) remarksIdx = c;
            if (colName.contains('AMOUNT')) amountIdx = c;
            if (colName.contains('ADVANCE')) advanceIdx = c;
          }

          for (int r = 1; r < table.rows.length; r++) {
            var row = table.rows[r];
            if (row.isEmpty || row.length <= vehicleIdx) continue;

            String rawVehicleStr = row[vehicleIdx]?.value?.toString().trim().toUpperCase() ?? '';
            if (rawVehicleStr.isEmpty || rawVehicleStr.contains('NO DRIVER')) continue;

            String rawDateStr = row[dateIdx]?.value?.toString().trim() ?? '';
            int parsedDay = 1;
            String computedMonthText = 'સપ્ટેમ્બર ૨૦૨૬';

            if (rawDateStr.isNotEmpty) {
              try {
                List<String> dateParts = rawDateStr.contains('-') ? rawDateStr.split('-') : rawDateStr.split('/');
                if (dateParts.length >= 2) {
                  parsedDay = int.parse(dateParts[0]);
                  int monthNum = int.parse(dateParts[1]);
                  String yearNum = dateParts.length > 2 ? dateParts[2] : '2026';
                  computedMonthText = '${_gujaratiMonths[monthNum] ?? 'સપ્ટેમ્બર'} ${_convertToGujaratiDigits(yearNum)}';
                }
              } catch (_) {}
            }

            String fallbackDriverName = row.length > driverIdx ? row[driverIdx]?.value?.toString().trim() ?? 'UNKNOWN' : 'UNKNOWN';
            String tripValue = row.length > tripIdx ? row[tripIdx]?.value?.toString().trim() ?? '' : '';
            String remarksValue = row.length > remarksIdx ? row[remarksIdx]?.value?.toString().trim().toUpperCase() ?? '' : '';
            
            double lineAmount = 0.0;
            if (row.length > amountIdx && row[amountIdx]?.value != null) {
              lineAmount = double.tryParse(row[amountIdx]!.value!.toString()) ?? 0.0;
            }

            double lineAdvance = 0.0;
            if (advanceIdx != -1 && row.length > advanceIdx && row[advanceIdx]?.value != null) {
              lineAdvance = double.tryParse(row[advanceIdx]!.value!.toString()) ?? 0.0;
            }

            if (!temporaryCache.containsKey(rawVehicleStr)) {
              temporaryCache[rawVehicleStr] = {
                'driverName': fallbackDriverName,
                'monthText': computedMonthText,
                'days': <int, String>{},
                'advances': <int, String>{},
                'totalPay': 0.0,
                'advancePay': 0.0,
              };
            }

            var driverRecord = temporaryCache[rawVehicleStr]!;
            String cellAttendanceDisplay = '';
            
            if (remarksValue == 'BREAKDOWN') {
              cellAttendanceDisplay = 'ભાથું';
            } else if (remarksValue.contains('12_HRS_SHIFT') || remarksValue.contains('12_HRS_SHIFT') || remarksValue.contains('12 HRS SHIFT')) {
              cellAttendanceDisplay = '૧૨ કલાક';
            } else if (remarksValue.contains('24_HRS_SHIFT') || remarksValue.contains('24_HRS_SHIFT') || remarksValue.contains('24 HRS SHIFT')) {
              cellAttendanceDisplay = '૨૪ કલાક';
            } else if (remarksValue == 'OFF' || remarksValue.contains('HOLD')) {
              cellAttendanceDisplay = 'આરામ';
            } else {
              cellAttendanceDisplay = tripValue;
            }

            if (cellAttendanceDisplay.isNotEmpty) {
              driverRecord['days'][parsedDay] = cellAttendanceDisplay;
            }

            if (lineAdvance > 0) {
              driverRecord['advances'][parsedDay] = lineAdvance.toStringAsFixed(0);
              driverRecord['advancePay'] = (driverRecord['advancePay'] as double) + lineAdvance;
            }
            
            driverRecord['totalPay'] = (driverRecord['totalPay'] as double) + lineAmount;
          }

          setState(() {
            _globalDriverMasterData = temporaryCache;
            _statusMessage = 'Success! Loaded ${_globalDriverMasterData.length} daily operational activity logs profiles.';
            _isUploading = false;
          });
        }
      } else {
        setState(() {
          _statusMessage = 'Daily report upload canceled.';
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error analyzing daily data sheets: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('માસ્ટર એડમિન ડેશબોર્ડ / ADMIN PANEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Container(
            maxWidth: 550,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, size: 90, color: Colors.blueGrey),
                const SizedBox(height: 15),
                const Text('એડમિનિસ્ટ્રેટર વર્કસ્પેસ / ADMIN WORKSPACE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 15),
                Text(_statusMessage, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
                const SizedBox(height: 35),
                
                _isUploading
                    ? const SizedBox.shrink()
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          icon: const Icon(Icons.badge, color: Colors.white),
                          label: const Text('૧. માસ્ટર લિસ્ટ (ડ્રાઈવર આઈડી, ગાડી નંબર, નામ એક્સેલ શીટ)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          onPressed: _pickAndProcessDriverRoster,
                        ),
                      ),
                const SizedBox(height: 15),
                
                _isUploading
                    ? const CircularProgressIndicator(color: Colors.blueGrey)
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                          icon: const Icon(Icons.upload_file, color: Colors.white),
                          label: const Text('૨. ડેઇલી રિપોર્ટ સિક્કા એક્સેલ શીટ (Daily Trip Report)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          onPressed: _pickAndProcessDailyReport,
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

class AlignmentModifier { static const centerRight = Alignment.centerRight; }
