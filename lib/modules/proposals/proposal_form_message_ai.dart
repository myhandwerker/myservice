// lib/modules/proposals/proposal_form_message_ai.dart
import 'package:flutter/material.dart';
import 'dart:convert'; // <<<<< Bu satırı ekledik
import '../../utils/constants.dart';
import '../proposals/gemini_service.dart';
import '../../models/proposal.dart';

class ProposalFromMessagePage extends StatefulWidget {
  const ProposalFromMessagePage({super.key});

  @override
  State<ProposalFromMessagePage> createState() =>
      _ProposalFromMessagePageState();
}

class _ProposalFromMessagePageState extends State<ProposalFromMessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _requestController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  // 👇 Yeni eklendi: AI'dan gelen ham JSON yanıtını göstermek için
  final TextEditingController _rawAiResponseController =
      TextEditingController();

  bool _loadingAI = false;

  @override
  void dispose() {
    _messageController.dispose();
    _titleController.dispose();
    _customerNameController.dispose();
    _amountController.dispose();
    _requestController.dispose();
    _descriptionController.dispose();
    // 👇 Yeni eklendi: Controller'ı temizle
    _rawAiResponseController.dispose();
    super.dispose();
  }

  Future<void> _generateProposalFields() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir müşteri mesajı girin!')),
      );
      return;
    }

    setState(() {
      _loadingAI = true;
      _rawAiResponseController.clear(); // Yeni bir istekte eski yanıtı temizle
    });
    try {
      // GeminiService'den gelen ham yanıtı almak için GeminiService içinde küçük bir değişiklik yapabiliriz
      // veya burada yanıtın hem parsed hem de raw halini yakalayabiliriz.
      // Şimdilik GeminiService'in doğrudan parse edilmiş Map'i döndürdüğünü varsayarak devam edelim
      // ve ham yanıtı burada tekrar yapılandıralım veya GeminiService'i güncelleyelim.
      // En basit yol için, GeminiService'den gelen yanıtın orijinal halini burada yakalayalım:
      final rawResult = await GeminiService.analyzeMessageAndGenerateProposal(
        message: _messageController.text,
      );

      setState(() {
        _customerNameController.text = rawResult["customer"] ?? '';
        _requestController.text = rawResult["request"] ?? '';
        _descriptionController.text = rawResult["description"] ?? '';
        _titleController.text = "Yeni Teklif - ${_customerNameController.text}";
        _amountController.text = "0.00";
        // 👇 Yeni eklendi: Ham yanıtı bir string olarak burada gösterelim
        // result Map'inden yeniden JSON string'i oluşturarak basitçe gösterebiliriz.
        _rawAiResponseController.text = jsonEncode(rawResult);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("AI Alanları Doldurma Başarısız: $e"),
          backgroundColor: AppColors.error,
        ),
      );
      // 👇 Yeni eklendi: Hata durumunda da hatayı ham yanıt alanında gösterebiliriz
      _rawAiResponseController.text = "Hata oluştu: $e";
    } finally {
      setState(() => _loadingAI = false);
    }
  }

  void _saveProposal() {
    if (_titleController.text.trim().isEmpty ||
        _customerNameController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty ||
        _requestController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm zorunlu alanları doldurun.')),
      );
      return;
    }

    final newProposal = Proposal(
      title: _titleController.text.trim(),
      customerName: _customerNameController.text.trim(),
      amount:
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
      request: _requestController.text.trim(),
      description: _descriptionController.text.trim(),
      date: DateTime.now(),
      status: ProposalStatus.pending,
    );

    Navigator.pop(context, newProposal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mesajdan Teklif Oluştur',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.yellowAccent,
          ),
        ),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.yellowAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppColors.yellowAccent),
            onPressed: _saveProposal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Müşteri mesajını buraya yapıştırın:',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.padding / 2),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText:
                    'Örn: "Merhaba, elektrik tesisatı için teklif alabilir miyiz?"',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
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
              ),
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: AppConstants.padding),
            ElevatedButton(
              onPressed: _loadingAI ? null : _generateProposalFields,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellowAccent,
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
              child: _loadingAI
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : Text(
                      'AI ile Alanları Doldur',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
            ),
            // 👇 Yeni eklendi: Ham AI yanıtını gösterecek alan
            const SizedBox(height: AppConstants.padding),
            Text(
              'AI Ham Yanıtı (JSON):',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.padding / 2),
            TextField(
              controller: _rawAiResponseController,
              readOnly: true, // Sadece okunabilir
              minLines: 3,
              maxLines: 8,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'AI yanıtı burada görünecek...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),

            // 👆 Yeni eklenen kısım burada bitiyor
            const Divider(
              color: AppColors.divider,
              height: AppConstants.padding * 2,
            ),
            Text(
              'Teklif Detayları:',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.yellowAccent,
              ),
            ),
            const SizedBox(height: AppConstants.padding),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Teklif Başlığı*',
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.padding),
            TextFormField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: 'Müşteri Adı*',
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.padding),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Tutar (₺)*',
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppConstants.padding),
            TextFormField(
              controller: _requestController,
              decoration: InputDecoration(
                labelText: 'Müşteri İsteği Özeti*',
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: AppConstants.padding),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Teklif Açıklaması*',
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              minLines: 5,
              maxLines: 10,
            ),
            const SizedBox(height: AppConstants.padding * 2),
            Center(
              child: ElevatedButton(
                onPressed: _saveProposal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                ),
                child: Text(
                  'Teklifi Kaydet',
                  style: AppTextStyles.button.copyWith(color: AppColors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
