// lib/modules/proposals/proposal_list.dart
// Düzeltmeler: ProposalForm içindeki _generateAIDescription metodunda
// AI çağrısı artık GeminiService'e yönlendirildi ve doğru parametre kullanıldı.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için
import 'package:uuid/uuid.dart'; // UUID oluşturmak için

import '../../models/proposal.dart'; // Proposal modeli
import '../../utils/constants.dart'; // AppColors ve AppTextStyles için
import 'proposal_form_message_ai.dart'; // AI ile teklif için sayfa
import 'gemini_service.dart'; // GeminiService import edildi

// NOTE: Bu 'generateProposalDescriptionAI' fonksiyonu artık ProposalForm içinde doğrudan kullanılmayacaktır.
// AI mantığı için GeminiService kullanılacak. Bu fonksiyon sadece örnek veya başka yerlerde kullanılıyorsa kalsın.
// Eğer sadece ProposalForm içinde AI kullanılıyorsa, bu mocked fonksiyon tamamen kaldırılabilir.
Future<String> generateProposalDescriptionAI({
  required String customer,
  required String request,
  required double amount,
}) async {
  // Bu bir simülasyon. Gerçek AI servisi (örn. GeminiService) ile değiştirilmelidir.
  await Future.delayed(const Duration(seconds: 1));
  return '''
GİRİŞ:
Sayın $customer, teklif talebiniz için teşekkür ederiz.

GELİŞME:
İsteğiniz: "$request" için teklifimiz: Toplam fiyat: ₺${amount.toStringAsFixed(2)}.
Tüm malzeme ve işçilik dahil, kaliteli ve zamanında teslimat sağlanacaktır.

SONUÇ:
Teklifimiz hakkında detaylı bilgi ve iletişim için her zaman ulaşabilirsiniz.
Saygılarımızla.
''';
}

class ProposalList extends StatefulWidget {
  const ProposalList({super.key});

  @override
  State<ProposalList> createState() => _ProposalListState();
}

class _ProposalListState extends State<ProposalList> {
  final List<Proposal> proposals = [
    Proposal(
      id: const Uuid().v4(),
      title: 'Web Sitesi Tasarımı Teklifi',
      customerName: 'Ali Yılmaz',
      amount: 25000.0,
      status: ProposalStatus.pending,
      date: DateTime(2025, 6, 1),
      description: 'Kurumsal bir web sitesi tasarımı için detaylı teklif.',
      request: 'Kurumsal web sitesi hazırlanacak.',
    ),
    Proposal(
      id: const Uuid().v4(),
      title: 'Mobil Uygulama Geliştirme',
      customerName: 'Ayşe Demir',
      amount: 50000.0,
      status: ProposalStatus.accepted,
      date: DateTime(2025, 5, 20),
      description: 'Android ve iOS için mobil uygulama geliştirme teklifi.',
      request: 'Restoranlar için sipariş uygulaması.',
    ),
  ];

