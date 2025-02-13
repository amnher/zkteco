import 'package:flutter/material.dart';
import 'package:flutter_zkteco/flutter_zkteco.dart';
import 'package:flutter_zkteco/src/model/attendance_log.dart';
import 'package:flutter_zkteco/src/model/user_info.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:http/http.dart'
    show BaseClient, Client, BaseRequest, StreamedResponse;
import 'package:http/io_client.dart';

ZKTeco? fingerprintMachine;
List<AttendanceLog> logs = [];
List<UserInfo> users = [];
bool isConnected = false;
String model = '';
String status = 'Disconnected';

void main() => runApp(MyApp());

class GoogleAuthClient extends BaseClient {
  final Map<String, String> _headers;
  final Client _client = Client();

  GoogleAuthClient(this._headers);

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}

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
  final TextEditingController _ipController =
      TextEditingController(text: '192.168.110.201');
  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  /*void initState() {
    super.initState();
    con();
    connectAndFetchLogs();
  }*/

  void con() async {
    // Show dialog to get IP address
    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter IP Address'),
          content: TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              hintText: 'Enter IP address',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Connect'),
              onPressed: () {
                Navigator.of(context).pop(_ipController.text);
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      fingerprintMachine = ZKTeco(result, port: 4370);
      await fingerprintMachine!.initSocket();
      isConnected = await fingerprintMachine!.connect();
      print(isConnected);
      if (isConnected) {
        model = await fingerprintMachine!.getDeviceName();
        status = 'Connected';
        print(model);
      }
      setState(() {});
    }
  }

  void clearLogs() {
    setState(() {
      logs = [];
      users = [];
    });
  }

  Future<void> connectAndFetchLogs() async {
    if (isConnected) {
      final fetchedLogs = await fingerprintMachine!.getAttendanceLogs();
      setState(() {
        logs = fetchedLogs; // Update the logs list in state
      });
      for (var log in logs) {
        print('User ID: ${log.id}, Timestamp: ${log.timestamp}');
      }
    } else {
      print('Machine is not connected.');
    }
  }

// Add this method in the _MyHomePageState class
  Future<void> disconnect() async {
    try {
      print('Attempting to disconnect...');
      if (isConnected && fingerprintMachine != null) {
        await fingerprintMachine!.disconnect();
        setState(() {
          isConnected = false;
          model = '';
          status = 'Disconnected';
          logs = []; // Clear logs
          users = []; // Clear users
          fingerprintMachine = null; // Clear the machine instance
        });
        print('Successfully disconnected');
      } else {
        print('Machine is not connected.');
      }
    } catch (e) {
      print('Error during disconnect: $e');
      // Force reset state even if disconnect fails
      setState(() {
        isConnected = false;
        model = '';
        status = 'Disconnected';
        logs = [];
        users = [];
        fingerprintMachine = null;
      });
    }
  }

  Future<void> connectAndFetchUsers() async {
    if (isConnected) {
      final fetchedUsers = await fingerprintMachine!.getUsers();
      setState(() {
        users = fetchedUsers; // Update the global users list
      });
      for (var user in users) {
        print('User ID: ${user.userId}, Name: ${user.name}');
      }
    } else {
      print('Machine is not connected.');
    }
  }

  //final List<String> dataList = ['John Doe', 'Jane Smith', 'Alice Johnson'];
  final List<Map<String, dynamic>> dataList = [
    {'name': 'John Doe', 'age': 30, 'city': 'New York'},
    {'name': 'Jane Smith', 'age': 25, 'city': 'Los Angeles'},
    // Add more items as needed
  ];
  @override
  Widget build(BuildContext context) {
    List<PlutoColumn> logColumns = [
      PlutoColumn(
        title: 'ID',
        field: 'id',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'TIMESTAMP',
        field: 'timestamp',
        type: PlutoColumnType.text(),
        width: 200,
      ),
    ];

    // Columns for Users
    List<PlutoColumn> userColumns = [
      PlutoColumn(
        title: 'User ID',
        field: 'userId',
        type: PlutoColumnType.text(),
        width: 100,
      ),
      PlutoColumn(
        title: 'Name',
        field: 'name',
        type: PlutoColumnType.text(),
        width: 200,
      ),
    ];

    List<PlutoRow> logRows = logs.map((log) {
      return PlutoRow(
        cells: {
          'id': PlutoCell(value: log.id),
          'timestamp': PlutoCell(value: log.timestamp),
        },
      );
    }).toList();

    // Rows for Users
    List<PlutoRow> userRows = users.map((user) {
      return PlutoRow(
        cells: {
          'userId': PlutoCell(value: user.userId),
          'name': PlutoCell(value: user.name),
        },
      );
    }).toList();
    Future<void> uploadToGoogleDrive() async {
      try {
        print('Initializing Google Sign In...');
        final googleSignIn = GoogleSignIn.standard(
          scopes: [
            'https://www.googleapis.com/auth/drive.file',
          ],
          //signInOption: SignInOption.standard,
        );

        print('Checking current user...');
        final account =
            await googleSignIn.signInSilently() ?? await googleSignIn.signIn();

        if (account == null) {
          print('Sign in failed: User cancelled');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in cancelled')),
          );
          return;
        }

        print('Getting authentication...');
        final auth = await account.authentication;
        final headers = await account.authHeaders;

        print('Initializing Drive API...');
        final client = GoogleAuthClient(headers);
        final drive = DriveApi(client);

        // ... rest of your existing upload code ...

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Files uploaded successfully')),
        );
      } catch (e, stackTrace) {
        print('Error uploading to Google Drive: $e');
        print('Stack trace: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Fingerprint Status: $status, Model: $model'),
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
                  ElevatedButton(
                    onPressed: con,
                    child: Text('CONNECT'),
                  ),
                  ElevatedButton(
                    onPressed: uploadToGoogleDrive,
                    child: Text('Upload to Google Drive'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: 'Attendance Logs'),
                        Tab(text: 'Users'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          PlutoGrid(
                            key: ValueKey(
                                'logs-${logs.length}'), // Add this line
                            columns: logColumns,
                            rows: logRows,
                            onChanged: (PlutoGridOnChangedEvent event) {
                              print(event);
                            },
                            onLoaded: (PlutoGridOnLoadedEvent event) {
                              print(event);
                            },
                            configuration: PlutoGridConfiguration(
                              columnSize: const PlutoGridColumnSizeConfig(
                                autoSizeMode: PlutoAutoSizeMode.scale,
                              ),
                            ),
                          ),
                          PlutoGrid(
                            key: ValueKey(
                                'users-${users.length}'), // Add this line
                            columns: userColumns,
                            rows: userRows,
                            onChanged: (PlutoGridOnChangedEvent event) {
                              print(event);
                            },
                            onLoaded: (PlutoGridOnLoadedEvent event) {
                              print(event);
                            },
                            configuration: PlutoGridConfiguration(
                              columnSize: const PlutoGridColumnSizeConfig(
                                autoSizeMode: PlutoAutoSizeMode.scale,
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
