import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class CustomerDataManager {
  final String customerId;
  final String accSerial;
  static const _jsonFilePrefix = 'vouchers_';

  CustomerDataManager({required this.customerId, required this.accSerial});

  Future<String> _getLocalJsonPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_jsonFilePrefix$customerId.json';
  }

  static Future<String?> fetchCustomerSerial(String customerId) async {
    try {
      final url = Uri.parse('https://fapp-e0966-default-rtdb.firebaseio.com/customers/$customerId.json');
      final response = await http.get(url);
      if (response.statusCode == 200 && response.body != 'null') {
        final data = jsonDecode(response.body);
        return data['acc_serial'].toString();
      }
    } catch (e) {
      debugPrint('❌ خطأ أثناء جلب acc_serial: $e');
    }
    return null;
  }

  Future<void> startSync() async {
    debugPrint('🚀 بدء المزامنة الكاملة للزبون: $customerId (accSerial: $accSerial)');
    final file = File(await _getLocalJsonPath());
    if (!await file.exists()) {
      debugPrint('🆕 لا يوجد ملف جيسون محلي، تحميل كل القيود لأول مرة...');
      await _downloadAllVouchers();
    } else {
      debugPrint('📂 تم العثور على ملف محلي، سيتم تحديثه...');
      await _refreshLocalData();
    }
  }

  Future<void> _downloadAllVouchers() async {
    try {
      final url = Uri.parse('https://fapp-e0966-default-rtdb.firebaseio.com/vouchers_today/$accSerial.json');
      final response = await http.get(url);
      if (response.statusCode == 200 && response.body != 'null') {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final vouchers = data.values.cast<Map<String, dynamic>>().toList();
        final path = await _getLocalJsonPath();
        final file = File(path);
        await file.writeAsString(jsonEncode(vouchers));
        debugPrint('✅ تم تحميل ${vouchers.length} قيد للزبون $customerId وحفظها.');
      } else {
        debugPrint('❌ فشل تحميل القيود. كود السيرفر: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ أثناء تحميل القيود: $e');
    }
  }

  Future<void> _refreshLocalData() async {
    try {
      final path = await _getLocalJsonPath();
      final file = File(path);
      final content = await file.readAsString();
      List<dynamic> vouchers = jsonDecode(content);
      if (vouchers.isEmpty) {
        debugPrint('📂 الجيسون فارغ. سيتم تحميل الكل من جديد.');
        await _downloadAllVouchers();
        return;
      }

      vouchers.sort((a, b) {
        final aDate = DateTime.tryParse(a['voucher_date'] ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b['voucher_date'] ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      final lastVoucher = vouchers.first;
      final lastVoucherDateTime = DateTime.tryParse(lastVoucher['voucher_date'] ?? '') ?? DateTime(1970);
      final lastVoucherDate = DateTime(lastVoucherDateTime.year, lastVoucherDateTime.month, lastVoucherDateTime.day);

      vouchers = vouchers.where((voucher) {
        final voucherDateStr = voucher['voucher_date'] ?? '';
        final voucherDate = DateTime.tryParse(voucherDateStr);
        if (voucherDate == null) return true;
        final cleanDate = DateTime(voucherDate.year, voucherDate.month, voucherDate.day);
        return cleanDate.isBefore(lastVoucherDate);
      }).toList();

      await file.writeAsString(jsonEncode(vouchers));
      debugPrint('🗑️ تم حذف القيود الخاصة بتاريخ: $lastVoucherDate');

      final url = Uri.parse('https://fapp-e0966-default-rtdb.firebaseio.com/vouchers_today/$accSerial.json');
      final response = await http.get(url);
      if (response.statusCode == 200 && response.body != 'null') {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final now = DateTime.now();
        final newVouchers = data.values.where((entry) {
          final voucherDateStr = entry['voucher_date'];
          final voucherDate = DateTime.tryParse(voucherDateStr ?? '');
          if (voucherDate == null) return false;
          final cleanDate = DateTime(voucherDate.year, voucherDate.month, voucherDate.day);
          return !cleanDate.isBefore(lastVoucherDate) && !voucherDate.isAfter(now);
        }).cast<Map<String, dynamic>>().toList();

        final updatedVouchers = [...vouchers, ...newVouchers];
        await file.writeAsString(jsonEncode(updatedVouchers));
        debugPrint('✅ تم تحديث الجيسون للزبون $customerId بعد إضافة ${newVouchers.length} قيد.');
      } else {
        debugPrint('❌ فشل تحميل القيود الجديدة. كود السيرفر: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ أثناء تحديث الجيسون: $e');
    }
  }
}