  void _addProposal(Proposal? proposal) {
    if (proposal != null) {
      setState(() {
        proposals.add(proposal);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teklif oluşturuldu: ${proposal.title}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _editProposal(Proposal proposal) async {
    final updatedProposal = await showDialog<Proposal>(
      context: context,
      builder: (context) => ProposalForm(initialProposal: proposal),
    );
    if (updatedProposal != null) {
      setState(() {
        final idx = proposals.indexWhere((p) => p.id == proposal.id);
        if (idx != -1) {
          proposals[idx] = updatedProposal;
        } else {
          proposals.add(updatedProposal); // Çok nadir, ama olabilir
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teklif güncellendi: ${updatedProposal.title}'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  void _removeProposal(Proposal proposal) {
    setState(() {
      proposals.removeWhere((p) => p.id == proposal.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Teklif silindi: ${proposal.title}'),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: 'Geri Al',
          textColor: AppColors.white,
          onPressed: () {
            setState(() {
              proposals.add(proposal); // Geri al
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Teklifler",
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.yellowAccent,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.padding),
            child: Text(
              "Tüm Teklifler",
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: proposals.isEmpty
                ? Center(
                    child: Text(
                      "Henüz teklif yok.",
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: proposals.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.divider),
                    itemBuilder: (context, i) {
                      final p = proposals[i];
                      return Card(
                        color: AppColors.surface,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppConstants.padding,
                          vertical: AppConstants.padding / 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.description,
                            color: p.status
                                .displayColor, // Enum uzantısından renk al
                          ),
                          title: Text(
                            p.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.yellowAccent,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Müşteri: ${p.customerName}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Tutar: ${p.amount.toStringAsFixed(2)} ₺',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Durum: ${p.status.displayName}', // Enum uzantısından metin al
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: p.status.displayColor,
                                ),
                              ),
                              Text(
                                'Tarih: ${DateFormat('dd.MM.yyyy').format(p.date)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppConstants.padding / 4),
                              Text(
                                'İstek: ${p.request}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                p.description,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.info,
                                ),
                                onPressed: () => _editProposal(p),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _removeProposal(p),
                              ),
                            ],
                          ),
                          onTap: () => _editProposal(
                            p,
                          ), // Detay görmek için de düzenleme ekranına git
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: AppColors.yellowAccent,
            foregroundColor: AppColors.primary,
            onPressed: () async {
              final newProposal = await showDialog<Proposal>(
                context: context,
                builder: (context) => const ProposalForm(),
              );
              _addProposal(newProposal);
            },
            heroTag: "normalTeklif",
            child: const Icon(Icons.add),
            tooltip: "Yeni Teklif Ekle",
          ),
          const SizedBox(height: AppConstants.padding / 2),
          FloatingActionButton(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.white,
            onPressed: () async {
              final newProposalFromAi = await Navigator.push<Proposal>(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProposalFromMessagePage(),
                ),
              );
              _addProposal(newProposalFromAi);
            },
            heroTag: "mesajdanTeklif",
            child: const Icon(Icons.auto_fix_high),
            tooltip: "Mesajdan AI ile Teklif Oluştur",
          ),
        ],
      ),
    );
  }
}

// --- ProposalForm (aynı dosya içinde tanımlanmış hali) ---
// Eğer bu form ayrı bir dosyada ise, o dosyayı import edin.
class ProposalForm extends StatefulWidget {
  final Proposal? initialProposal;
  const ProposalForm({super.key, this.initialProposal});

  @override
  State<ProposalForm> createState() => _ProposalFormState();
}

class _ProposalFormState extends State<ProposalForm> {
  final _formKey = GlobalKey<FormState>();
  late String title;
  late String customerName;
  late double amount;
  late ProposalStatus status;
  late DateTime date;
  String description = "";
  String request = "";

  bool loadingAI = false;

  @override
  void initState() {
    super.initState();
    title = widget.initialProposal?.title ?? '';
    customerName = widget.initialProposal?.customerName ?? '';
    amount = widget.initialProposal?.amount ?? 0;
    status = widget.initialProposal?.status ?? ProposalStatus.pending;
    date = widget.initialProposal?.date ?? DateTime.now();
    description = widget.initialProposal?.description ?? '';
    request = widget.initialProposal?.request ?? '';
  }

  Future<void> _generateAIDescription() async {
    if (customerName.isEmpty || request.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "AI açıklaması için önce Müşteri Adı, İstek ve Tutar girin!",
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => loadingAI = true);
    try {
      // Düzeltildi: GeminiService.analyzeMessageAndGenerateProposal metoduna doğru parametre gönderildi.
      final result = await GeminiService.analyzeMessageAndGenerateProposal(
        message:
            'Müşteri: $customerName, İstek: $request, Tutar: ${amount.toStringAsFixed(2)}. Bu bilgilere göre Türkçe, profesyonel bir teklif metni oluştur ve sadece description kısmını döndür.',
      );
      setState(() {
        description = result["description"] ?? "";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("AI açıklaması alınamadı: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }
    setState(() => loadingAI = false);
  }

  @override
  Widget build(BuildContext context) {
    final descController = TextEditingController(text: description);
    descController.selection = TextSelection.fromPosition(
      TextPosition(offset: descController.text.length),
    );

    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(
        widget.initialProposal == null ? "Yeni Teklif" : "Teklif Düzenle",
        style: AppTextStyles.titleLarge.copyWith(color: AppColors.yellowAccent),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: "Başlık*",
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Başlık giriniz" : null,
                onSaved: (value) => title = value ?? '',
                onChanged: (v) => title = v,
              ),
              const SizedBox(height: AppConstants.padding / 2),
              TextFormField(
                initialValue: customerName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: "Müşteri Adı*",
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? "Müşteri adı giriniz"
                    : null,
                onSaved: (value) => customerName = value ?? '',
                onChanged: (v) => customerName = v,
              ),
              const SizedBox(height: AppConstants.padding / 2),
              TextFormField(
                initialValue: amount == 0 ? '' : amount.toStringAsFixed(2),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: "Tutar (₺)*",
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Tutar giriniz";
                  final num? parsed = num.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0)
                    return "Geçerli bir tutar giriniz";
                  return null;
                },
                onSaved: (value) =>
                    amount = double.tryParse(value!.replaceAll(',', '.')) ?? 0,
                onChanged: (v) =>
                    amount = double.tryParse(v.replaceAll(',', '.')) ?? 0,
              ),
              const SizedBox(height: AppConstants.padding / 2),
              TextFormField(
                initialValue: request,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: "Müşteri İsteği*",
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? "Müşteri isteğini yazınız"
                    : null,
                onSaved: (value) => request = value ?? '',
                onChanged: (v) => request = v,
              ),
              const SizedBox(height: AppConstants.padding / 2),
              DropdownButtonFormField<ProposalStatus>(
                value: status,
                dropdownColor: AppColors.surface,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: "Durum",
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                items: ProposalStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(
                      s.displayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) =>
                    setState(() => status = val ?? ProposalStatus.pending),
                onSaved: (value) => status = value ?? ProposalStatus.pending,
              ),
              const SizedBox(height: AppConstants.padding / 2),
              ListTile(
                title: Text(
                  "Tarih: ${DateFormat('dd.MM.yyyy').format(date)}",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: AppColors.yellowAccent,
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.yellowAccent,
                            onPrimary: AppColors.primary,
                            onSurface: AppColors.textPrimary,
                            surface: AppColors.surface,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.yellowAccent,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => date = picked);
                },
              ),
              const SizedBox(height: AppConstants.padding / 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: descController,
                      minLines: 4,
                      maxLines: 8,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: "Açıklama (AI ile doldurulabilir)*",
                        labelStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Açıklama giriniz" : null,
                      onSaved: (v) => description = v ?? "",
                      onChanged: (v) {
                        description = v;
                      },
                    ),
                  ),
                  IconButton(
                    icon: loadingAI
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.yellowAccent,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(
                            Icons.auto_fix_high,
                            color: AppColors.yellowAccent,
                          ),
                    tooltip: "AI ile Açıklama Oluştur",
                    onPressed: loadingAI ? null : _generateAIDescription,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            "İptal",
            style: AppTextStyles.button.copyWith(color: AppColors.yellowAccent),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.yellowAccent,
            foregroundColor: AppColors.primary,
          ),
          child: Text(
            widget.initialProposal == null
                ? "Teklif Oluştur"
                : "Teklifi Güncelle",
            style: AppTextStyles.button.copyWith(color: AppColors.primary),
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              final proposal = Proposal(
                id: widget.initialProposal?.id,
                title: title,
                customerName: customerName,
                amount: amount,
                status: status,
                date: date,
                description: description,
                request: request,
              );
              Navigator.of(context).pop(proposal);
            }
          },
        ),
      ],
    );
  }
}
