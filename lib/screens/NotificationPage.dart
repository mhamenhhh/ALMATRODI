import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  final bool refreshTrigger; // 👈 يجي من MainScreen

  const NotificationPage({Key? key, required this.refreshTrigger})
      : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didUpdateWidget(covariant NotificationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 👈 إذا تغير التريغر نعيد التحميل
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getStringList("notifications") ?? [];
    setState(() {
      _notifications = savedData.map((e) {
        try {
          final decoded = json.decode(e);
          if (decoded is Map<String, dynamic>) return decoded;
          return {"title": "❌ خطأ", "body": e, "time": ""};
        } catch (_) {
          return {"title": "❌ خطأ", "body": e, "time": ""};
        }
      }).toList();
    });
    print("📥 تم تحميل ${_notifications.length} إشعار");
  }

  Future<void> _clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("notifications");
    setState(() {
      _notifications = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑 تم مسح كل الإشعارات")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📩 إشعاراتي", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true, // ✅ العنوان بالمنتصف
        backgroundColor: Colors.teal,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              tooltip: "مسح الكل",
              onPressed: _clearNotifications,
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
        child: Text(
          "لا توجد إشعارات بعد",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final notif = _notifications[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: const Icon(Icons.notifications_active, color: Colors.teal, size: 28),
                title: Text(
                  notif['title'] ?? "بدون عنوان",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  notif['body'] ?? "بدون محتوى",
                  style: const TextStyle(color: Colors.black87),
                ),
                trailing: Text(
                  notif['time'] ?? "",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
