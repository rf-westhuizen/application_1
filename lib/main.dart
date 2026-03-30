import 'dart:isolate';
import 'dart:ui';

import 'package:audit_db_package/audit_db_package.dart';
import 'package:device_info_fetcher/device_info_fetcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:log_db_package/log_db_package.dart';
import 'package:scotch_analyser/scotch_analyser.dart';
import 'package:scotch_dev_error/logging/logging.dart';
import 'package:sqlite_postgresql_connector/sqlite_postgresql_connector.dart';
import 'package:yaml_parser_fetcher/yaml_parser_fetcher.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
// import 'package:drift/isolate.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import 'package:drift/native.dart';
// import 'dart:io';
import 'package:shared_database/shared_database.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // First get the FlutterView.
  FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

  // Dimensions in physical pixels (px)
  Size sizeP = view.physicalSize;
  double widthP = sizeP.width;
  double heightP = sizeP.height;

  // Dimensions in logical pixels (dp)
  Size sizeL = view.physicalSize / view.devicePixelRatio;
  double widthL = sizeL.width;
  double heightL = sizeL.height;

  print('FlutterView dimensions: ');
  print('Physical pixels: ${widthP}x${heightP} px');
  print('Logical pixels: ${widthL}x${heightL} dp');

  // Initialize the SharedDatabase
  //await SharedDatabase.initialize();

  // Initialize the LogDb — hosts the SQLite file at /sdcard/log_db.sqlite
  // over a local TCP socket (port 4041) so any part of the app can reach it
  // via LogDb.localSqlite or LogDb.aLocalSqlite without passing the instance
  // around.  sync: false disables the 10-minute postgres sync timer which is
  // not needed during development.

  if (defaultTargetPlatform == TargetPlatform.windows) {
    await AuditDb.listenerInit();
    await LogDb.listenerInit();
  }

  final _ = await ScotchAnalyserBuilder(deviceSpecificIdentifier: '9222011411')
    .withSentry('https://c82a6bfcb36f009cb9a0ba2423cc3bed@o4508340938801152.ingest.de.sentry.io/4508364663095376')
    //.withTalker()
    //.withClarity('clarityProjectId')
    //.withScotchLogger() // Not implemented yet
    .build();

  //await Future.delayed(Duration(seconds: 10));

  ScotchAnalyser.instance.info('ScotchAnalyser: info');
  ScotchAnalyser.instance.log('ScotchAnalyser: log');
  ScotchAnalyser.instance.debug('ScotchAnalyser: debug');
  ScotchAnalyser.instance.warning('ScotchAnalyser: warning');
  ScotchAnalyser.instance.error('ScotchAnalyser: error');
  ScotchAnalyser.instance.critical('ScotchAnalyser: exception');
  //ScotchAnalyser.instance.handle(Exception('ScotchAnalyser: exception'), StackTrace.current, 'ScotchAnalyser: exception message');
  //ScotchAnalyser.instance.handle(Error(), StackTrace.current, 'ScotchAnalyser: error message');



  // await AuditDb.listenerInit();
  // await LogDb.listenerInit();

  // Future<String> getDeviceSerial() async {
  //   final deviceSerial = await getDeviceInfo().aSyncSerial;
  //   return deviceSerial;
  // }
  //
  // Future<String> getYamlSoftware() async {
  //   final yamlSoftware = await getYamlData().aSyncSoftware;
  //   return yamlSoftware;
  // }
  //
  // Future<String> getYamlVersion() async {
  //   final yamlVersion = await getYamlData().aSyncVersion;
  //   return yamlVersion;
  // }
  //
  // final deviceSerial = await getDeviceSerial();
  // final deviceSoftware = await getYamlSoftware();
  // final deviceVersion = await getYamlVersion();
  //
  // print('deviceInfo: getDeviceSerial: $deviceSerial');
  // print('deviceInfo: getYamlSoftware: $deviceSoftware');
  // print('deviceInfo: getYamlVersion: $deviceVersion');

  await getDeviceInfo().aSyncSerial;
  await getYamlData().aSyncSoftware;
  await getYamlData().aSyncVersion;
  kDebugPrint('Device Serial: ${getDeviceInfo().serial}');
  kDebugPrint('Software: ${getYamlData().software}');
  kDebugPrint('Version: ${getYamlData().version}');

  SqlitePostgresqlConnectorHooks.register(
    serialFunction: () => getDeviceInfo().serial,
    softwareFunction: () => getYamlData().software,
    versionFunction: () => getYamlData().version,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}


