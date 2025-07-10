import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const DebugApp());
}

class DebugApp extends StatelessWidget {
  const DebugApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep Debug',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const DebugScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DebugScreen extends StatelessWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep App Debug'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.bedtime,
              size: 100,
              color: Colors.purple,
            ),
            SizedBox(height: 20),
            Text(
              'Sleep App is Running!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Debug mode activated',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}