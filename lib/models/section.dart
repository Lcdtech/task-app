import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Section {
  final String id;
  final String name;
  final Color color;
  final bool isFixed;
  final List<Map<String, dynamic>> tasks;

  Section({
    required this.id,
    required this.name,
    required this.color,
    this.isFixed = false,
    this.tasks = const [],
  });

 factory Section.fromMap(Map<dynamic, dynamic> map) {

  return Section(
    id: map['id'] ?? const Uuid().v4(),
    name: map['name'] ?? '',
    color: Color(map['color'] ?? Colors.grey.value),
    isFixed: map['isFixed'] ?? false,
    tasks: (map['tasks'] as List?)?.map((task) {
      return Map<String, dynamic>.from(task as Map);
    }).toList() ?? [],
  );
}


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'isFixed': isFixed,
      'tasks': tasks,
    };
  }
}
