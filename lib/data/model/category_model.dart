// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:Ebozor/utils/ApiService/api.dart';

class Type {
  String? id;
  String? type;

  Type({this.id, this.type});

  Type.fromJson(Map<String, dynamic> json) {
    id = json[Api.id].toString();
    type = json[Api.type];
  }
}

class CategoryModel {
  final int? id;
  final String? name;
  final String? url;
  final List<CategoryModel>? children;
  final String? description;
  final List<CategoryFilterModel>? filters; // Added filters field

  //final String translatedName;
  final int? subcategoriesCount;
  final String? originalName; // [NEW] Stores the English/Original name

  CategoryModel({
    this.id,
    this.name,
    this.url,
    this.description,
    this.children,
    this.subcategoriesCount,
    this.filters, // Added to constructor
    this.originalName, // [NEW] Added to constructor
    //required this.translatedName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    try {
      List<dynamic> childData = json['subcategories'] ?? [];
      List<CategoryModel> children =
          childData.map((child) => CategoryModel.fromJson(child)).toList();

      // Parse filters
      List<dynamic> filtersData = json['filters'] ?? [];
      List<CategoryFilterModel> filters =
          filtersData.map((f) => CategoryFilterModel.fromJson(f)).toList();

      // [NEW] Map custom_fields to filters if filters are empty (or merge them)
      if (json.containsKey('custom_fields')) {
        List<dynamic> customFieldsData = json['custom_fields'] ?? [];
        if (customFieldsData.isNotEmpty) {
          for (var item in customFieldsData) {
            // Structure seems to be: { ..., custom_fields: { id, name, type, values... } }
            if (item is Map<String, dynamic> &&
                item.containsKey('custom_fields')) {
              var fieldData = item['custom_fields'];
              if (fieldData != null) {
                filters.add(CategoryFilterModel.fromJson(fieldData));
              }
            }
          }
        }
      }

      return CategoryModel(
          id: json['id'],
          //name: json['name'],
          name: json['translated_name'],
          url: json['image'],
          subcategoriesCount: json['subcategories_count'] ?? 0,
          children: children,
          filters: filters,
          description: json['description'] ?? "");
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      //'name': name,
      'translated_name': name,
      'image': url,
      'subcategories_count': subcategoriesCount,
      "description": description,
      'subcategories': children!.map((child) => child.toJson()).toList(),
      'filters': filters?.map((filter) => filter.toJson()).toList(),
    };
    return data;
  }

  @override
  String toString() {
    return 'CategoryModel( id: $id, translated_name:$name, url: $url, descrtiption:$description, children: $children,subcategories_count:$subcategoriesCount, filters: $filters)';
  }
}

class CategoryFilterModel {
  final int? id;
  final String? name;
  final String? type; // e.g., "button", "range"
  final List<dynamic>? values; // e.g., [1, 2, 3] or []
  final String? placeholder;

  CategoryFilterModel({
    this.id,
    this.name,
    this.type,
    this.values,
    this.placeholder,
  });

  factory CategoryFilterModel.fromJson(Map<String, dynamic> json) {
    return CategoryFilterModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      values: json['values'] is List ? json['values'] : [],
      placeholder: json['placeholder'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'values': values,
      'placeholder': placeholder,
    };
  }
}
