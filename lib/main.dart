import 'package:flutter/material.dart';
import 'package:flutter_zkteco/flutter_zkteco.dart';
import 'package:flutter_zkteco/src/model/attendance_log.dart';
import 'package:flutter_zkteco/src/model/user_info.dart';
//import 'package:flutter_zkteco/src/user.dart';

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
  List<UserInfo> users = [];

  @override
  void initState() {
    super.initState();
    fingerprintMachine = ZKTeco('192.168.110.202', port: 4370);
  }

  void clearLogs() {
    setState(() {
      logs = [];
      users = [];
    });
  }

  Future<void> connectAndFetchLogs() async {
    await fingerprintMachine!.initSocket();
    print('Socket initialized.');
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

  Future<void> connectAndFetchUsers() async {
    await fingerprintMachine!.initSocket();
    print('Socket initialized.');
    bool isConnected = await fingerprintMachine!.connect();

    if (isConnected) {
      List<UserInfo> fetchedUsers = await fingerprintMachine!.getUsers();
      setState(() {
        users = fetchedUsers;
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
            Container(
              color: Colors.grey[200],
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: connectAndFetchLogs,
                    child: Text('Fetch Logs'),
                  ),
                  ElevatedButton(
                    onPressed: connectAndFetchUsers,
                    child: Text('Fetch Users'),
                  ),
                  ElevatedButton(
                    onPressed: clearLogs,
                    child: Text('Clear Logs and Users'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: users.isNotEmpty
                  ? ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text('User ID: ${users[index].userId}'),
                          subtitle: Text('Name: ${users[index].name}'),
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text('User ID: ${logs[index].id}'),
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
