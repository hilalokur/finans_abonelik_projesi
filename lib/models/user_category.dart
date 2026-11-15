import 'package:flutter/material.dart';

@immutable
class UserCategory {
  const UserCategory({required this.name, required this.color});
  final String name;
  final Color color;
  Map<String, dynamic> toMap() => {'name': name, 'color': color.toARGB32()};
  factory UserCategory.fromMap(Map<String, dynamic> map) => UserCategory(
    name: map['name'] as String,
    color: Color((map['color'] as num).toInt()),
  );
}