class HomeScreen extends StatelessWidget {

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application 1')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ElevatedButton(
            //   onPressed: () async {
            //     for (var i = 0; i < 25; i++) {
            //       await Future.delayed(const Duration(milliseconds: 200));
            //       final userId = await SharedDatabase.local().into(SharedDatabase.local().userTable).insert(UserTableCompanion.insert(name: 'User from App 1'));
            //       print('Inserted user with id: $userId');
            //     }
            //   },
            //   child: Text('Insert Loop from App 1'),
            // ),
            // SizedBox.fromSize(size: const Size(0, 20)),
            // ElevatedButton(
            //   onPressed: () async {
            //       final users = await SharedDatabase.local().select(SharedDatabase.local().userTable).get();
            //       for (var user in users) {
            //         print('User: ${user.id}, ${user.name}');
            //       }
            //   },
            //   child: Text('Fetch Users from App 1'),
            // ),
            // SizedBox.fromSize(size: const Size(0, 20)),
            // ElevatedButton(
            //   onPressed: () async {
            //     // to check if the isolate is registered
            //     final sendPort = IsolateNameServer.lookupPortByName('drift_isolate');
            //     if (sendPort == null) {
            //       print('Failed to find the Drift isolate.');
            //     } else {
            //       print('Drift isolate found.');
            //     }
            //   },
            //   child: Text('Check Isolate Registration'),
            // ),
            // SizedBox.fromSize(size: const Size(0, 20)),
            ElevatedButton(
              onPressed: () async {
                // final deviceSerial = await getDeviceInfo().aSyncSerial;
                // final deviceSoftware = await getYamlData().aSyncSoftware;
                // final deviceVersion = await getYamlData().aSyncVersion;

                final localLogDb = LogDb.localSqlite();

                if (localLogDb  == null) {
                  print('Insert Log: LogDb not available');
                  return;
                }

                final companion = LogsCompanion(
                  id: Value(UuidPostgresGenerator.generatedUuidValue()),
                  key: const Value('LOG Final Insert PRESS'),
                  data: const Value('Insert basic Log record button pressed from HomeScreen'),
                  // meta: Value(deviceSoftware),
                  // version: Value(deviceVersion),
                  date: Value(PgDateTimeExt.now()),
                  synced: const Value(false),
                  ts: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
                  deviceId: const Value('9222011411'),
                );

                try{
                  await localLogDb.into(localLogDb.logs).insert(companion);
                }catch(e, stack){
                  print('Insert Log: exception: $e, stack: $stack');
                }

              },
              child: const Text('Insert Log'),
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
    //_initializeDatabases();
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
      // runInsert();
    });
  }

  Future<void> _initializeDatabases() async {
    kDebugPrint('inside application 1:');

    // Check if the local database isolate is accessible
    final localDb = await AuditDb.localSqlite();
    kDebugPrint('Local audit database initialized: ${localDb != null}');

    // Check if the remote database isolate is accessible
    final remoteDb = await AuditDb.postgres();
    kDebugPrint('Remote audit database initialized: ${remoteDb != null}');
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
                onPressed: runInsertLog,
                tooltip: 'Insert Local Log',
                child: const Icon(Icons.arrow_circle_down),
              ),
            ),
            // Align(
            //   alignment: Alignment.bottomRight,
            //   child: FloatingActionButton(
            //     onPressed: _incrementCounter,
            //     tooltip: 'Increment',
            //     child: const Icon(Icons.add),
            //   ),
            // ),
            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: FloatingActionButton(
            //     onPressed: runInsertLoop,
            //     tooltip: 'Insert Loop',
            //     child: const Icon(Icons.loop),
            //   ),
            // ),
          ],
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }

  // void runInsert() async {
  //
  //   // Getting the required information.
  //   final deviceSerial = await getDeviceInfo().aSyncSerial;
  //   final deviceSoftware = await getYamlData().aSyncSoftware;
  //   final deviceVersion = await getYamlData().aSyncVersion;
  //
  //   for (var i = 0; i < 1; i++) {
  //     final record = ScotchPaymentRequest(
  //       id: UuidValue.fromString(Uuid().v4()).toString(),
  //       serial: deviceSerial,
  //       origin: 'Pepkor DateTime test',
  //       software: deviceSoftware,
  //       version: deviceVersion,
  //       refId: 'Pepkor - E65',
  //       refType: RefType.none,
  //       tenderType: TenderType.unknown,
  //       synced: false,
  //       //date: PgDateTime(resultDate),
  //       //date: PgDateTime(DateTime.now()),
  //       date: PgDateTimeExt.now(),
  //       transactionId: null,
  //       amount: 7850,
  //       cashBack: null,
  //       tip: null,
  //       callbackUrl: null,
  //       ts: 1661930423,
  //     );
  //
  //     // insert into the local sqlite
  //     final localDb = await AuditDb.localSqlite();
  //     await localDb!.auditDao.createRequest(record);
  //
  //     kDebugPrint('Record inserted: $record');
  //
  //   }
  // }

  // void runInsertLoop() async {
  //
  //   // Getting the required information.
  //   final deviceSerial = await getDeviceInfo().aSyncSerial;
  //   final deviceSoftware = await getYamlData().aSyncSoftware;
  //   final deviceVersion = await getYamlData().aSyncVersion;
  //
  //   for (var i = 0; i < 10; i++) {
  //     final record = ScotchPaymentRequest(
  //       id: UuidValue.fromString(Uuid().v4()).toString(),
  //       serial: deviceSerial,
  //       origin: 'Pepkor DateTime test',
  //       software: deviceSoftware,
  //       version: deviceVersion,
  //       refId: 'Pepkor - E65',
  //       refType: RefType.none,
  //       tenderType: TenderType.unknown,
  //       synced: false,
  //       //date: PgDateTime(resultDate),
  //       //date: PgDateTime(DateTime.now()),
  //       date: PgDateTimeExt.now(),
  //       transactionId: null,
  //       amount: 7850,
  //       cashBack: null,
  //       tip: null,
  //       callbackUrl: null,
  //       ts: 1661930423,
  //     );
  //
  //     // insert into the local sqlite
  //     final localDb = await AuditDb.localSqlite();
  //     await localDb!.auditDao.createRequest(record);
  //
  //     kDebugPrint('Record inserted: $record');
  //
  //   }
  // }
  
  void runInsertLog() async {
    // Grab device/app metadata the same way the other insert methods do.
    // final deviceSerial = await getDeviceInfo().aSyncSerial;
    // final deviceSoftware = await getYamlData().aSyncSoftware;
    // final deviceVersion = await getYamlData().aSyncVersion;

    // Resolve the local LogDb instance that was hosted in main() via
    // LogDb.listenerInit().  aLocalSqlite returns a Future<LogDb? Function()>
    // — we await it to get the factory, then call it to get the instance.
    final localLogDb = await LogDb.aLocalSqlite;

    if (localLogDb() == null) {
      kDebugPrint('runInsertLog: LogDb not available — was listenerInit called?');
      return;
    }

    final companion = LogsCompanion(
      id: Value(UuidPostgresGenerator.generatedUuidValue()),
      key: const Value('APP_1_LOG'),
      data: const Value('Log entry inserted from runInsertLog()'),
      // meta: Value(deviceSoftware),
      // version: Value(deviceVersion),
      date: Value(PgDateTimeExt.now()),
      synced: const Value(false),
      ts: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      deviceId: const Value('9222011411'),
    );

    try{
      await localLogDb()!.into(localLogDb()!.logs).insert(companion);
    }catch(e, stack){
      kDebugPrint('runInsertLog: exception: $e, stack: $stack');
    }

  }

}
