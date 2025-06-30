/// Güvenlik servisleri ve işlemleri için sayfa.
library;

import 'package:flutter/material.dart';

class SecurityService extends StatelessWidget {
  const SecurityService({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Güvenlik')),
      body: const Center(child: Text('Burada güvenlik servisi olacak')),
    );
  }
}
