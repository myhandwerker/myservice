// lib/modules/customers/customer_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'customer_material_model.dart';

class Customer {
  final String id;
  String name;
  String address;
  String phone;
  String email;
  String? customerNumber;
  String? notes;
  List<CustomerMaterial> materials;
  List<Map<String, dynamic>> workHours;

  Customer({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.customerNumber,
    this.notes,
    this.materials = const [],
    this.workHours = const [],
  });

  factory Customer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? {};
    return Customer(
      id: snapshot.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      customerNumber: data['customerNumber'] as String?,
      notes: data['notes'] as String?,
      materials: (data['materials'] as List<dynamic>?)
              ?.map(
                (item) => CustomerMaterial.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          [],
      workHours: _parseWorkHours(data['workHours']),
    );
  }

  factory Customer.fromJson(Map<String, dynamic> data) {
    return Customer(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      customerNumber: data['customerNumber'] as String?,
      notes: data['notes'] as String?,
      materials: (data['materials'] as List<dynamic>?)
              ?.map(
                (item) => CustomerMaterial.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          [],
      workHours: _parseWorkHours(data['workHours']),
    );
  }

  factory Customer.fromMap(Map<String, dynamic> data) =>
      Customer.fromJson(data);

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "address": address,
      "phone": phone,
      "email": email,
      "customerNumber": customerNumber,
      "notes": notes,
      "materials": materials.map((m) => m.toJson()).toList(),
      "workHours": workHours,
    };
  }

  static List<Map<String, dynamic>> _parseWorkHours(dynamic list) {
    if (list is! List) return [];
    return list.map<Map<String, dynamic>>((item) {
      final map = Map<String, dynamic>.from(item as Map);
      if (!map.containsKey('type')) {
        if (map.containsKey('unit')) {
          map['type'] = 'OtherWorkEntry';
        } else {
          map['type'] = 'WorkEntryType.hourly';
        }
      }
      return map;
    }).toList();
  }

  factory Customer.empty() {
    return Customer(
      id: const Uuid().v4(),
      name: '',
      address: '',
      phone: '',
      email: '',
      customerNumber: '',
      notes: '',
      materials: const [],
      workHours: const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
