import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JsonDownloaderManager {
  static const _jsonFolder = "json_files";
  static const _baseUrl = "https://fapp-e0966-default-rtdb.firebaseio.com/products.json";
  static const _summaryUrl = "https://fapp-e0966-default-rtdb.firebaseio.com/upload_summary.json";

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("✅ تم التهيئة بدون Workmanager.");
  }

  static Future<void> requestNotificationPermission() async {
    debugPrint("🔔 الإشعارات معطلة حاليًا.");
  }

  static Future<void> downloadJsonNow() async {
    await _downloadJsonIfNeeded();
    //final prefs = await SharedPreferences.getInstance();
    //await prefs.setBool('onboarding_seen', false);
  }

  static Future<void> _downloadJsonIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final summaryResponse = await http.get(Uri.parse(_summaryUrl));

    if (summaryResponse.statusCode != 200) return;
    final remoteSummary = summaryResponse.body;
    final localSummary = prefs.getString('upload_summary');

    if (remoteSummary == localSummary){ print("📦 ماكو جديد"); return;}

    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final dir = await _getJsonDirectory();
      final now = DateTime.now();
      final fileName =
          "products_${now.year}-${_two(now.month)}-${_two(now.day)}_${_two(now.hour)}-${_two(now.minute)}.json";
      final file = await File('${dir.path}/$fileName').create();
      await file.writeAsString(response.body);

      await prefs.setString('upload_summary', remoteSummary);
      debugPrint("📦 تم تحميل الموديلات الجديدة بنجاح");
    }
  }

  static Future<void> deleteOldJsons() async {
    final dir = await _getJsonDirectory();
    if (await dir.exists()) {
      for (var file in dir.listSync()) {
        if (file is File && file.path.endsWith(".json")) {
          await file.delete();
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    for (var key in prefs.getKeys()) {
      if (key.startsWith('downloaded_')) {
        await prefs.remove(key);
      }
    }

    debugPrint("🧹 تم حذف الجيسونات القديمة وتنظيف التفضيلات.");
  }

  static Future<void> printLatestDownloadedJsonFile() async {
    final dir = await _getJsonDirectory();
    if (!(await dir.exists())) return;

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    if (files.isEmpty) return;

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    debugPrint('📁 أحدث ملف: ${files.first.path.split("/").last}');
  }

  static Future<Directory> _getJsonDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final jsonDir = Directory('${dir.path}/$_jsonFolder');
    if (!(await jsonDir.exists())) {
      await jsonDir.create(recursive: true);
    }
    return jsonDir;
  }

  static String _two(int x) => x.toString().padLeft(2, '0');
}
