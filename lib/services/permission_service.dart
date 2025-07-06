import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestSensorPermissions() async {
    final permissions = [
      Permission.sensors,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    bool allGranted = true;
    for (final status in statuses.values) {
      if (status != PermissionStatus.granted) {
        allGranted = false;
        break;
      }
    }

    return allGranted;
  }

  Future<bool> checkSensorPermissions() async {
    final sensorStatus = await Permission.sensors.status;
    return sensorStatus == PermissionStatus.granted;
  }

  Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('センサーアクセス許可'),
          content: const Text(
            '睡眠の質を分析するために、デバイスのモーションセンサーへのアクセスが必要です。\n\n'
            '設定からアプリのセンサー権限を有効にしてください。',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('設定を開く'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> handlePermissions(BuildContext context) async {
    if (await checkSensorPermissions()) {
      return true;
    }

    final granted = await requestSensorPermissions();
    if (!granted) {
      await showPermissionDialog(context);
      return false;
    }

    return true;
  }
}