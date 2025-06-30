/// Offline çalışma desteği için servis sayfası.
library;

import 'package:flutter/material.dart';

class OfflineService extends StatelessWidget {
  const OfflineService({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline')),
      body: const Center(child: Text('Burada offline servis işlemleri olacak')),
    );
  }
}
