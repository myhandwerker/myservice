  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:file_picker/file_picker.dart';
  import 'package:syncfusion_flutter_pdf/pdf.dart' as sf; // DOĞRU!
  import 'package:pdf/pdf.dart' as pw;
  import 'package:pdf/widgets.dart' as pw_widgets;
  import 'dart:io';
  import 'customer_material_model.dart';
  import 'customer_material_ocr_utils.dart';
  import '../../utils/constants.dart';
  import 'package:path_provider/path_provider.dart';
  import 'package:open_filex/open_filex.dart';
  import 'package:printing/printing.dart';
  import 'dart:typed_data';

  class CustomerMaterialForm extends StatefulWidget {
    final String customerId;
    final VoidCallback? onMaterialAdded;

    const CustomerMaterialForm({
      super.key,
      required this.customerId,
      this.onMaterialAdded,
    });

    @override
    State<CustomerMaterialForm> createState() => _CustomerMaterialFormState();
  }

  class _CustomerMaterialFormState extends State<CustomerMaterialForm> {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _quantityController = TextEditingController();
    final _unitController = TextEditingController();
    final _priceController = TextEditingController();
    final _noteController = TextEditingController();

    bool _loading = false;
    bool _loadingPdf = false;

    List<CustomerMaterial> _ocrMaterials = [];

    @override
    void dispose() {
      _nameController.dispose();
      _quantityController.dispose();
      _unitController.dispose();
      _priceController.dispose();
      _noteController.dispose();
      super.dispose();
    }

    Future<void> _submit() async {
      if (_formKey.currentState!.validate()) {
        setState(() => _loading = true);

        final material = CustomerMaterial(
          name: _nameController.text.trim(),
          quantity: double.tryParse(_quantityController.text) ?? 0,
          unit: _unitController.text.trim(),
          price: _priceController.text.isEmpty
              ? null
              : double.tryParse(_priceController.text),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

        try {
          final docRef = FirebaseFirestore.instance
              .collection('customers')
              .doc(widget.customerId);

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(docRef);
            final data = snapshot.data();
            final List<dynamic> materials =
                (data?['materials'] as List<dynamic>? ?? []);
            materials.add(material.toJson());
            transaction.update(docRef, {'materials': materials});
          });

          if (mounted && widget.onMaterialAdded != null) {
            widget.onMaterialAdded!();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Malzeme eklendi: ${material.name}')),
            );
          }
          _formKey.currentState!.reset();
          _nameController.clear();
          _quantityController.clear();
          _unitController.clear();
          _priceController.clear();
          _noteController.clear();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Malzeme eklenemedi: $e")));
          }
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      }
    }

    Future<void> _deleteMaterial(int index, List<CustomerMaterial> mats) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Malzeme Sil'),
          content: const Text('Bu malzemeyi silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Sil'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      try {
        final docRef = FirebaseFirestore.instance
            .collection('customers')
            .doc(widget.customerId);
        final newList = List<CustomerMaterial>.from(mats)..removeAt(index);
        await docRef.update({
          'materials': newList.map((e) => e.toJson()).toList(),
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Malzeme silindi")));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Silme hatası: $e")));
      }
    }

    Future<void> _editMaterial(
      int index,
      CustomerMaterial mat,
      List<CustomerMaterial> mats,
    ) async {
      final nameCtrl = TextEditingController(text: mat.name);
      final quantityCtrl = TextEditingController(text: mat.quantity.toString());
      final unitCtrl = TextEditingController(text: mat.unit);
      final priceCtrl = TextEditingController(text: mat.price?.toString() ?? "");
      final noteCtrl = TextEditingController(text: mat.note ?? "");
      final formKey = GlobalKey<FormState>();

      final result = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Malzeme Düzenle'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Malzeme Adı"),
                  validator: (v) => v == null || v.isEmpty ? "Zorunlu" : null,
                ),
                TextFormField(
                  controller: quantityCtrl,
                  decoration: const InputDecoration(labelText: "Miktar"),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Zorunlu";
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return "Geçerli miktar girin";
                    return null;
                  },
                ),
                TextFormField(
                  controller: unitCtrl,
                  decoration: const InputDecoration(labelText: "Birim"),
                  validator: (v) => v == null || v.isEmpty ? "Zorunlu" : null,
                ),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: "Fiyat"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: "Açıklama"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate())
                  Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );

      if (result == true) {
        try {
          final docRef = FirebaseFirestore.instance
              .collection('customers')
              .doc(widget.customerId);
          final updated = CustomerMaterial(
            name: nameCtrl.text.trim(),
            quantity: double.tryParse(quantityCtrl.text) ?? 0,
            unit: unitCtrl.text.trim(),
            price: priceCtrl.text.isEmpty
                ? null
                : double.tryParse(priceCtrl.text),
            note: noteCtrl.text.isEmpty ? null : noteCtrl.text.trim(),
          );
          final newList = List<CustomerMaterial>.from(mats);
          newList[index] = updated;
          await docRef.update({
            'materials': newList.map((e) => e.toJson()).toList(),
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Malzeme güncellendi")));
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Düzenleme hatası: $e")));
        }
      }
    }

    // PDF DIŞA AKTAR (pw ile)
    Future<void> _exportToPdf(List<CustomerMaterial> mats) async {
      final pdf = pw_widgets.Document();

      pdf.addPage(
        pw_widgets.Page(
          pageFormat: pw.PdfPageFormat.a4,
          build: (pw_widgets.Context context) {
            return pw_widgets.Column(
              crossAxisAlignment: pw_widgets.CrossAxisAlignment.start,
              children: [
                pw_widgets.Text(
                  'Malzeme Listesi',
                  style: pw_widgets.TextStyle(
                    fontSize: 22,
                    fontWeight: pw_widgets.FontWeight.bold,
                  ),
                ),
                pw_widgets.SizedBox(height: 18),
                pw_widgets.Table.fromTextArray(
                  border: null,
                  cellStyle: const pw_widgets.TextStyle(fontSize: 11),
                  headerStyle: pw_widgets.TextStyle(
                    fontWeight: pw_widgets.FontWeight.bold,
                    fontSize: 12,
                  ),
                  headers: ['Adı', 'Miktar', 'Birim', 'Fiyat', 'Tutar', 'Not'],
                  data: [
                    for (final m in mats)
                      [
                        m.name,
                        m.quantity.toString(),
                        m.unit,
                        m.price?.toStringAsFixed(2) ?? "-",
                        ((m.price ?? 0) * m.quantity).toStringAsFixed(2),
                        m.note ?? "-",
                      ],
                  ],
                ),
                pw_widgets.SizedBox(height: 10),
                pw_widgets.Align(
                  alignment: pw_widgets.Alignment.centerRight,
                  child: pw_widgets.Text(
                    'Toplam Tutar: ${mats.fold<double>(0, (sum, m) => sum + ((m.price ?? 0) * m.quantity)).toStringAsFixed(2)} ₺',
                    style: pw_widgets.TextStyle(
                      fontWeight: pw_widgets.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/malzeme_listesi.pdf');
      await file.writeAsBytes(bytes, flush: true);

      await OpenFilex.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF başarıyla oluşturuldu ve açıldı!')),
        );
      }
    }

    // YAZDIR (pw ile)
    Future<void> _printMaterials(List<CustomerMaterial> mats) async {
      await Printing.layoutPdf(
        onLayout: (pw.PdfPageFormat format) async {
          final pdf = pw_widgets.Document();

          pdf.addPage(
            pw_widgets.Page(
              pageFormat: format,
              build: (pw_widgets.Context context) {
                return pw_widgets.Column(
                  crossAxisAlignment: pw_widgets.CrossAxisAlignment.start,
                  children: [
                    pw_widgets.Text(
                      'Malzeme Listesi',
                      style: pw_widgets.TextStyle(
                        fontSize: 22,
                        fontWeight: pw_widgets.FontWeight.bold,
                      ),
                    ),
                    pw_widgets.SizedBox(height: 18),
                    pw_widgets.Table.fromTextArray(
                      border: null,
                      cellStyle: const pw_widgets.TextStyle(fontSize: 11),
                      headerStyle: pw_widgets.TextStyle(
                        fontWeight: pw_widgets.FontWeight.bold,
                        fontSize: 12,
                      ),
                      headers: [
                        'Adı',
                        'Miktar',
                        'Birim',
                        'Fiyat',
                        'Tutar',
                        'Not',
                      ],
                      data: [
                        for (final m in mats)
                          [
                            m.name,
                            m.quantity.toString(),
                            m.unit,
                            m.price?.toStringAsFixed(2) ?? "-",
                            ((m.price ?? 0) * m.quantity).toStringAsFixed(2),
                            m.note ?? "-",
                          ],
                      ],
                    ),
                    pw_widgets.SizedBox(height: 10),
                    pw_widgets.Align(
                      alignment: pw_widgets.Alignment.centerRight,
                      child: pw_widgets.Text(
                        'Toplam Tutar: ${mats.fold<double>(0, (sum, m) => sum + ((m.price ?? 0) * m.quantity)).toStringAsFixed(2)} ₺',
                        style: pw_widgets.TextStyle(
                          fontWeight: pw_widgets.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );

          return Uint8List.fromList(await pdf.save());
        },
      );
    }

    // PDF'den malzeme çekme fonksiyonu (syncfusion ile)
    Future<void> _importMaterialsFromPdf() async {
      setState(() {
        _loadingPdf = true;
      });

      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result == null || result.files.single.path == null) {
          setState(() => _loadingPdf = false);
          return;
        }

        final fileBytes = await File(result.files.single.path!).readAsBytes();
        final sf.PdfDocument document = sf.PdfDocument(inputBytes: fileBytes);
        String text = sf.PdfTextExtractor(document).extractText();
        document.dispose();

        List<CustomerMaterial> importedMaterials = [];
        for (var line in text.split('\n')) {
          final parts = line.split(',');
          if (parts.length < 3) continue;

          final name = parts[0].trim();
          final quantity = double.tryParse(parts[1].trim()) ?? 0;
          final unit = parts[2].trim();
          final price = parts.length > 3
              ? double.tryParse(parts[3].trim())
              : null;
          final note = parts.length > 4 ? parts[4].trim() : null;

          if (name.isNotEmpty && quantity > 0) {
            importedMaterials.add(
              CustomerMaterial(
                name: name,
                quantity: quantity,
                unit: unit,
                price: price,
                note: note,
              ),
            );
          }
        }

        if (importedMaterials.isNotEmpty) {
          final docRef = FirebaseFirestore.instance
              .collection('customers')
              .doc(widget.customerId);

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(docRef);
            final data = snapshot.data();
            final List<dynamic> materials =
                (data?['materials'] as List<dynamic>? ?? []);

            for (var mat in importedMaterials) {
              final exists = materials.any(
                (e) =>
                    e['name'] == mat.name &&
                    e['quantity'] == mat.quantity &&
                    e['unit'] == mat.unit &&
                    e['price'] == mat.price &&
                    e['note'] == mat.note,
              );
              if (!exists) {
                materials.add(mat.toJson());
              }
            }
            transaction.update(docRef, {'materials': materials});
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF\'den malzemeler başarıyla eklendi.'),
              ),
            );
          }
          if (widget.onMaterialAdded != null) widget.onMaterialAdded!();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF\'de uygun malzeme bulunamadı.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF\'den malzeme çekilemedi: $e')),
          );
        }
      } finally {
        setState(() {
          _loadingPdf = false;
        });
      }
    }

    // OCR: Fatura/Makbuzdan malzeme ekle
    Future<void> _pickAndProcessInvoice() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OCR işlemi başlatılıyor...')));

      try {
        final ocrText = await recognizeTextFromImage(picked.path);
        print("OCR Çıktısı:\n$ocrText");
        final parsed = parseMaterialsFromText(ocrText);
        if (parsed.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Faturadan malzeme tespit edilemedi!")),
          );
          return;
        }
        setState(() {
          _ocrMaterials = parsed;
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("OCR hatası: $e")));
      }
    }

    Future<void> _addOcrMaterialsToFirestore(List<CustomerMaterial> mats) async {
      final docRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.customerId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final data = snapshot.data();
        final List<dynamic> materials =
            (data?['materials'] as List<dynamic>? ?? []);
        materials.addAll(mats.map((e) => e.toJson()));
        transaction.update(docRef, {'materials': materials});
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OCR malzemeleri eklendi!')));
      if (widget.onMaterialAdded != null) widget.onMaterialAdded!();
    }

    @override
    Widget build(BuildContext context) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        width: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // OCR/Fatura Tara butonu
                Card(
                  color: Colors.orange[100],
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    leading: const Icon(Icons.camera, color: Colors.orange),
                    title: const Text("Fatura/Makbuzdan Malzeme Tara (OCR)"),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.document_scanner),
                      label: const Text("Fatura Tara"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _pickAndProcessInvoice,
                    ),
                    subtitle: const Text(
                      "Fatura veya makbuz fotoğrafı çekerek malzemeleri hızlıca ekleyin.",
                    ),
                  ),
                ),

                // OCR ile taranan ve henüz eklenmemiş malzemeler için ayrı tablo (tema uyumlu)
                if (_ocrMaterials.isNotEmpty) ...[
                  Card(
                    color: Theme.of(context).cardColor,
                    margin: const EdgeInsets.only(bottom: 18),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Taranan Malzemeler (Onaylamadan eklenmez)",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                Theme.of(context).colorScheme.surfaceVariant,
                              ),
                              dataRowColor: MaterialStateProperty.all(
                                Theme.of(context).cardColor,
                              ),
                              headingTextStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                              dataTextStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                              columns: const [
                                DataColumn(label: Text('Adı')),
                                DataColumn(label: Text('Miktar')),
                                DataColumn(label: Text('Birim')),
                                DataColumn(label: Text('Fiyat')),
                                DataColumn(label: Text('Not')),
                                DataColumn(label: Text('İşlem')),
                              ],
                              rows: List.generate(_ocrMaterials.length, (i) {
                                final m = _ocrMaterials[i];
                                return DataRow(
                                  cells: [
                                    DataCell(Text(m.name)),
                                    DataCell(Text(m.quantity.toString())),
                                    DataCell(Text(m.unit)),
                                    DataCell(
                                      Text(m.price?.toStringAsFixed(2) ?? "-"),
                                    ),
                                    DataCell(Text(m.note ?? "-")),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.add,
                                              color: Colors.green,
                                            ),
                                            tooltip: "Tabloya ekle",
                                            onPressed: () async {
                                              await _addOcrMaterialsToFirestore([
                                                m,
                                              ]);
                                              setState(() {
                                                _ocrMaterials.removeAt(i);
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            tooltip: "Tarananlardan sil",
                                            onPressed: () {
                                              setState(() {
                                                _ocrMaterials.removeAt(i);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text("Hepsini Tabloya Ekle"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  await _addOcrMaterialsToFirestore(
                                    List.from(_ocrMaterials),
                                  );
                                  setState(() {
                                    _ocrMaterials.clear();
                                  });
                                },
                              ),
                              const SizedBox(width: 10),
                              TextButton.icon(
                                icon: const Icon(Icons.clear),
                                label: const Text("Hepsini Sil"),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _ocrMaterials.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // PDF'den malzeme çekme butonu
                Card(
                  color: Colors.blue[50],
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                    title: const Text("PDF'den Malzeme Aktar"),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.file_open),
                      label: _loadingPdf
                          ? const Text("Yükleniyor...")
                          : const Text("PDF Aktar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _loadingPdf ? null : _importMaterialsFromPdf,
                    ),
                    subtitle: const Text(
                      "PDF dosyasından malzeme listesini otomatik ekleyin.",
                    ),
                  ),
                ),

                // MANUEL FORM CARD
                Card(
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Malzeme Ekle",
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onBackground,
                                ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Malzeme Adı',
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Zorunlu' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Miktar',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Zorunlu';
                                    final n = double.tryParse(v);
                                    if (n == null || n <= 0)
                                      return 'Geçerli miktar girin';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _unitController,
                                  decoration: const InputDecoration(
                                    labelText: 'Birim (adet, kg, m...)',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.isEmpty) ? 'Zorunlu' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Birim Fiyatı (Opsiyonel)',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _noteController,
                                  decoration: const InputDecoration(
                                    labelText: 'Açıklama (Opsiyonel)',
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text(
                                'Malzeme Ekle',
                                style: TextStyle(fontSize: 16),
                              ),
                              onPressed: _loading ? null : _submit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ASIL DATA TABLE CARD
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('customers')
                      .doc(widget.customerId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final data = snapshot.data!.data();
                    final List materialsJson = data?['materials'] ?? [];
                    final List<CustomerMaterial> mats = materialsJson
                        .map(
                          (e) => CustomerMaterial.fromJson(
                            Map<String, dynamic>.from(e as Map),
                          ),
                        )
                        .toList();

                    if (mats.isEmpty) {
                      return Card(
                        color: Theme.of(context).cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'Henüz malzeme eklenmedi.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ),
                        ),
                      );
                    }

                    final toplamTutar = mats.fold<double>(
                      0,
                      (sum, m) => sum + ((m.price ?? 0) * (m.quantity)),
                    );

                    return Card(
                      color: Theme.of(context).cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: _loadingPdf
                                      ? const Text("Yükleniyor...")
                                      : const Text("PDF'den Malzeme Aktar"),
                                  onPressed: _loadingPdf
                                      ? null
                                      : _importMaterialsFromPdf,
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onError,
                                  ),
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text("PDF Dışa Aktar"),
                                  onPressed: () => _exportToPdf(mats),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                  icon: const Icon(Icons.print),
                                  label: const Text("Yazdır"),
                                  onPressed: () => _printMaterials(mats),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 16,
                                headingRowColor:
                                    MaterialStateProperty.resolveWith(
                                      (states) => Theme.of(
                                        context,
                                      ).colorScheme.surfaceVariant,
                                    ),
                                dataRowColor: MaterialStateProperty.resolveWith(
                                  (states) => Theme.of(context).cardColor,
                                ),
                                headingTextStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                dataTextStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 14,
                                    ),
                                columns: const [
                                  DataColumn(label: Text('Adı')),
                                  DataColumn(label: Text('Miktar')),
                                  DataColumn(label: Text('Birim')),
                                  DataColumn(label: Text('Fiyat')),
                                  DataColumn(label: Text('Tutar')),
                                  DataColumn(label: Text('Not')),
                                  DataColumn(label: Text('İşlem')),
                                ],
                                rows: List.generate(mats.length, (i) {
                                  final m = mats[i];
                                  final tutar = (m.price ?? 0) * m.quantity;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(m.name)),
                                      DataCell(Text(m.quantity.toString())),
                                      DataCell(Text(m.unit)),
                                      DataCell(
                                        Text(m.price?.toStringAsFixed(2) ?? "-"),
                                      ),
                                      DataCell(
                                        Text(
                                          tutar == 0
                                              ? "-"
                                              : tutar.toStringAsFixed(2),
                                        ),
                                      ),
                                      DataCell(Text(m.note ?? "-")),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                              onPressed: () =>
                                                  _editMaterial(i, m, mats),
                                              tooltip: "Düzenle",
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                              ),
                                              onPressed: () =>
                                                  _deleteMaterial(i, mats),
                                              tooltip: "Sil",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0, right: 4),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "Toplam Tutar: ${toplamTutar.toStringAsFixed(2)} ₺",
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontSize: 16,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    }
  }
