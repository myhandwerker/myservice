/// Çalışanların listelendiği sayfa.
library;

import 'package:flutter/material.dart';

class EmployeeList extends StatelessWidget {
  const EmployeeList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Çalışanlar')),
      body: const Center(child: Text('Burada çalışanlar listelenecek')),
    );
  }
}
