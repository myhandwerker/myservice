import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  String _adminUsername = "admin";
  String _adminPassword = "";
  String _role = "Yönetici";

  final TextEditingController _secureController = TextEditingController();
  bool _showDangerZone = false;
  String? _secureError;

  static const String _securePin =
      "1234"; // Gerçekte güvenli storage/backend kullanılmalı!

  @override
  void dispose() {
    _secureController.dispose();
    super.dispose();
  }

  void _checkPin() {
    setState(() {
      if (_secureController.text == _securePin) {
        _showDangerZone = true;
        _secureError = null;
      } else {
        _secureError = "Şifre yanlış!";
        _showDangerZone = false;
      }
    });
  }

  Future<void> _confirmBulkDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tüm Müşterileri Sil"),
        content: const Text(
          "Bu işlem geri alınamaz. Tüm müşteriler silinecek. Emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // TODO: Burada toplu müşteri silme işlemini başlat (ör: provider'dan çağır)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tüm müşteriler silindi! (örnek)")),
      );
    }
  }

  // --- CSV EXPORT FONKSİYONU ---
  Future<void> _exportCustomersToCSV() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .get();
      final customers = snapshot.docs;

      if (customers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hiç müşteri bulunamadı!")),
        );
        return;
      }

      List<List<dynamic>> csvData = [
        ["ID", "Ad", "Adres", "Telefon", "Email"],
      ];

      for (var doc in customers) {
        final data = doc.data();
        csvData.add([
          doc.id,
          data['name'] ?? '',
          data['address'] ?? '',
          data['phone'] ?? '',
          data['email'] ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);

      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/musteriler.csv";
      final file = File(filePath);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(filePath)], text: 'Müşteri listesi (CSV)');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "CSV dosyası kaydedildi ve paylaşım ekranı açıldı!\nKonum: $filePath",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("CSV dışa aktarma hatası: $e")));
    }
  }

  // --- CSV IMPORT FONKSİYONU ---
  Future<void> _importCustomersFromCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return; // Kullanıcı dosya seçmeden çıktı

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        content,
      );

      if (csvTable.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("CSV dosyası boş veya hatalı!")),
        );
        return;
      }

      // İlk satır başlık, diğerleri müşteri!
      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.length < 5) continue; // Satır eksikse atla

        final customerData = {
          'name': row[1].toString(),
          'address': row[2].toString(),
          'phone': row[3].toString(),
          'email': row[4].toString(),
        };

        // Eğer ID sütunu varsa güncelle, yoksa yeni ekle
        final customerId = row[0].toString();
        if (customerId.isNotEmpty && customerId != "ID") {
          await FirebaseFirestore.instance
              .collection('customers')
              .doc(customerId)
              .set(customerData, SetOptions(merge: true));
        } else {
          await FirebaseFirestore.instance
              .collection('customers')
              .add(customerData);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("CSV'den müşteri verileri başarıyla içe aktarıldı!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("CSV içe aktarma hatası: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Ayarları")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Yönetici Formu ...
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Admin Bilgileri",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _adminUsername,
                    decoration: const InputDecoration(
                      labelText: "Kullanıcı Adı",
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? "Kullanıcı adı giriniz"
                        : null,
                    onSaved: (value) =>
                        _adminUsername = value ?? _adminUsername,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Yeni Parola"),
                    obscureText: true,
                    onSaved: (value) => _adminPassword = value ?? "",
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _role,
                    decoration: const InputDecoration(
                      labelText: "Yetki Seviyesi",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Yönetici",
                        child: Text("Yönetici"),
                      ),
                      DropdownMenuItem(
                        value: "Süper Admin",
                        child: Text("Süper Admin"),
                      ),
                      DropdownMenuItem(
                        value: "Okuyucu",
                        child: Text("Okuyucu"),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _role = value ?? "Yönetici"),
                    onSaved: (value) => _role = value ?? _role,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: const Text("Kaydet"),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _formKey.currentState?.save();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Admin ayarları kaydedildi (örnek)!",
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 48),
            const Text(
              "Tehlikeli İşlemler",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            if (!_showDangerZone)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _secureController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Yönetici Şifresi ile doğrula",
                        errorText: _secureError,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _checkPin,
                    child: const Text("Doğrula"),
                  ),
                ],
              ),
            if (_showDangerZone)
              Card(
                color: Colors.red.shade50,
                margin: const EdgeInsets.only(top: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Toplu Müşteri Silme",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete_forever),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => _confirmBulkDelete(context),
                        label: const Text(
                          "Tüm Müşterileri Sil (GERİ ALINAMAZ)",
                        ),
                      ),
                      const Divider(height: 32),
                      const Text(
                        "Müşteri Listesini Dışa Aktar (CSV)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: _exportCustomersToCSV,
                        label: const Text("CSV Olarak İndir & Paylaş"),
                      ),
                      const Divider(height: 32),
                      const Text(
                        "Müşteri Listesini İçe Aktar (CSV)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: _importCustomersFromCSV,
                        label: const Text("CSV Dosyasından İçe Aktar"),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
