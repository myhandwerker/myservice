/// Grafik ve veri görselleştirme sayfası.
library;

import 'package:flutter/material.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grafikler')),
      body: const Center(child: Text('Burada grafikler gösterilecek')),
    );
  }
}
