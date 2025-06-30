import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiKeySettingsPage extends StatefulWidget {
  const ApiKeySettingsPage({super.key});

  @override
  State<ApiKeySettingsPage> createState() => _ApiKeySettingsPageState();
}

class _ApiKeySettingsPageState extends State<ApiKeySettingsPage> {
  final TextEditingController _controller = TextEditingController();
  String? _savedApiKey;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('gemini_api_key') ?? '';
    setState(() {
      _savedApiKey = key;
      _controller.text = key;
    });
  }

  Future<void> _saveApiKey() async {
    final key = _controller.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    setState(() {
      _savedApiKey = key;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('API anahtarı kaydedildi!')));
  }

  Future<void> _deleteApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gemini_api_key');
    setState(() {
      _savedApiKey = '';
      _controller.text = '';
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('API anahtarı silindi!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini API Anahtarı Ayarları')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Gemini AI Studio API anahtarınızı girin:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'API Anahtarı',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              enableSuggestions: false,
              autocorrect: false,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveApiKey,
                    child: const Text('Kaydet'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_savedApiKey != null && _savedApiKey!.isNotEmpty)
                  IconButton(
                    tooltip: 'Anahtarı Sil',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteApiKey,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (_savedApiKey != null && _savedApiKey!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Kayıtlı bir API anahtarı mevcut.'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
