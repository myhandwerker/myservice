/// İş analitiklerini ve performans verilerini gösteren sayfa.
library;

import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İş Analitikleri')),
      body: const Center(child: Text('Burada iş analitikleri sunulacak')),
    );
  }
}
