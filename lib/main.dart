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

Future<DriftIsolate> createDriftIsolate() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final path = p.join(dbFolder.path, 'shared_db.sqlite');
  final driftIsolate = await DriftIsolate.spawn(() {
    return NativeDatabase(File(path));
  });
  return driftIsolate;
}




void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  final isolate = await createDriftIsolate();
  kDebugPrint('Application 1: DriftIsolate created successfully: $isolate');

  // final receivePort = ReceivePort();
  // final sendPort = receivePort.sendPort;
  //
  // bool isRegistered = IsolateNameServer.registerPortWithName(
  //   sendPort,
  //   'audit_db_local_isolate',
  // );
  //
  // if (isRegistered) {
  //   kDebugPrint('SendPort registered successfully in Application 1');
  // } else {
  //   kDebugPrint('Failed to register SendPort in Application 1');
  // }
  //
  // receivePort.listen((message) {
  //   // Handle incoming messages if needed
  //   kDebugPrint('Received message: $message');
  // });

  // // Ensure that the databases are initialized properly in separate isolates before running the app.
  await DatabaseIsolate.createAndRegisterDriftIsolate(AuditDatabaseType.local);
  await DatabaseIsolate.createAndRegisterDriftIsolate(AuditDatabaseType.remote);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});



  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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