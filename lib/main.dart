import 'dart:isolate';
import 'dart:ui';

import 'package:audit_db_package/audit_db_package.dart';
import 'package:device_info_fetcher/device_info_fetcher.dart';
import 'package:flutter/material.dart';
import 'package:scotch_dev_error/logging/logging.dart';
import 'package:sqlite_postgresql_connector/sqlite_postgresql_connector.dart';
import 'package:yaml_parser_fetcher/yaml_parser_fetcher.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/isolate.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:shared_database/shared_database.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Ensure Application 1 creates and registers the DriftIsolate.
  final driftIsolate  = await createDriftIsolate();

  // Register the isolate's send port with a unique name
  final registered = IsolateNameServer.registerPortWithName(
    driftIsolate.connectPort,
    'drift_isolate',
  );

  if (!registered) {
    print('Failed to register drift isolate.');
  } else {
    print('Drift isolate registered successfully.');
  }


  runApp(MyApp(driftIsolate: driftIsolate));
}

class MyApp extends StatelessWidget {

  final DriftIsolate driftIsolate;

  const MyApp({super.key, required this.driftIsolate});



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(driftIsolate: driftIsolate),
    );
  }
}


class HomeScreen extends StatelessWidget {
  final DriftIsolate driftIsolate;

  const HomeScreen({super.key, required this.driftIsolate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Application 1')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final connection = await driftIsolate.connect();
                final db = SharedDatabase(connection);
                for (var i = 0; i < 25; i++) {
                  await Future.delayed(const Duration(milliseconds: 500));
                  final userId = await db.into(db.userTable).insert(UserTableCompanion.insert(name: 'User from App 1'));
                  print('Inserted user with id: $userId');
                }
              },
              child: Text('Insert Users from App 1'),
            ),
            SizedBox.fromSize(size: const Size(0, 20)),
            ElevatedButton(
              onPressed: () async {
                final sendPort = IsolateNameServer.lookupPortByName('drift_isolate');
                if (sendPort == null) {
                  print('Failed to find the Drift isolate.');
                } else {
                  final driftIsolate = DriftIsolate.fromConnectPort(sendPort);
                  final connection = await driftIsolate.connect();
                  final db = SharedDatabase(connection);
                  final users = await db.select(db.userTable).get();
                  for (var user in users) {
                    print('User: ${user.id}, ${user.name}');
                  }
                }

              },
              child: Text('Fetch Users from App 1'),
            ),
            SizedBox.fromSize(size: const Size(0, 20)),
            ElevatedButton(
              onPressed: () async {
                // to check if the isolate is registered
                final sendPort = IsolateNameServer.lookupPortByName('drift_isolate');
                if (sendPort == null) {
                  print('Failed to find the Drift isolate.');
                } else {
                  //If the isolate is found, it connects to it,
                  print('Drift isolate found. Inserting a user...');
                  final driftIsolate = DriftIsolate.fromConnectPort(sendPort);
                  final connection = await driftIsolate.connect();
                  final db = SharedDatabase(connection);
                  final userId = await db.into(db.userTable).insert(UserTableCompanion.insert(name: 'User inserted from Check button'));
                  print('Inserted user with id: $userId');
                }
              },
              child: Text('Check Isolate Registration'),
            ),
          ],
        ),
      ),
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    kDebugPrint('inside application 1:');
    _initializeDatabases();
    // final localDb = AuditDb.local();
    // final remoteDb = AuditDb.postgres();
  }

  // @override
  // void dispose() {
  //   // Ensure to shut down the isolate when the app is disposed
  //   DatabaseIsolate.shutdownIsolate();
  //   super.dispose();
  // }

  void _incrementCounter() {
    setState(() {
      _counter++;
      runInsert();
    });
  }

  Future<void> _initializeDatabases() async {
    kDebugPrint('inside application 1:');

    // Check if the local database isolate is accessible
    final localDb = await AuditDb.local();
    kDebugPrint('Local database initialized: ${localDb != null}');

    // Check if the remote database isolate is accessible
    final remoteDb = await AuditDb.postgres();
    kDebugPrint('Remote database initialized: ${remoteDb != null}');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        floatingActionButton: Stack(
          alignment: Alignment.bottomRight,
          children: <Widget>[
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: _incrementCounter,
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton(
                onPressed: runInsertLoop,
                tooltip: 'Insert Loop',
                child: const Icon(Icons.loop),
              ),
            ),
          ],
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }

  void runInsert() async {

    // Getting the required information.
    final deviceSerial = await getDeviceInfo().aSyncSerial;
    final deviceSoftware = await getYamlData().aSyncSoftware;
    final deviceVersion = await getYamlData().aSyncVersion;

    for (var i = 0; i < 1; i++) {
      final record = ScotchPaymentRequest(
        id: UuidValue.fromString(Uuid().v4()).toString(),
        serial: deviceSerial,
        origin: 'Pepkor DateTime test',
        software: deviceSoftware,
        version: deviceVersion,
        refId: 'Pepkor - E65',
        refType: RefType.none,
        tenderType: TenderType.unknown,
        synced: false,
        //date: PgDateTime(resultDate),
        //date: PgDateTime(DateTime.now()),
        date: PgDateTimeExt.now(),
        transactionId: null,
        amount: 7850,
        cashBack: null,
        tip: null,
        callbackUrl: null,
        ts: 1661930423,
      );

      // insert into the local sqlite
      final localDb = await AuditDb.local();
      await localDb.auditDao.createRequest(record);

      kDebugPrint('Record inserted: $record');

    }
  }

  void runInsertLoop() async {

    // Getting the required information.
    final deviceSerial = await getDeviceInfo().aSyncSerial;
    final deviceSoftware = await getYamlData().aSyncSoftware;
    final deviceVersion = await getYamlData().aSyncVersion;

    for (var i = 0; i < 10; i++) {
      final record = ScotchPaymentRequest(
        id: UuidValue.fromString(Uuid().v4()).toString(),
        serial: deviceSerial,
        origin: 'Pepkor DateTime test',
        software: deviceSoftware,
        version: deviceVersion,
        refId: 'Pepkor - E65',
        refType: RefType.none,
        tenderType: TenderType.unknown,
        synced: false,
        //date: PgDateTime(resultDate),
        //date: PgDateTime(DateTime.now()),
        date: PgDateTimeExt.now(),
        transactionId: null,
        amount: 7850,
        cashBack: null,
        tip: null,
        callbackUrl: null,
        ts: 1661930423,
      );

      // insert into the local sqlite
      final localDb = await AuditDb.local();
      await localDb.auditDao.createRequest(record);

      kDebugPrint('Record inserted: $record');

    }
  }

}
