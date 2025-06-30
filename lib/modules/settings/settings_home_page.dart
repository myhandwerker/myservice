// settings_home_page.dart
import 'package:flutter/material.dart';
import 'company_settings_model.dart' as model;
import 'user_settings.dart';
import 'admin_settings.dart';
import 'company_settings_page.dart';

class SettingsHomePage extends StatelessWidget {
  final model.CompanySettings companySettings;
  final void Function(model.CompanySettings) onCompanySettingsChanged;

  const SettingsHomePage({
    super.key,
    required this.companySettings,
    required this.onCompanySettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text("Şirket Ayarları"),
            subtitle: Text(companySettings.companyName),
            onTap: () async {
              final result = await Navigator.push<model.CompanySettings>(
                context,
                MaterialPageRoute(
                  builder: (_) => CompanySettingsPage(
                    settings: companySettings,
                    onChanged: (updated) {
                      Navigator.pop(context, updated);
                    },
                  ),
                ),
              );
              if (result != null) {
                onCompanySettingsChanged(result);
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Kullanıcı Ayarları"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSettingsPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text("Admin Ayarları"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
