/// Mobil ve web entegrasyon servisleri için sayfa.
library;

import 'package:flutter/material.dart';

class IntegrationService extends StatelessWidget {
  const IntegrationService({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entegrasyon')),
      body: const Center(child: Text('Burada entegrasyon servisi olacak')),
    );
  }
}
