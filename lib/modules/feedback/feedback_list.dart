/// Müşteri geri bildirimlerinin listelendiği sayfa.
library;

import 'package:flutter/material.dart';

class FeedbackList extends StatelessWidget {
  const FeedbackList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geri Bildirimler')),
      body: const Center(
        child: Text('Burada müşteri geri bildirimleri listelenecek'),
      ),
    );
  }
}
