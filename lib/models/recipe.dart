import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.createdAt,
  });

  final String id;
  final String title;
  final List<String> ingredients;
  final String steps;
  final DateTime createdAt;

  factory Recipe.fromJson(String id, Map<String, dynamic> json) => Recipe(
        id: id,
        title: json['title'] as String,
        ingredients: List<String>.from(json['ingredients'] as List),
        steps: json['steps'] as String,
        createdAt: (json['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'ingredients': ingredients,
        'steps': steps,
        'createdAt': createdAt,
      };
}
