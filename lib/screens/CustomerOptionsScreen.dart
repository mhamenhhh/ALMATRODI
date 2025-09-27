import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class CustomerOptionsScreen extends StatefulWidget {
  const CustomerOptionsScreen({super.key});

  @override
  State<CustomerOptionsScreen> createState() => _CustomerOptionsScreenState();
}

class _CustomerOptionsScreenState extends State<CustomerOptionsScreen> {
  String? customerId;
  String? accSerial;
  bool isLoading = true;
  bool isFetching = false; // 👈 شريط التحميل
  List<Map<String, dynamic>> vouchers = [];

  double totalCredit = 0;
  String lastPayInDate = '';

  DateTime selectedFromDate = DateTime.now();
  DateTime selectedToDate = DateTime.now();

  late TextEditingController fromDateController;
  late TextEditingController toDateController;

  @override
  void initState() {
    super.initState();
    fromDateController = TextEditingController();
    toDateController = TextEditingController();
    fromDateController.text = formatDate(selectedFromDate);
    toDateController.text = formatDate(selectedToDate);

    _initPage();
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('customer_id');
    if (id == null) {
      setState(() => isLoading = false);
      return;
    }
    setState(() => customerId = id);

    final acc = await fetchCustomerSerial(id);
    if (acc != null) {
      setState(() => accSerial = acc);
      await _loadCustomerInfo(id);
      await _loadVoucherData(acc, from: selectedFromDate, to: selectedToDate);
    }
    setState(() => isLoading = false);
  }

  Future<String?> fetchCustomerSerial(String customerId) async {
    final url = Uri.parse(
        'https://fapp-e0966-default-rtdb.firebaseio.com/customers/$customerId.json');
    final response = await http.get(url);
    if (response.statusCode == 200 && response.body != 'null') {
      final data = json.decode(response.body);
      return data['acc_serial']?.toString();
    }
    return null;
  }

  Future<void> _loadCustomerInfo(String customerId) async {
    final url = Uri.parse(
        'https://fapp-e0966-default-rtdb.firebaseio.com/customers/$customerId.json');
    final res = await http.get(url);
    if (res.statusCode == 200 && res.body != 'null') {
      final data = json.decode(res.body);
      setState(() {
        totalCredit =
            double.tryParse(data['total_credit']?.toString() ?? '0') ?? 0;
        lastPayInDate = data['last_pay_in_date'] ?? '';
      });
    }
  }

  Future<void> _loadVoucherData(String accSerial,
      {DateTime? from, DateTime? to}) async {
    setState(() => isFetching = true); // 👈 إظهار الشريط
    final List<Map<String, dynamic>> result = [];

    final start = from ?? DateTime.now();
    final end = to ?? DateTime.now();

    for (DateTime date = start;
    !date.isAfter(end);
    date = date.add(const Duration(days: 1))) {
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final url = Uri.parse(
          "https://fapp-e0966-default-rtdb.firebaseio.com/vouchers_today/$accSerial/$dateKey.json");

      final response = await http.get(url);
      if (response.statusCode == 200 && response.body != "null") {
        final data = json.decode(response.body) as Map<String, dynamic>;
        data.forEach((k, v) {
          result.add(Map<String, dynamic>.from(v));
        });
      }
    }

    result.sort((a, b) {
      final aDate = DateTime.tryParse(a['voucher_date'] ?? '') ?? DateTime(1970);
      final bDate = DateTime.tryParse(b['voucher_date'] ?? '') ?? DateTime(1970);
      return aDate.compareTo(bDate);
    });

    setState(() {
      vouchers = result;
      isFetching = false; // 👈 إخفاء الشريط
    });
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String formatNumber(dynamic number) {
    String str = number.toString().split(".")[0];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write(',');
    }
    return buffer.toString().split('').reversed.join();
  }

