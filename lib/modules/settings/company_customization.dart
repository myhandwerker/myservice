import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CompanyCustomizationPage extends StatefulWidget {
  const CompanyCustomizationPage({super.key});

  @override
  State<CompanyCustomizationPage> createState() =>
      _CompanyCustomizationPageState();
}

class _CompanyCustomizationPageState extends State<CompanyCustomizationPage> {
  final _formKey = GlobalKey<FormState>();
  String _companyName = "Demo Şirketi";
  String _companyDescription = "Açıklamanızı buraya yazabilirsiniz.";
  Color _themeColor = Colors.blue;
  File? _logoFile;

  // Varsayılan ayarlar
  void _resetToFactoryDefaults() {
    setState(() {
      _companyName = "Demo Şirketi";
      _companyDescription = "Açıklamanızı buraya yazabilirsiniz.";
      _themeColor = Colors.blue;
      _logoFile = null;
    });
    // Formu da sıfırlamak için
    _formKey.currentState?.reset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ayarlar fabrika ayarlarına döndürüldü!")),
    );
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _logoFile = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Şirket Özelleştirmeleri"),
        actions: [
          IconButton(
            tooltip: "Fabrika Ayarlarına Dön",
            icon: const Icon(Icons.restore),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Fabrika Ayarlarına Dön"),
                  content: const Text(
                    "Tüm şirket ayarlarını sıfırlamak istediğinize emin misiniz?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("İptal"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Evet"),
                    ),
                  ],
                ),
              );
              if (confirmed == true) _resetToFactoryDefaults();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Şirket Bilgileri",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _companyName,
                decoration: const InputDecoration(labelText: "Şirket Adı"),
                validator: (value) => value == null || value.isEmpty
                    ? "Şirket adı giriniz"
                    : null,
                onSaved: (value) => _companyName = value ?? _companyName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _companyDescription,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Şirket Açıklaması / Slogan",
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Açıklama giriniz" : null,
                onSaved: (value) =>
                    _companyDescription = value ?? _companyDescription,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: _logoFile != null
                    ? CircleAvatar(backgroundImage: FileImage(_logoFile!))
                    : const CircleAvatar(child: Icon(Icons.business)),
                title: const Text("Logo Seç"),
                onTap: _pickLogo,
                trailing: _logoFile != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: "Logoyu Kaldır",
                        onPressed: () => setState(() => _logoFile = null),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text("Tema Rengi: "),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      Color? color = await showDialog(
                        context: context,
                        builder: (_) =>
                            _ColorPickerDialog(initialColor: _themeColor),
                      );
                      if (color != null) setState(() => _themeColor = color);
                    },
                    child: CircleAvatar(backgroundColor: _themeColor),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
                  child: const Text("Kaydet"),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _formKey.currentState?.save();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Şirket özelleştirmeleri kaydedildi (örnek)!",
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
      ),
    );
  }
}

/// Basit bir renk seçici dialog
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  Color? _selectedColor;

  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Tema Rengi Seç"),
      content: Wrap(
        spacing: 8,
        children: _colors
            .map(
              (color) => GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: CircleAvatar(
                  backgroundColor: color,
                  child: _selectedColor == color
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text("Tamam"),
        ),
      ],
    );
  }
}
