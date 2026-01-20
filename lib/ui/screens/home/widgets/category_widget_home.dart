import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/data/cubits/category/fetch_category_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:Ebozor/ui/screens/widgets/errors/no_data_found.dart';
import 'package:Ebozor/ui/screens/home/widgets/category_home_card.dart';

import 'package:shimmer/shimmer.dart';
import 'package:Ebozor/ui/theme/theme.dart';

class CategoryWidgetHome extends StatelessWidget {
  const CategoryWidgetHome({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
      builder: (context, state) {
        if (state is FetchCategoryInProgress) {
          return _shimmerEffect(context);
        }

        if (state is FetchCategorySuccess) {
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
                  title: category.name!,
                  url: category.url!,
                  onTap: () {
                    if (category.children!.isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        Routes.subCategoryScreen,
                        arguments: {
                          "categoryList": category.children,
                          "catName": category.name,
                          "catId": category.id,
                          "categoryIds": [category.id.toString()],
                        },
                      );
                    } else {
                      Navigator.pushNamed(
                        context,
                        Routes.itemsList,
                        arguments: {
                          "catID": category.id.toString(),
                          "catName": category.name,
                          "categoryIds": [category.id.toString()],
                        },
                      );
                    }
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 10,
                  width: 50,
                  color: Colors.white,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
