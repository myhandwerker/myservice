/// Özet raporların sunulduğu sayfa.
library;

import 'package:flutter/material.dart';

class SummaryReportPage extends StatelessWidget {
  const SummaryReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Özet Rapor')),
      body: const Center(child: Text('Burada özet rapor gösterilecek')),
    );
  }
}
