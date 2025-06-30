// lib/modules/proposals/ai_proposal_suggestion.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart'; // AppColors ve AppTextStyles için
import '../proposals/gemini_service.dart'; // GeminiService import edildi

class AiProposalSuggestion extends StatefulWidget {
  const AiProposalSuggestion({super.key});

  @override
  State<AiProposalSuggestion> createState() => _AiProposalSuggestionState();
}

class _AiProposalSuggestionState extends State<AiProposalSuggestion> {
  final _controller = TextEditingController();
  String _customer = '';
  String _request = '';
  String _description = '';
  bool _loading = false;

  Future<void> _getProposal() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir müşteri mesajı girin!')),
      );
      return;
    }
    setState(() {
      _loading = true;
      _customer = '';
      _request = '';
      _description = '';
    });
    try {
      final res = await GeminiService.analyzeMessageAndGenerateProposal(
        message: _controller.text,
      );
      setState(() {
        _customer = res["customer"] ?? '';
        _request = res["request"] ?? '';
        _description = res["description"] ?? '';
      });
    } catch (e) {
      setState(() {
        _description = 'Hata: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI ile Teklif Oluşturma Başarısız: $e'),
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
          'AI Teklif Önerisi',
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
            Text(
              'Müşteri mesajını girin ve AI teklif önerisi alın:',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.padding),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Müşteri mesajı...',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: AppConstants.padding),
            ElevatedButton(
              onPressed: _loading ? null : _getProposal,
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
                      'AI ile Teklif Oluştur',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.white,
                      ),
                    ),
            ),
            const SizedBox(height: AppConstants.padding * 1.5),
            if (_customer.isNotEmpty ||
                _request.isNotEmpty ||
                _description.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.padding),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                    ),
                    child: SelectableText(
                      'Müşteri: $_customer\n\nTalep: $_request\n\nAçıklama:\n$_description',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
