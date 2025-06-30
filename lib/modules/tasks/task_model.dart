import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { todo, inProgress, done }

class MaterialItem {
  final String name;
  final int quantity;

  MaterialItem({required this.name, required this.quantity});

  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    return MaterialItem(
      name: map['name'] as String? ?? '',
      quantity: map['quantity'] is int
          ? map['quantity'] as int
          : int.tryParse(map['quantity']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'quantity': quantity};
}

class LaborItem {
  final String description;
  final double duration;
  final String? worker;

  LaborItem({required this.description, required this.duration, this.worker});

  factory LaborItem.fromMap(Map<String, dynamic> map) {
    return LaborItem(
      description: map['description'] as String? ?? '',
      duration: map['duration'] is num
          ? (map['duration'] as num).toDouble()
          : double.tryParse(map['duration']?.toString() ?? '') ?? 0.0,
      worker: map['worker'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'description': description,
    'duration': duration,
    'worker': worker,
  };
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final TaskStatus status;
  final String? customerId;
  final List<MaterialItem> materials;
  final List<LaborItem> labors;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.status = TaskStatus.todo,
    this.customerId,
    this.materials = const [],
    this.labors = const [],
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TaskStatus? status,
    String? customerId,
    List<MaterialItem>? materials,
    List<LaborItem>? labors,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      materials: materials ?? this.materials,
      labors: labors ?? this.labors,
    );
  }

  factory Task.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return Task(
      id: documentId ?? map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      date: map['date'] != null
          ? (map['date'] is String
                ? DateTime.tryParse(map['date']) ?? DateTime.now()
                : (map['date'] is DateTime
                      ? map['date'] as DateTime
                      : (map['date'] is Timestamp
                            ? (map['date'] as Timestamp).toDate()
                            : DateTime.now())))
          : DateTime.now(),
      status: map['status'] is int
          ? TaskStatus.values[map['status']]
          : (map['status'] is String
                ? TaskStatus.values.firstWhere(
                    (s) => s.toString() == map['status'],
                    orElse: () => TaskStatus.todo,
                  )
                : TaskStatus.todo),
      customerId: map['customerId'] as String?,
      materials: (map['materials'] as List<dynamic>? ?? [])
          .map((item) => MaterialItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      labors: (map['labors'] as List<dynamic>? ?? [])
          .map((item) => LaborItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'status': status.index,
    'customerId': customerId,
    'materials': materials.map((e) => e.toMap()).toList(),
    'labors': labors.map((e) => e.toMap()).toList(),
  };
}
