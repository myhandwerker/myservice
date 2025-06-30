import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'customer_model.dart';
import 'customer_provider.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? initialCustomer;

  const CustomerFormScreen({super.key, this.initialCustomer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _customerNumberController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCustomer?.name ?? '',
    );
    _addressController = TextEditingController(
      text: widget.initialCustomer?.address ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialCustomer?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialCustomer?.email ?? '',
    );
    _customerNumberController = TextEditingController(
      text: widget.initialCustomer?.customerNumber ?? '',
    );
    _notesController = TextEditingController(
      text: widget.initialCustomer?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _customerNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomerToFirestore(String customerId) async {
    try {
      final customerDoc = FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId);

      Map<String, dynamic> data = {
        'id': customerId,
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'materials': [],
      };
      if (_customerNumberController.text.trim().isNotEmpty) {
        data['customerNumber'] = _customerNumberController.text.trim();
      }
      if (_notesController.text.trim().isNotEmpty) {
        data['notes'] = _notesController.text.trim();
      }

      await customerDoc.set(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Firestore hata: $e')));
      }
    }
  }

  void _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final customerProvider = Provider.of<CustomerProvider>(
        context,
        listen: false,
      );
      final uuid = Uuid();

      final isNew = widget.initialCustomer == null;
      final customerId = isNew ? uuid.v4() : widget.initialCustomer!.id;

      await _saveCustomerToFirestore(customerId);

      if (isNew) {
        final newCustomer = Customer(
          id: customerId,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          customerNumber: _customerNumberController.text.trim().isEmpty
              ? null
              : _customerNumberController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          materials: const [],
          workHours: const [],
        );
        await customerProvider.addCustomer(newCustomer);
      } else {
        final updatedCustomer = Customer(
          id: customerId,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          customerNumber: _customerNumberController.text.trim().isEmpty
              ? null
              : _customerNumberController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          materials: widget.initialCustomer!.materials,
          workHours: widget.initialCustomer!.workHours,
        );
        await customerProvider.updateCustomer(updatedCustomer);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialCustomer == null
              ? 'Yeni Müşteri Ekle'
              : 'Müşteriyi Düzenle',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Müşteri Adı'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen müşteri adı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adres'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen adres girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefon'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen telefon numarası girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen email adresi girin';
                  }
                  if (!value.contains('@')) {
                    return 'Geçerli bir email adresi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerNumberController,
                decoration: const InputDecoration(
                  labelText: 'Müşteri Numarası (Opsiyonel)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notlar (Opsiyonel)',
                ),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveCustomer,
                child: Text(
                  widget.initialCustomer == null
                      ? 'Müşteri Ekle'
                      : 'Müşteriyi Güncelle',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
