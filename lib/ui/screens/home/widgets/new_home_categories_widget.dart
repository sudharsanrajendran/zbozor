import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/data/cubits/category/newcategoriescubit.dart';
import 'package:Ebozor/data/model/category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:Ebozor/ui/screens/widgets/errors/no_data_found.dart';
import 'package:Ebozor/ui/screens/home/widgets/category_home_card.dart';

import 'package:shimmer/shimmer.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/ui/screens/new_property_screen.dart';

class NewHomeCategoriesWidget extends StatelessWidget {
  const NewHomeCategoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewCategoriesCubit, NewCategoriesState>(
      builder: (context, state) {
        if (state is NewCategoriesInProgress) {
          return _shimmerEffect(context);
        }

        if (state is NewCategoriesSuccess) {
          if (state.categories.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(50),
              child: NoDataFound(onTap: null),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final category = state.categories[index];

                return CategoryHomeCard(
                  title: category.name,
                  url: category.image,
                  onTap: () {
                    CategoryModel categoryModel = CategoryModel(
                      id: category.id,
                      name: category.name,
                      url: category.image,
                      subcategoriesCount: 0,
                      children: [],
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              NewPropertyScreen(category: categoryModel)),
                    );
                  },
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _shimmerEffect(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
        highlightColor: Theme.of(context).colorScheme.shimmerHighlightColor,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 8, // Show 8 placeholders
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            return Column(
              children: [
                Container(
                  height: 60, // Approx size of category circle/box
                  width: 60,
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 10,
                  width: 50,
                  color: context.color.secondaryColor,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
