import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'work_entry_model.dart';

class WorkEntryForm extends StatefulWidget {
  final String customerId; // Firestore için müşteri id'si
  final void Function(WorkEntry)? onAdd;
  const WorkEntryForm({super.key, required this.customerId, this.onAdd});

  @override
  State<WorkEntryForm> createState() => _WorkEntryFormState();
}

class _WorkEntryFormState extends State<WorkEntryForm> {
  final _formKey = GlobalKey<FormState>();
  WorkEntryType _selectedType = WorkEntryType.hourly;
  DateTime? _selectedDate;

  // Saatlik için
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<WorkBreak> _breaks = [];
  final _hourlyRateController = TextEditingController();
  final _distanceController = TextEditingController();
  final _distanceRateController = TextEditingController();

  // Ortak
  final _locationController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _descController = TextEditingController();

  double? _calculatedTotal;

  void _calculate() {
    if (_selectedType == WorkEntryType.hourly) {
      double hourRate = double.tryParse(_hourlyRateController.text) ?? 0;
      double km = double.tryParse(_distanceController.text) ?? 0;
      double kmRate = double.tryParse(_distanceRateController.text) ?? 0;

      final start = _startTime != null
          ? _startTime!.hour * 60 + _startTime!.minute
          : 0;
      final end = _endTime != null ? _endTime!.hour * 60 + _endTime!.minute : 0;
      int diff = (end >= start) ? end - start : (24 * 60 - start) + end;
      int totalBreak = _breaks.fold(0, (sum, b) => sum + b.breakMinutes);
      double netHours = (diff - totalBreak) / 60.0;
      if (netHours < 0) netHours = 0;

      setState(() {
        _calculatedTotal = netHours * hourRate + (km * kmRate);
      });
    } else {
      double qty = double.tryParse(_amountController.text) ?? 0;
      double price = double.tryParse(_unitPriceController.text) ?? 0;
      setState(() {
        _calculatedTotal = qty * price;
      });
    }
  }

  void _addBreak() {
    setState(() {
      _breaks.add(
        WorkBreak(
          start: const TimeOfDay(hour: 12, minute: 0),
          end: const TimeOfDay(hour: 13, minute: 0),
        ),
      );
    });
  }

  void _removeBreak(int index) {
    setState(() {
      _breaks.removeAt(index);
    });
  }

  void _clearFields() {
    _locationController.clear();
    _amountController.clear();
    _unitPriceController.clear();
    _descController.clear();
    _hourlyRateController.clear();
    _distanceController.clear();
    _distanceRateController.clear();
    setState(() {
      _selectedDate = null;
      _startTime = null;
      _endTime = null;
      _breaks = [];
      _calculatedTotal = null;
    });
  }

