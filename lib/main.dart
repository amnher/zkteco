import 'package:flutter/material.dart';
import 'package:flutter_zkteco/flutter_zkteco.dart';
import 'package:flutter_zkteco/src/model/attendance_log.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fingerprint Machine Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ZKTeco? fingerprintMachine;
  List<AttendanceLog> logs = [];

  @override
  void initState() {
    super.initState();
    fingerprintMachine = ZKTeco('192.168.110.201', port: 4370);
  }

  Future<void> connectAndFetchLogs() async {
    await fingerprintMachine!.initSocket();
    bool isConnected = await fingerprintMachine!.connect();

    if (isConnected) {
      List<AttendanceLog> fetchedLogs =
          await fingerprintMachine!.getAttendanceLogs();
      setState(() {
        logs = fetchedLogs;
      });
      await fingerprintMachine!.disconnect();
    } else {
      print('Failed to connect.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fingerprint Logs'),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: connectAndFetchLogs,
              child: Text('Fetch Logs'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('User ID: ${logs[index].uid}'),
                    subtitle: Text('Timestamp: ${logs[index].timestamp}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
