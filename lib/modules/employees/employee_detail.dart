/// Seçili çalışanın detaylarının gösterildiği sayfa.
library;

import 'package:flutter/material.dart';

class EmployeeDetail extends StatelessWidget {
  const EmployeeDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Çalışan Detayı')),
      body: const Center(child: Text('Burada çalışan detayı gösterilecek')),
    );
  }
}
