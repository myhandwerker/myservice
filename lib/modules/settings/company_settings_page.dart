import 'package:flutter/material.dart';
import 'company_settings_model.dart' as model;

class CompanySettingsPage extends StatelessWidget {
  final model.CompanySettings settings;
  final void Function(model.CompanySettings) onChanged;

  const CompanySettingsPage({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Gerçek uygulamada burada ayarları düzenlemek için formlar olur.
    // Şimdilik örnek ve test amaçlı, şirket adını gösterip güncelleyen bir buton koyuyoruz.
    return Scaffold(
      appBar: AppBar(title: const Text("Şirket Ayarları")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Şirket adı: ${settings.companyName}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Örnek güncelleme (Gerçekte form ile yeni ayar alınır)
                final updated = settings.copyWith(
                  companyName: "Yeni Şirket Adı",
                );
                onChanged(updated);
                Navigator.pop(context, updated);
              },
              child: const Text("Şirket adını (örnek) değiştir"),
            ),
          ],
        ),
      ),
    );
  }
}
