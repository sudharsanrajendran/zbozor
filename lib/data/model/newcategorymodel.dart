class NewCategoryResponseModel {
  final bool error;
  final String message;
  final List<NewCategory> data;
  final int code;

  NewCategoryResponseModel({
    required this.error,
    required this.message,
    required this.data,
    required this.code,
  });

  factory NewCategoryResponseModel.fromJson(Map<String, dynamic> json) {
    return NewCategoryResponseModel(
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => NewCategory.fromJson(e))
              .toList() ??
          [],
      code: json['code'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
      'code': code,
    };
  }
}

class NewCategory {
  final int id;
  final int sequence;
  final String name;
  final String image;
  final int? parentCategoryId;
  final String? description;
  final int status;
  final String createdAt;
  final String updatedAt;
  final String slug;
  final int subcategoriesCount;
  final String translatedName;
  final List<NewTranslation> translations;
  final List<NewCategory>? subcategories;

  NewCategory({
    required this.id,
    required this.sequence,
    required this.name,
    required this.image,
    this.parentCategoryId,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.slug,
    required this.subcategoriesCount,
    required this.translatedName,
    required this.translations,
    this.subcategories,
  });

  factory NewCategory.fromJson(Map<String, dynamic> json) {
    return NewCategory(
      id: json['id'] ?? 0,
      sequence: json['sequence'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      parentCategoryId: json['parent_category_id'],
      description: json['description'],
      status: json['status'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      slug: json['slug'] ?? '',
      subcategoriesCount: json['subcategories_count'] ?? 0,
      translatedName: json['translated_name'] ?? '',
      translations: (json['translations'] as List<dynamic>?)
              ?.map((e) => NewTranslation.fromJson(e))
              .toList() ??
          [],
      subcategories: (json['subcategories'] as List<dynamic>?)
              ?.map((e) => NewCategory.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sequence': sequence,
      'name': name,
      'image': image,
      'parent_category_id': parentCategoryId,
      'description': description,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'slug': slug,
      'subcategories_count': subcategoriesCount,
      'translated_name': translatedName,
      'translations': translations.map((e) => e.toJson()).toList(),
      'subcategories': subcategories?.map((e) => e.toJson()).toList(),
    };
  }
}

class NewTranslation {
  final int id;
  final int categoryId;
  final int languageId;
  final String name;
  final String createdAt;
  final String updatedAt;

  NewTranslation({
    required this.id,
    required this.categoryId,
    required this.languageId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NewTranslation.fromJson(Map<String, dynamic> json) {
    return NewTranslation(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      languageId: json['language_id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'language_id': languageId,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
