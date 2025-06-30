// lib/modules/proposals/ai_teklif_goster.dart
// Düzeltmeler: AppTextStyles.body -> AppTextStyles.bodyMedium kullanıldı.

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'gemini_service.dart';

class AiTeklifGoster extends StatefulWidget {
  const AiTeklifGoster({super.key});

  @override
  State<AiTeklifGoster> createState() => _AiTeklifGosterState();
}

class _AiTeklifGosterState extends State<AiTeklifGoster> {
  final TextEditingController _controller = TextEditingController();
  String _customer = "";
  String _request = "";
  String _description = "";
  bool _loading = false;

  Future<void> _getTeklif() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir müşteri mesajı girin!')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await GeminiService.analyzeMessageAndGenerateProposal(
        message: _controller.text,
      );
      setState(() {
        _customer = result["customer"] ?? '';
        _request = result["request"] ?? '';
        _description = result["description"] ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("AI ile Teklif Oluşturma Başarısız: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "AI ile Teklif Oluştur",
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.yellowAccent,
          ),
        ),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.yellowAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Müşteri mesajı girin',
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ), // bodyMedium kullanıldı
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ), // bodyMedium kullanıldı
              minLines: 2,
              maxLines: 5,
            ),
            const SizedBox(height: AppConstants.padding),
            ElevatedButton(
              onPressed: _loading ? null : _getTeklif,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: AppColors.white)
                  : Text(
                      "AI ile Teklif Alanlarını Doldur",
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.white,
                      ),
                    ), // AppColors.white kullanıldı
            ),
            const Divider(
              color: AppColors.divider,
              height: AppConstants.padding * 2,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_customer.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.padding / 2,
                        ),
                        child: Text(
                          "Müşteri: $_customer",
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.yellowAccent,
                          ),
                        ),
                      ),
                    if (_request.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.padding / 2,
                        ),
                        child: Text(
                          "Talep: $_request",
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.yellowAccent,
                          ),
                        ),
                      ),
                    if (_description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppConstants.padding / 2,
                        ),
                        child: Text(
                          "Açıklama:\n$_description",
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
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
