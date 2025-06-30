import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_material_model.dart';

class CustomerMaterialList extends StatelessWidget {
  final String customerId;

  const CustomerMaterialList({super.key, required this.customerId});

  Future<void> _deleteMaterial(
    BuildContext context,
    CustomerMaterial material,
  ) async {
    final docRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final data = snapshot.data();
        final List<dynamic> materials =
            (data?['materials'] as List<dynamic>? ?? []);
        materials.removeWhere(
          (e) =>
              e['name'] == material.name &&
              (e['quantity'] == material.quantity) &&
              (e['unit'] == material.unit) &&
              (e['price'] == material.price) &&
              (e['note'] == material.note),
        );
        transaction.update(docRef, {'materials': materials});
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${material.name} silindi.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Malzeme silinemedi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.data();
        final List materialsJson = data?['materials'] ?? [];
        final List<CustomerMaterial> materials = materialsJson
            .map(
              (e) => CustomerMaterial.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();

        if (materials.isEmpty) {
          return const Center(child: Text('Malzeme eklenmedi.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: materials.length,
          itemBuilder: (context, i) {
            final mat = materials[i];
            return Card(
              child: ListTile(
                title: Text(mat.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${mat.quantity} ${mat.unit}'),
                    if (mat.note != null && mat.note!.isNotEmpty)
                      Text(
                        mat.note!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (mat.price != null)
                      Text('${mat.price?.toStringAsFixed(2)} ₺'),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteMaterial(context, mat),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
