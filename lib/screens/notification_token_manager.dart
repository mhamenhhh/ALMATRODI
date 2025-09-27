import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  final String customerKey; // مثل: "-Oabc123xyz" (id من Firebase)

  NotificationManager(this.customerKey);

  /// توليد وحفظ التوكن
  Future<void> generateAndSyncToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        try {
          await FirebaseDatabase.instance
              .ref("customers/$customerKey")
              .update({"token": token});

          await prefs.remove("pending_token");
          print("✅ Token uploaded: $token");
        } catch (e) {
          await prefs.setString("pending_token", token);
          print("⚠️ Token saved locally due to error: $token");
        }
      }
    } catch (e) {
      print("❌ Failed to get token: $e");
    }
  }

  /// إعادة رفع التوكن إذا كان محفوظ محليًا
  Future<void> tryResendPendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("pending_token");

    if (token != null) {
      try {
        await FirebaseDatabase.instance
            .ref("customers/$customerKey")
            .update({"token": token});
        await prefs.remove("pending_token");
        print("✅ Pending token re-uploaded: $token");
      } catch (e) {
        print("⚠️ Failed to re-upload token: $e");
      }
    }
  }
}
