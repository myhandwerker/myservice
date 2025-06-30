import '../customers/customer_model.dart';
import 'task_model.dart';

String getCustomerName(String? customerId, List<Customer> customers) {
  if (customerId == null) return "Bilinmiyor";
  final customer = customers.firstWhere(
    (c) => c.id == customerId,
    orElse: () =>
        Customer(id: '', name: 'Bilinmiyor', address: '', phone: '', email: ''),
  );
  return customer.name;
}

String statusText(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return "Beklemede";
    case TaskStatus.inProgress:
      return "Devam Ediyor";
    case TaskStatus.done:
      return "Yapıldı";
  }
}
