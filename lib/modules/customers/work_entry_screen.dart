import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_model.dart';
import 'work_entry_form.dart';
import 'other_work_entry_form.dart';
import 'work_entry_model.dart';
import 'other_work_entry_model.dart';

class WorkEntryScreen extends StatefulWidget {
  final Customer customer;

  const WorkEntryScreen({super.key, required this.customer});

  @override
  State<WorkEntryScreen> createState() => _WorkEntryScreenState();
}

class _WorkEntryScreenState extends State<WorkEntryScreen> {
  int _selectedTab = 0;

  // Saatlik işçilik Firestore'a ekleme fonksiyonu
  Future<void> _addHourlyEntry(WorkEntry entry) async {
    final ref = FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customer.id)
        .collection('hourly_work_entries');
    await ref.add(entry.toJson());
  }

  // Tablo kalemi işçilik Firestore'a ekleme fonksiyonu
  Future<void> _addOtherEntry(OtherWorkEntry entry) async {
    final ref = FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customer.id)
        .collection('other_work_entries');
    await ref.add(entry.toJson());
  }

  // Saatlik işçilikleri stream ile çek (docId ile birlikte)
  Stream<List<WorkEntry>> _hourlyEntriesStream() {
    if (widget.customer.id.isEmpty) {
      // id boşsa boş bir stream döndür.
      return const Stream<List<WorkEntry>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customer.id)
        .collection('hourly_work_entries')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => WorkEntry.fromJson(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  // Tablo kalemi işçilikleri stream ile çek (docId ile birlikte)
  Stream<List<OtherWorkEntry>> _otherEntriesStream() {
    if (widget.customer.id.isEmpty) {
      return const Stream<List<OtherWorkEntry>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customer.id)
        .collection('other_work_entries')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OtherWorkEntry.fromJson(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  // Saatlik işçiliği Firestore'dan sil
  Future<void> _deleteHourlyEntry(String docId) async {
    await FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customer.id)
        .collection('hourly_work_entries')
        .doc(docId)
        .delete();
  }

  // Tablo kalemini Firestore'dan sil
  Future<void> _deleteOtherEntry(String docId) async {
    await FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customer.id)
        .collection('other_work_entries')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.customer.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("İşçilik Kalemleri")),
        body: const Center(
          child: Text(
            "Geçersiz müşteri! Lütfen önce müşteri oluşturun.",
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("İşçilik Kalemleri - ${widget.customer.name}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ToggleButtons(
              isSelected: [_selectedTab == 0, _selectedTab == 1],
              onPressed: (idx) => setState(() => _selectedTab = idx),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Saatlik (Gelişmiş)"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Tablo Kalemi"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedTab == 0)
              WorkEntryForm(
                customerId: widget.customer.id,
                onAdd: (entry) async {
                  await _addHourlyEntry(entry);
                },
              ),
            if (_selectedTab == 1)
              OtherWorkEntryForm(
                customerId: widget.customer.id,
                onAdd: (entry) async {
                  await _addOtherEntry(entry);
                },
              ),
            const Divider(height: 24),
            if (_selectedTab == 0)
              StreamBuilder<List<WorkEntry>>(
                stream: _hourlyEntriesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final entries = snapshot.data!;
                  if (entries.isEmpty) {
                    return const Text("Henüz saatlik işçilik eklenmedi.");
                  }
                  return Column(
                    children: entries.map((e) {
                      return Card(
                        child: ListTile(
                          title: Text(
                            e.description ?? 'İşçilik Kalemi',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Tarih: ${e.date.toString().split(' ')[0]}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              if (e.docId != null) {
                                await _deleteHourlyEntry(e.docId!);
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            if (_selectedTab == 1)
              StreamBuilder<List<OtherWorkEntry>>(
                stream: _otherEntriesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final entries = snapshot.data!;
                  if (entries.isEmpty) {
                    return const Text("Henüz tablo kalemi eklenmedi.");
                  }
                  return Column(
                    children: entries.map((e) {
                      return Card(
                        child: ListTile(
                          title: Text(
                            e.description ?? 'Tablo Kalemi',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Tarih: ${e.date.toString().split(' ')[0]}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              if (e.docId != null) {
                                await _deleteOtherEntry(e.docId!);
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
