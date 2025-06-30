import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'other_work_entry_model.dart';

class OtherWorkEntryForm extends StatefulWidget {
  final String customerId; // <-- Firebase için müşteri id parametresi
  final void Function(OtherWorkEntry)? onAdd;
  const OtherWorkEntryForm({super.key, required this.customerId, this.onAdd});

  @override
  State<OtherWorkEntryForm> createState() => _OtherWorkEntryFormState();
}

class _OtherWorkEntryFormState extends State<OtherWorkEntryForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _date;
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  OtherWorkEntryUnit _unit = OtherWorkEntryUnit.goturu;
  final _unitPriceController = TextEditingController();
  final _locationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _distanceRateController = TextEditingController();
  final _accommodationNightsController = TextEditingController();
  final _accommodationPriceController = TextEditingController();

  // Eklenecek satırların listesi (tablo için)
  final List<OtherWorkEntry> _addedOtherWorkEntries = [];

  double get _workCost =>
      (double.tryParse(_amountController.text) ?? 0) *
      (double.tryParse(_unitPriceController.text) ?? 0);

  double get _travelCost =>
      (double.tryParse(_distanceController.text) ?? 0) *
      (double.tryParse(_distanceRateController.text) ?? 0);

  double get _accommodationCost =>
      (int.tryParse(_accommodationNightsController.text) ?? 0) *
      (double.tryParse(_accommodationPriceController.text) ?? 0);

  double get _totalCost => _workCost + _travelCost + _accommodationCost;

  String _unitToStr(OtherWorkEntryUnit unit) {
    switch (unit) {
      case OtherWorkEntryUnit.goturu:
        return "Götürü";
      case OtherWorkEntryUnit.metre:
        return "Metre";
      case OtherWorkEntryUnit.metrekare:
        return "Metrekare";
    }
  }

  Future<void> _saveEntryToFirestore(OtherWorkEntry entry) async {
    final ref = FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customerId)
        .collection('other_work_entries');
    await ref.add(entry.toJson());
  }

  Widget _otherWorkTable() {
    // Firestore'dan çekilen veriyi göster
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.customerId)
          .collection('other_work_entries')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "Henüz tablo kalemi eklenmedi.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        final entries = docs
            .map(
              (d) => OtherWorkEntry.fromJson(d.data() as Map<String, dynamic>),
            )
            .toList();
        return Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Tarih")),
                DataColumn(label: Text("Açıklama")),
                DataColumn(label: Text("Miktar")),
                DataColumn(label: Text("Birim")),
                DataColumn(label: Text("Birim Fiyat")),
                DataColumn(label: Text("İşçilik Tutarı")),
                DataColumn(label: Text("Görev Yeri")),
                DataColumn(label: Text("Yol (km)")),
                DataColumn(label: Text("Yol Ücreti")),
                DataColumn(label: Text("Konaklama")),
                DataColumn(label: Text("Toplam")),
                DataColumn(label: Text("Sil")),
              ],
              rows: [
                ...entries.map(
                  (e) => DataRow(
                    cells: [
                      DataCell(Text(e.date.toString().split(' ')[0])),
                      DataCell(Text(e.description ?? "-")),
                      DataCell(Text(e.amount?.toString() ?? "-")),
                      DataCell(Text(_unitToStr(e.unit))),
                      DataCell(Text(e.unitPrice?.toStringAsFixed(2) ?? "-")),
                      DataCell(Text(e.workCost?.toStringAsFixed(2) ?? "-")),
                      DataCell(Text(e.workLocation ?? "-")),
                      DataCell(Text(e.distance?.toString() ?? "-")),
                      DataCell(Text(e.travelCost?.toStringAsFixed(2) ?? "-")),
                      DataCell(
                        Text(
                          "${e.accommodationNights?.toString() ?? "-"} x ${e.accommodationPrice?.toStringAsFixed(2) ?? "-"} = ${e.accommodationCost?.toStringAsFixed(2) ?? "-"}",
                        ),
                      ),
                      DataCell(Text(e.totalCost?.toStringAsFixed(2) ?? "-")),
                      DataCell(
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () async {
                            // Firestore'dan sil
                            await FirebaseFirestore.instance
                                .collection('customers')
                                .doc(widget.customerId)
                                .collection('other_work_entries')
                                .doc(e.id)
                                .delete();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onChanged: () => setState(() {}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... Diğer form alanları aynı ...
          // Tarih seç
          Row(
            children: [
              Expanded(
                child: Text(
                  _date == null
                      ? "Tarih seçilmedi"
                      : "Tarih: ${_date!.toString().split(' ')[0]}",
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.date_range),
                label: const Text("Tarih Seç"),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
            ],
          ),
          // Açıklama
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(labelText: "Açıklama"),
            validator: (v) =>
                v == null || v.isEmpty ? "Açıklama gerekli" : null,
          ),
          // Miktar + birim seçimi
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: "Miktar"),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Miktar gerekli" : null,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<OtherWorkEntryUnit>(
                value: _unit,
                onChanged: (val) => setState(() => _unit = val!),
                items: [
                  DropdownMenuItem(
                    value: OtherWorkEntryUnit.goturu,
                    child: Text("Götürü"),
                  ),
                  DropdownMenuItem(
                    value: OtherWorkEntryUnit.metre,
                    child: Text("Metre"),
                  ),
                  DropdownMenuItem(
                    value: OtherWorkEntryUnit.metrekare,
                    child: Text("Metrekare"),
                  ),
                ],
              ),
            ],
          ),
          // Birim fiyat
          TextFormField(
            controller: _unitPriceController,
            decoration: const InputDecoration(labelText: "Birim Fiyat (€)"),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.isEmpty ? "Fiyat gerekli" : null,
          ),
          // İşçilik maliyeti
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Maliyet: € ${_workCost.toStringAsFixed(2)}"),
          ),
          // Görev yeri
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: "Görev Yeri"),
            validator: (v) =>
                v == null || v.isEmpty ? "Görev yeri gerekli" : null,
          ),
          // Yol
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _distanceController,
                  decoration: const InputDecoration(labelText: "Tek yön km"),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _distanceRateController,
                  decoration: const InputDecoration(
                    labelText: "Km başına ücret (€)",
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Yol Maliyeti: € ${_travelCost.toStringAsFixed(2)}"),
          ),
          // Konaklama
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _accommodationNightsController,
                  decoration: const InputDecoration(
                    labelText: "Konaklama (gece)",
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _accommodationPriceController,
                  decoration: const InputDecoration(
                    labelText: "Gece Fiyatı (€)",
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Konaklama Maliyeti: € ${_accommodationCost.toStringAsFixed(2)}",
            ),
          ),
          // Toplam maliyet
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Toplam: € ${_totalCost.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Satır Ekle"),
              onPressed: () async {
                if (_formKey.currentState!.validate() && _date != null) {
                  final entry = OtherWorkEntry(
                    id: const Uuid().v4(),
                    date: _date!,
                    description: _descController.text,
                    amount: double.tryParse(_amountController.text) ?? 0,
                    unit: _unit,
                    unitPrice: double.tryParse(_unitPriceController.text) ?? 0,
                    workCost: _workCost,
                    workLocation: _locationController.text,
                    distance: double.tryParse(_distanceController.text) ?? 0,
                    distanceRate:
                        double.tryParse(_distanceRateController.text) ?? 0,
                    travelCost: _travelCost,
                    accommodationNights:
                        int.tryParse(_accommodationNightsController.text) ?? 0,
                    accommodationPrice:
                        double.tryParse(_accommodationPriceController.text) ??
                        0,
                    accommodationCost: _accommodationCost,
                    totalCost: _totalCost,
                  );
                  setState(() {
                    _addedOtherWorkEntries.add(entry);
                  });
                  if (widget.onAdd != null) widget.onAdd!(entry);
                  // Firestore'a kaydet
                  await _saveEntryToFirestore(entry);
                  // Formu temizle
                  setState(() {
                    _date = null;
                    _descController.clear();
                    _amountController.clear();
                    _unit = OtherWorkEntryUnit.goturu;
                    _unitPriceController.clear();
                    _locationController.clear();
                    _distanceController.clear();
                    _distanceRateController.clear();
                    _accommodationNightsController.clear();
                    _accommodationPriceController.clear();
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Tüm alanları doldurun")),
                  );
                }
              },
            ),
          ),
          // Alta tabloyu ekle!
          _otherWorkTable(),
        ],
      ),
    );
  }
}