  String _timeOfDayFormat(TimeOfDay? t) => t == null
      ? ""
      : "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  Future<void> _saveEntryToFirestore(WorkEntry entry) async {
    final ref = FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customerId)
        .collection('hourly_work_entries');
    await ref.add(entry.toJson());
  }

  Widget _hourlyTable() {
    // Firestore'dan gelen işçilikleri göster
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.customerId)
          .collection('hourly_work_entries')
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
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
              "Henüz saatlik işçilik eklenmedi.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        final entries = docs
            .map((d) => WorkEntry.fromJson(d.data() as Map<String, dynamic>))
            .toList();

        double totalHour = 0,
            totalNoBreak = 0,
            totalWorkCost = 0,
            totalTravelCost = 0,
            total = 0;
        int totalKm = 0;

        for (final e in entries) {
          totalHour += e.netHours ?? 0;
          totalNoBreak +=
              (e.netHours ?? 0) +
              ((e.breaks?.fold(0, (sum, b) => sum + b.breakMinutes) ?? 0) /
                  60.0);
          totalWorkCost += e.workCost ?? 0;
          totalTravelCost += e.travelCost ?? 0;
          total += e.totalCost ?? 0;
          totalKm += e.distance?.toInt() ?? 0;
        }

        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              columns: const [
                DataColumn(label: Text("Tarih")),
                DataColumn(label: Text("Çalışma Zamanı\nBaşla")),
                DataColumn(label: Text("\nBitir")),
                DataColumn(label: Text("\nToplam")),
                DataColumn(label: Text("Mola\nBaşla")),
                DataColumn(label: Text("Mola\nBitir")),
                DataColumn(label: Text("Molasız\nSaat")),
                DataColumn(label: Text("Saatlik\nÜcret")),
                DataColumn(label: Text("Maliyet")),
                DataColumn(label: Text("Görev Yeri")),
                DataColumn(label: Text("Tek yön\n(km)")),
                DataColumn(label: Text("Km başı\nücret")),
                DataColumn(label: Text("Yol\nMaliyet")),
                DataColumn(
                  label: Text(
                    "Toplam",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: [
                ...entries.map((e) {
                  final firstBreak = (e.breaks?.isNotEmpty ?? false)
                      ? e.breaks!.first
                      : null;
                  final breakMinutes =
                      (e.breaks?.fold(0, (sum, b) => sum + b.breakMinutes) ??
                          0);
                  return DataRow(
                    cells: [
                      DataCell(Text("${e.date.day}/${e.date.month}")),
                      DataCell(Text(_timeOfDayFormat(e.startTime))),
                      DataCell(Text(_timeOfDayFormat(e.endTime))),
                      DataCell(Text((e.netHours ?? 0).toStringAsFixed(0))),
                      DataCell(Text(_timeOfDayFormat(firstBreak?.start))),
                      DataCell(Text(_timeOfDayFormat(firstBreak?.end))),
                      DataCell(Text("-${(breakMinutes / 60).toStringAsFixed(0)}s")),
                      DataCell(Text(e.hourlyRate?.toStringAsFixed(2) ?? "")),
                      DataCell(Text(e.workCost?.toStringAsFixed(2) ?? "")),
                      DataCell(Text(e.workLocation ?? "")),
                      DataCell(Text(e.distance?.toStringAsFixed(0) ?? "")),
                      DataCell(Text(e.distanceRate?.toStringAsFixed(2) ?? "")),
                      DataCell(Text(e.travelCost?.toStringAsFixed(2) ?? "")),
                      DataCell(
                        Text(
                          e.totalCost?.toStringAsFixed(2) ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }),
                DataRow(
                  cells: [
                    const DataCell(Text("")),
                    const DataCell(Text("")),
                    const DataCell(Text("")),
                    DataCell(Text(totalHour.toStringAsFixed(0))),
                    const DataCell(Text("")),
                    const DataCell(Text("")),
                    DataCell(Text("-${totalNoBreak.toStringAsFixed(0)}s")),
                    const DataCell(Text("")),
                    DataCell(Text(totalWorkCost.toStringAsFixed(2))),
                    const DataCell(Text("")),
                    DataCell(Text(totalKm.toString())),
                    const DataCell(Text("")),
                    DataCell(Text(totalTravelCost.toStringAsFixed(2))),
                    DataCell(
                      Text(
                        total.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
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
    return Column(
      children: [
        Form(
          key: _formKey,
          onChanged: _calculate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<WorkEntryType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: "İşçilik Tipi"),
                items: [
                  DropdownMenuItem(
                    value: WorkEntryType.hourly,
                    child: Text("Saatlik (Gelişmiş)"),
                  ),
                  DropdownMenuItem(
                    value: WorkEntryType.road,
                    child: Text("Yol (km)"),
                  ),
                  DropdownMenuItem(
                    value: WorkEntryType.accommodation,
                    child: Text("Konaklama (gün)"),
                  ),
                  DropdownMenuItem(
                    value: WorkEntryType.meter,
                    child: Text("Metre/Metrekare"),
                  ),
                  DropdownMenuItem(
                    value: WorkEntryType.lumpSum,
                    child: Text("Götürü/Adet"),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedType = val!;
                    _clearFields();
                  });
                },
              ),
              const SizedBox(height: 8),
              // Tarih
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? "Tarih seçilmedi"
                          : "Tarih: ${_selectedDate!.toString().split(' ')[0]}",
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: const Text("Tarih Seç"),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null)
                        setState(() => _selectedDate = picked);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_selectedType == WorkEntryType.hourly)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlangıç & Bitiş Saat
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _startTime == null
                                ? "Başlangıç: -"
                                : "Başlangıç: ${_startTime!.format(context)}",
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime:
                                  _startTime ??
                                  const TimeOfDay(hour: 8, minute: 0),
                            );
                            if (picked != null)
                              setState(() => _startTime = picked);
                          },
                          child: const Text("Saat Seç"),
                        ),
                        Expanded(
                          child: Text(
                            _endTime == null
                                ? "Bitiş: -"
                                : "Bitiş: ${_endTime!.format(context)}",
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime:
                                  _endTime ??
                                  const TimeOfDay(hour: 17, minute: 0),
                            );
                            if (picked != null)
                              setState(() => _endTime = picked);
                          },
                          child: const Text("Saat Seç"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Mola aralıkları
                    Row(
                      children: [
                        const Text("Mola Aralıkları"),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addBreak,
                          tooltip: "Mola Ekle",
                        ),
                      ],
                    ),
                    ..._breaks.asMap().entries.map(
                      (entry) => Row(
                        children: [
                          TextButton(
                            child: Text(
                              "Baş: ${entry.value.start.format(context)}",
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: entry.value.start,
                              );
                              if (picked != null) {
                                setState(() {
                                  _breaks[entry.key] = WorkBreak(
                                    start: picked,
                                    end: entry.value.end,
                                  );
                                });
                              }
                            },
                          ),
                          const Text("-"),
                          TextButton(
                            child: Text(
                              "Bit: ${entry.value.end.format(context)}",
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: entry.value.end,
                              );
                              if (picked != null) {
                                setState(() {
                                  _breaks[entry.key] = WorkBreak(
                                    start: entry.value.start,
                                    end: picked,
                                  );
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () => _removeBreak(entry.key),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Saatlik ücret
                    TextFormField(
                      controller: _hourlyRateController,
                      decoration: const InputDecoration(
                        labelText: "Saatlik Ücret",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    // Görev yeri
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: "Görev Yeri",
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? "Çalışma yeri gerekli"
                          : null,
                    ),
                    const SizedBox(height: 8),
                    // Tek yön km
                    TextFormField(
                      controller: _distanceController,
                      decoration: const InputDecoration(
                        labelText: "Tek yön km",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    // Km başına ücret
                    TextFormField(
                      controller: _distanceRateController,
                      decoration: const InputDecoration(
                        labelText: "Km başına ücret",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    // Açıklama
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: "Açıklama"),
                    ),
                  ],
                ),

              if (_selectedType != WorkEntryType.hourly)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedType == WorkEntryType.meter ||
                        _selectedType == WorkEntryType.lumpSum)
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: "Çalışma Yeri",
                        ),
                        validator: (v) =>
                            (_selectedType == WorkEntryType.meter ||
                                    _selectedType == WorkEntryType.lumpSum) &&
                                (v == null || v.isEmpty)
                            ? "Çalışma yeri gerekli"
                            : null,
                      ),
                    // Miktar (saat/km/gün/metre/...)
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: _selectedType == WorkEntryType.road
                            ? "Toplam Km"
                            : _selectedType == WorkEntryType.accommodation
                            ? "Toplam Gün"
                            : _selectedType == WorkEntryType.meter
                            ? "Miktar"
                            : _selectedType == WorkEntryType.lumpSum
                            ? "Adet"
                            : "Miktar",
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Değer gerekli" : null,
                    ),
                    // Açıklama (sadece götürü)
                    if (_selectedType == WorkEntryType.lumpSum)
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: "Açıklama",
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Birim fiyat
                    TextFormField(
                      controller: _unitPriceController,
                      decoration: const InputDecoration(
                        labelText: "Birim Fiyat",
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Birim fiyat gerekli" : null,
                    ),
                  ],
                ),

              const SizedBox(height: 8),
              // Tutar ve hesaplamalar
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedType == WorkEntryType.hourly
                          ? "Toplam: ${_calculatedTotal?.toStringAsFixed(2) ?? '-'}"
                          : "Tutar: ${_calculatedTotal != null ? "${_calculatedTotal!.toStringAsFixed(2)} ₺" : "-"}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Ekle
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Satır Ekle"),
                  onPressed: () async {
                    if (_formKey.currentState!.validate() &&
                        _selectedDate != null) {
                      final entry = WorkEntry(
                        id: const Uuid().v4(),
                        type: _selectedType,
                        date: _selectedDate!,
                        startTime: _selectedType == WorkEntryType.hourly
                            ? _startTime
                            : null,
                        endTime: _selectedType == WorkEntryType.hourly
                            ? _endTime
                            : null,
                        breaks: _selectedType == WorkEntryType.hourly
                            ? List.from(_breaks)
                            : null,
                        hourlyRate: _selectedType == WorkEntryType.hourly
                            ? double.tryParse(_hourlyRateController.text)
                            : null,
                        workLocation: _locationController.text,
                        amount: _selectedType != WorkEntryType.hourly
                            ? double.tryParse(_amountController.text)
                            : null,
                        unitPrice: _selectedType != WorkEntryType.hourly
                            ? double.tryParse(_unitPriceController.text)
                            : null,
                        totalCost: _calculatedTotal,
                        description: _descController.text,
                        distance: _selectedType == WorkEntryType.hourly
                            ? double.tryParse(_distanceController.text)
                            : null,
                        distanceRate: _selectedType == WorkEntryType.hourly
                            ? double.tryParse(_distanceRateController.text)
                            : null,
                      );
                      if (widget.onAdd != null) widget.onAdd!(entry);
                      await _saveEntryToFirestore(entry);
                      _clearFields();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Lütfen tüm alanları doldurun"),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        // TABLO BURADA!
        _selectedType == WorkEntryType.hourly
            ? _hourlyTable()
            : const SizedBox(),
      ],
    );
  }
}