  Widget buildCreditCard() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.teal.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.account_balance_wallet, color: Colors.teal),
                  SizedBox(width: 8),
                  Text('الدين الحالي:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Text('${formatNumber(totalCredit)} د.ع',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.date_range, color: Colors.teal),
                  SizedBox(width: 8),
                  Text('آخر تسديد:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Text(lastPayInDate.isNotEmpty ? lastPayInDate : '—',
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDateFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📆 كشف حساب في تاريخ:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  controller: fromDateController,
                  decoration: InputDecoration(
                    labelText: 'من',
                    prefixIcon: const Icon(Icons.date_range),
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedFromDate,
                      firstDate: DateTime(2022),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        selectedFromDate = date;
                        fromDateController.text = formatDate(date);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  readOnly: true,
                  controller: toDateController,
                  decoration: InputDecoration(
                    labelText: 'إلى',
                    prefixIcon: const Icon(Icons.date_range),
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedToDate,
                      firstDate: DateTime(2022),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        selectedToDate = date;
                        toDateController.text = formatDate(date);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              if (accSerial != null) {
                await _loadVoucherData(accSerial!,
                    from: selectedFromDate, to: selectedToDate);
              }
            },
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text("استعراض كشف الحساب",
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> showVoucherModal(Map<String, dynamic> item) async {
    final invoices =
        (item['invoices'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد تفاصيل لهذه الفاتورة')),
      );
      return;
    }

    final totalQty = invoices.fold<int>(0, (sum, inv) {
      final qty = (inv['qty']*inv['uom_rate'] ) /inv['packing'] ?? 0;
      return sum + (qty is int ? qty : (qty is double ? qty.toInt() : 0));
    });

    final totalValue = item['acc_value'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item['credit_debit'] == 1
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Text(
                    item['credit_debit'] == 1
                        ? "🧾 فاتورة مبيعات"
                        : "↩️ فاتورة إرجاع",
                    style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text("📅 ${item['voucher_date']}"),
                  Text("📦 الكمية: $totalQty"),
                  Text("💰 المبلغ: ${formatNumber(totalValue)} د.ع"),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 8,
                  columns: const [
                    DataColumn(label: Text("الموديل")),
                    DataColumn(label: Text("الكمية")),
                    DataColumn(label: Text("السعر")),
                    DataColumn(label: Text("الإجمالي")),
                  ],
                  rows: invoices.map((inv) {
                    final qty =  (inv['qty']*inv['uom_rate'] ) /inv['packing']  ?? 0;
                    final price = inv['product_sales_price'] ?? 0;
                    final total = qty * price;
                    final artNo = inv['Carton_code'] ?? "";

                    return DataRow(cells: [
                      DataCell(
                        InkWell(
                          onTap: () {
                            final imageUrl =
                                "http://51.195.6.59/ToobacoNew/images/$artNo.JPG";
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text("❌ تعذر تحميل الصورة"),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            inv['product_english_name'] ?? "—",
                            style: const TextStyle(
                                color: Colors.teal,
                                decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                      DataCell(Text("$qty")),
                      DataCell(Text(formatNumber(price))),
                      DataCell(Text(formatNumber(total))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إغلاق"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildVoucherList(List<Map<String, dynamic>> vouchers) {
    return Column(
      children: [
        if (isFetching)
          Container(
            color: Colors.yellow.shade100,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: const [
                LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  color: Colors.teal,
                ),
                SizedBox(height: 8),
                Text(
                  "⚠️ لا تخرج من الصفحة، انتظر تحميل الفواتير...",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final item = vouchers[index];
              return GestureDetector(
                onTap: () => showVoucherModal(item),
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['vot_type_aname'] ?? 'فاتورة',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item['credit_debit'] == 1
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['credit_debit'] == 1 ? item['vot_type_aname'] : item['vot_type_aname'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: item['credit_debit'] == 1
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text("📅 التاريخ: ${item['voucher_date']}"),
                        Text(
                            "💵 القيمة: ${formatNumber(item['acc_value'] ?? 0)} د.ع"),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildShimmerCard(double height) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal,
          centerTitle: true,
          title: const Text('كشف الحساب', style: TextStyle(color: Colors.white)),
        ),
        body: isLoading
            ? Column(
          children: [
            buildShimmerCard(100),
            buildShimmerCard(50),
            Expanded(child: buildShimmerCard(80)),
          ],
        )
            : accSerial == null
            ? const Center(child: Text('لا توجد بيانات بالحساب'))
            : Column(
          children: [
            buildCreditCard(),
            buildDateFilterSection(),
            Expanded(
              child: vouchers.isEmpty
                  ? const Center(
                  child: Text('لا توجد حركات في الفترة المختارة'))
                  : buildVoucherList(vouchers),
            ),
          ],
        ),
      ),
    );
  }
}
