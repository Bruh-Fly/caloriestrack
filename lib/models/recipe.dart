class Recipe {
  const Recipe(
      {required this.id,
      required this.name,
      required this.thumbnail,
      required this.area,
      required this.category,
      required this.instructions,
      required this.ingredients,
      this.source,
      this.youtube,
      this.tags = const []});
  final String id, name, thumbnail, area, category, instructions;
  final List<(String, String)> ingredients;
  final String? source, youtube;
  final List<String> tags;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredients = <(String, String)>[];
    for (var i = 1; i <= 20; i++) {
      final name = (json['strIngredient$i'] as String? ?? '').trim();
      final measure = (json['strMeasure$i'] as String? ?? '').trim();
      if (name.isNotEmpty) ingredients.add((name, measure));
    }
    final tags = (json['strTags'] as String? ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return Recipe(
      id: json['idMeal'] as String? ?? '',
      name: json['strMeal'] as String? ?? '',
      thumbnail: json['strMealThumb'] as String? ?? '',
      area: json['strArea'] as String? ?? '',
      category: json['strCategory'] as String? ?? '',
      instructions: json['strInstructions'] as String? ?? '',
      ingredients: ingredients,
      source: json['strSource'] as String?,
      youtube: json['strYoutube'] as String?,
      tags: tags,
    );
  }
}
