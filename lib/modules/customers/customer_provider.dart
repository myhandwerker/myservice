// lib/modules/customers/customer_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'customer_model.dart';

class CustomerProvider with ChangeNotifier {
  final FirebaseFirestore _db;
  List<Customer> _customers = [];
  StreamSubscription? _customerSubscription;
  bool _isLoading = false; // Yükleme durumunu izlemek için

  CustomerProvider(this._db) {
    _startListeningToCustomers();
  }

  // isLoading getter'ı
  bool get isLoading => _isLoading;

  void _startListeningToCustomers() {
    _customerSubscription?.cancel();
    _isLoading = true; // Yükleme başladığında true yap
    notifyListeners(); // UI'a yükleme başladığını bildir

    _customerSubscription = _db
        .collection('customers')
        .snapshots()
        .listen(
          (snapshot) {
            _customers = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              data['materials'] = data['materials'] ?? [];
              data['workHours'] = data['workHours'] ?? [];
              return Customer.fromMap(data);
            }).toList();
            _isLoading = false; // Yükleme bittiğinde false yap
            notifyListeners(); // UI'a verilerin güncellendiğini ve yüklemenin bittiğini bildir
          },
          onError: (error) {
            print("Müşteriler dinlenirken hata oluştu: $error");
            _isLoading = false; // Hata durumunda da yüklemeyi bitir
            notifyListeners(); // Hata durumunu ve yüklemenin bittiğini bildir
          },
        );
  }

  @override
  void dispose() {
    _customerSubscription?.cancel();
    super.dispose();
  }

  List<Customer> get customers => _customers;

  Future<void> addCustomer(Customer customer) async {
    final docRef = await _db
        .collection('customers')
        .add(customer.toFirestore());
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db
        .collection('customers')
        .doc(customer.id)
        .set(customer.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteCustomer(String customerId) async {
    await _db.collection('customers').doc(customerId).delete();
  }

  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((customer) => customer.id == id);
    } catch (e) {
      return null;
    }
  }
}
