import 'package:flutter/material.dart';
import 'package:Ebozor/data/model/category_model.dart';
import 'package:Ebozor/ui/screens/propertyscreen.dart';

class NewPropertyScreen extends StatelessWidget {
  final CategoryModel category;

  const NewPropertyScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return PropertyFilterScreen(
      categoryList: [category],
      catName: category.name ?? "",
      catId: category.id!,
      categoryIds: [category.id.toString()],
    );
  }
}
