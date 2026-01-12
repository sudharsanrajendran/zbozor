import 'package:Ebozor/data/cubits/category/fetch_sub_categories_cubit.dart';
import 'package:Ebozor/ui/screens/home/widgets/location_widget.dart';
import 'package:Ebozor/data/model/category_model.dart';
import 'package:Ebozor/ui/screens/widgets/amenities_filter_screen.dart';
import 'package:Ebozor/utils/helper_utils.dart';

import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/utils/app_icon.dart';

import 'package:flutter/services.dart'; // For TextInputFormatter

import 'package:Ebozor/data/repositories/item/item_repository.dart';
import 'package:Ebozor/data/repositories/category_repository.dart';
import 'package:Ebozor/data/model/data_output.dart';
import 'package:Ebozor/ui/screens/widgets/shimmerLoadingContainer.dart';

class PropertyFilterScreen extends StatefulWidget {
  final List<CategoryModel> categoryList;
  final String catName;
  final int catId;
  final List<String> categoryIds;

  const PropertyFilterScreen({
    super.key,
    required this.categoryList,
    required this.catName,
    required this.catId,
    required this.categoryIds,
  });

  @override
  State<PropertyFilterScreen> createState() => _PropertyFilterScreenState();
}

class _PropertyFilterScreenState extends State<PropertyFilterScreen> {
  int _selectedTabIndex = 0; // 0 for Rent, 1 for Sale (assuming order)
  CategoryModel? _selectedPropertyType; // e.g. Residential
  final List<CategoryModel> _subCategoryPath =
      []; // Dynamic path: [Apartment, 1 Room, ...]

  // We need a separate cubit to fetch children of the selected property type (e.g. Residential -> Apartments)
  late final FetchSubCategoriesCubit _subCategoryCubit;

  // We need another cubit to fetch Property Types (Residential/Commercial) if the Tab doesn't have them (e.g. Sale)
  late final FetchSubCategoriesCubit _propertyTypesCubit;

  // [NEW] Repository for ad-hoc category fetching
  final CategoryRepository _categoryRepository = CategoryRepository();
  // [NEW] Track loading state for specific category IDs
  final Map<int, bool> _loadingCategories = {};

  // Filter State
  TextEditingController minController = TextEditingController();
  TextEditingController maxController = TextEditingController();
  RangeValues _priceRangeValues =
      const RangeValues(0, 1000000); // 0 to 1M default
  String postedOn = Constant.postedSince[0].value; // Default "All Time"

  // Store dynamic filter values: {"Rooms": 2, "Bathrooms": 1}
  Map<String, dynamic> _selectedFilters = {};

  // 4️⃣ ✅ Filters only ONCE update
  bool filtersInitialized = false;

  @override
  void initState() {
    super.initState();

    _subCategoryCubit = FetchSubCategoriesCubit();
    _propertyTypesCubit = FetchSubCategoriesCubit();

    // ✅ API CALL ONLY ONCE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDefaultSelection();
    });
  }

  // Persistent controllers for dynamic ListViews to avoid cursor reset
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void dispose() {
    _subCategoryCubit.close();
    _propertyTypesCubit.close();
    minController.dispose();
    maxController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _initializeDefaultSelection() {
    if (widget.categoryList.isNotEmpty) {
      // By default select the first sub-category of the first tab (e.g. Residential in Rent)
      var firstTabCategory = widget.categoryList.first;

      // Only fetch subcategories for the first tab if not already present
      if (firstTabCategory.children != null &&
          firstTabCategory.children!.isNotEmpty) {
        _onPropertyTypeSelected(firstTabCategory.children!.first);
      } else {
        _propertyTypesCubit.fetchSubCategories(
            categoryId: firstTabCategory.id!);
      }
    }
  }

  // ... (skipping lines)

  void _onPropertyTypeSelected(CategoryModel propertyType) {
    setState(() {
      _selectedPropertyType = propertyType;
      _subCategoryPath.clear(); // Reset all subcategories
      _selectedFilters.clear(); // Reset filters when property type changes
    });

    // If this property type has children already loaded, we don't need to fetch.
    if (propertyType.children != null && propertyType.children!.isNotEmpty) {
      // Children already available
      // PROACTIVE FIX: Auto-select the first child (e.g. Apartment) so its filters show up
      setState(() {
        _subCategoryPath.add(propertyType.children!.first);
      });
      // [NEW] Also ensure the auto-selected child has its own children loaded if needed
      _fetchChildrenFor(propertyType.children!.first);
    } else {
      // Check if it's supposed to have children?
      // Many times subcategoriesCount is reliable.
      // Or just fetch anyway if it's a leaf node candidate.
      if ((propertyType.subcategoriesCount ?? 0) > 0) {
        // [MODIFIED] Use the manual fetch to keep logic consistent or keep using Cubit for this top level?
        // Let's stick to the existing Cubit for the top level for now to minimize risk,
        // OR rely on our new generic fetch. The existing Cubit updates `_selectedPropertyType` via BlocListener.
        _subCategoryCubit.fetchSubCategories(categoryId: propertyType.id!);
      }
    }
  }

  /// [NEW] Generic method to fetch children for any category level
  Future<void> _fetchChildrenFor(CategoryModel category) async {
    // [MODIFIED] Always fetch to ensure fresh data/filters
    // if (category.children != null && category.children!.isNotEmpty) return;

    // If no potential children, do nothing
    // [MODIFIED] Force fetch even if count is 0 to ensure we attempt to get dynamic data/filters
    // if ((category.subcategoriesCount ?? 0) <= 0) return;

    // Avoid duplicate fetches
    if (_loadingCategories[category.id] == true) return;

    setState(() {
      _loadingCategories[category.id!] = true;
    });

    try {
      print("DEBUG: fetching children for ${category.name} (${category.id})");
      DataOutput<CategoryModel> result = await _categoryRepository
          .fetchCategories(page: 1, categoryId: category.id!);

      if (mounted) {
        setState(() {
          _loadingCategories[category.id!] = false;
          // Update the model in memory (Note: this modifies the object references in _subCategoryPath)
          category.children?.clear();

          // [NEW] Extract fresh filters from self_category if available
          List<CategoryFilterModel>? freshFilters = category.filters;
          if (result.extraData?.data != null) {
            print(
                "DEBUG: Updating filters for ${category.name} from self_category");
            freshFilters = result.extraData!.data.filters;
          }

          CategoryModel newCategory = CategoryModel(
            id: category.id,
            name: category.name,
            url: category.url,
            description: category.description,
            subcategoriesCount: category.subcategoriesCount,
            //translatedName: category.translatedName,
            filters: freshFilters, // [MODIFIED] Use fresh filters
            children: result.modelList, // NEW DATA
          );

          // Find and replace in _subCategoryPath
          int index = _subCategoryPath.indexWhere((c) => c.id == category.id);
          if (index != -1) {
            // Retain selection if valid
            _subCategoryPath[index] = newCategory;
          }

          // ALSO: We might be updating `_selectedPropertyType` if this was called for it.
          if (_selectedPropertyType?.id == category.id) {
            _selectedPropertyType = newCategory;
          }
        });
      }
    } catch (e) {
      print("DEBUG: Error fetching children: $e");
      if (mounted) {
        setState(() {
          _loadingCategories[category.id!] = false;
        });
      }
    }
  }

  /*
   * Helper to get the currently active "Tab" category (Rent or Sale)
   */
  CategoryModel? get _currentTabCategory {
    if (widget.categoryList.length > _selectedTabIndex) {
      return widget.categoryList[_selectedTabIndex];
    }
    return null;
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      backgroundColor: context.color.secondaryColor,
      leading: Material(
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        type: MaterialType.circle,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Directionality(
              textDirection: Directionality.of(context),
              child: RotatedBox(
                quarterTurns:
                    Directionality.of(context) == TextDirection.rtl ? 2 : -4,
                child: UiUtils.getSvg(AppIcons.arrowLeft,
                    fit: BoxFit.none, color: context.color.textDefaultColor),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        widget.catName,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
      )
          .color(context.color.textDefaultColor)
          .bold(weight: FontWeight.w600)
          .size(18),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedTabIndex = 0;
              _initializeDefaultSelection();
            });
          },
          child: Text(
            "Reset".translate(context),
            style: TextStyle(
                color: context.color.textDefaultColor.withOpacity(0.5)),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
          context: context, statusBarColor: context.color.backgroundColor),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: _buildAppBar(context),
        body: Container(
          color: context.color.secondaryColor,
          child: BlocProvider.value(
            value: _propertyTypesCubit,
            child:
                BlocListener<FetchSubCategoriesCubit, FetchSubCategoriesState>(
              listener: (context, state) {
                if (state is FetchSubCategoriesSuccess) {
                  print(
                      "DEBUG: Top-level Listener: Fetched ${state.categories.length} categories");
                  if (state.categories.isNotEmpty) {
                    // 4️⃣ ✅ Filters only ONCE update
                    // Logic: If we already have a selected property type with filters, don't overwrite blindly unless it's a new selection context

                    if (_selectedPropertyType != null) {
                      // Sync existing selection with fresh data
                      try {
                        var freshData = state.categories.firstWhere((element) =>
                            element.id == _selectedPropertyType!.id);

                        // Only update if filters are meant to be initialized or data changed significantly
                        // For the purpose of "Filters only ONCE update" pattern:
                        if (!filtersInitialized &&
                            (freshData.filters?.isNotEmpty ?? false)) {
                          print(
                              "DEBUG: Initializing filters for ${_selectedPropertyType!.name}");
                          filtersInitialized = true;

                          setState(() {
                            _selectedPropertyType = freshData;
                            // Auto-select first child of the refreshed data if path is empty
                            if (_subCategoryPath.isEmpty &&
                                freshData.children != null &&
                                freshData.children!.isNotEmpty) {
                              _subCategoryPath.add(freshData.children!.first);
                              // [NEW] Trigger API fetch for this auto-selected child
                              _fetchChildrenFor(freshData.children!.first);
                            }
                          });
                        } else if (!filtersInitialized) {
                          // If no filters yet, we might still want to update data but keep flag false?
                          // Or just standard update.
                          setState(() {
                            _selectedPropertyType = freshData;
                            if (_subCategoryPath.isEmpty &&
                                freshData.children != null &&
                                freshData.children!.isNotEmpty) {
                              _subCategoryPath.add(freshData.children!.first);
                              _fetchChildrenFor(freshData.children!.first);
                            }
                          });
                        }
                      } catch (e) {
                        print(
                            "DEBUG: Could not find current selection in fresh list: $e");
                      }
                    } else {
                      // Auto-select the first one if nothing is selected
                      var firstProp = state.categories.first;
                      setState(() {
                        _selectedPropertyType = firstProp;
                        // Auto-select first child of this auto-selected property
                        if (firstProp.children != null &&
                            firstProp.children!.isNotEmpty) {
                          _subCategoryPath.clear();
                          _subCategoryPath.add(firstProp.children!.first);
                          // [NEW] Trigger API fetch for this auto-selected child
                          _fetchChildrenFor(firstProp.children!.first);
                        }
                      });
                      // Also fetch subcategories for this auto-selected item if needed
                      if ((firstProp.subcategoriesCount ?? 0) > 0) {
                        _subCategoryCubit.fetchSubCategories(
                            categoryId: firstProp.id!);
                      }
                    }
                  }
                }
              },
              child: Column(
                children: [
                  _buildTabs(),

                  ///////body of the tabs
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLocationSection(),
                          const SizedBox(height: 12),
                          _buildPropertyTypes(),
                          if (_selectedPropertyType != null) ...[
                            const SizedBox(height: 12),
                            _buildSubCategories(),
                          ],
                          if (_selectedPropertyType?.filters != null &&
                              _selectedPropertyType!.filters!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDynamicFilters(
                                _selectedPropertyType!.filters!),
                          ],
                          // Recursively build all subsequent category levels
                          ..._buildDynamicCategoryLevels(),

                          // Render filters for any selected sub-categories (e.g. Apartment)
                          if (_subCategoryPath.isNotEmpty) ...[
                            ..._subCategoryPath.map((cat) {
                              if (cat.filters != null &&
                                  cat.filters!.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: _buildDynamicFilters(cat.filters!),
                                );
                              }
                              return const SizedBox.shrink();
                            }).toList(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///
  ///
  ///
  /// ]\]
  ///
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: context.color.secondaryColor,
      child: Row(
        children: [
          for (int index = 0; index < widget.categoryList.length; index++) ...[
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = index;
                  });

                  // Fetch subcategories for the new tab (e.g. Sale) if needed
                  var currentCategory = widget.categoryList[index];
                  if (currentCategory.children == null ||
                      currentCategory.children!.isEmpty) {
                    _propertyTypesCubit.fetchSubCategories(
                        categoryId: currentCategory.id!);
                  }
                  // Auto-select first child if available (replication of init logic)
                  if (currentCategory.children != null &&
                      currentCategory.children!.isNotEmpty) {
                    _onPropertyTypeSelected(currentCategory.children!.first);
                  } else {
                    setState(() {
                      _selectedPropertyType = null;
                      _subCategoryPath.clear();
                      _selectedFilters.clear();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: _selectedTabIndex == index
                        ? Border(
                            bottom: BorderSide(
                                color: context.color.territoryColor, width: 2))
                        : null,
                  ),
                  child: Text(
                    widget.categoryList[index].name ?? "",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedTabIndex == index
                          ? context.color.territoryColor
                          : context.color.textDefaultColor,
                      fontWeight: _selectedTabIndex == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            if (index != widget.categoryList.length - 1)
              const SizedBox(width: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Location",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.color.textDefaultColor),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.color.borderColor),
          ),
          child: const LocationWidget(),
        ),
        const SizedBox(height: 8),
        Text(
          "Select the cities neighbourhoods or building that you want to search property in .",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPropertyTypes() {
    CategoryModel? activeTab = _currentTabCategory;
    if (activeTab == null) return const SizedBox.shrink();

    // Case 1: Children are pre-loaded
    if (activeTab.children != null && activeTab.children!.isNotEmpty) {
      return _buildPropertyTypesList(activeTab.children!);
    }

    // Case 2: Children need fetching
    return BlocProvider.value(
      value: _propertyTypesCubit,
      child: BlocConsumer<FetchSubCategoriesCubit, FetchSubCategoriesState>(
        listener: (context, state) {
          if (state is FetchSubCategoriesSuccess) {
            print("DEBUG: Fetched ${state.categories.length} categories");
            if (state.categories.isNotEmpty) {
              if (_selectedPropertyType != null) {
                // Sync existing selection with fresh data
                try {
                  var freshData = state.categories.firstWhere(
                      (element) => element.id == _selectedPropertyType!.id);
                  print(
                      "DEBUG: Found fresh data for ${_selectedPropertyType!.name}. Filters count: ${freshData.filters?.length}");
                  setState(() {
                    _selectedPropertyType = freshData;
                    // Auto-select first child of the refreshed data
                    if (freshData.children != null &&
                        freshData.children!.isNotEmpty) {
                      _subCategoryPath.clear();
                      _subCategoryPath.add(freshData.children!.first);
                    }
                  });
                } catch (e) {
                  print(
                      "DEBUG: Could not find current selection in fresh list: $e");
                }
              } else {
                // Auto-select the first one if nothing is selected
                var firstProp = state.categories.first;
                setState(() {
                  _selectedPropertyType = firstProp;
                  // Auto-select first child of this auto-selected property
                  if (firstProp.children != null &&
                      firstProp.children!.isNotEmpty) {
                    _subCategoryPath.clear();
                    _subCategoryPath.add(firstProp.children!.first);
                  }
                });
                // Also fetch subcategories for this auto-selected item if needed
                if ((firstProp.subcategoriesCount ?? 0) > 0) {
                  _subCategoryCubit.fetchSubCategories(
                      categoryId: firstProp.id!);
                }
              }
            }
          }
        },
        builder: (context, state) {
          if (state is FetchSubCategoriesInProgress) {
            return _buildPropertyTypeShimmer();
          }
          if (state is FetchSubCategoriesSuccess) {
            if (state.categories.isEmpty) return const SizedBox.shrink();

            return _buildPropertyTypesList(state.categories);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  //PRPERTY TYPE
  Widget _buildPropertyTypesList(List<CategoryModel> propertyTypes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Property Type",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.color.textDefaultColor),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: propertyTypes.map((subCat) {
              bool isSelected = _selectedPropertyType?.id == subCat.id;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    _onPropertyTypeSelected(subCat);
                  },
                  child: Container(
                    width: 100,
                    height: 90, // 🔥 FIXED HEIGHT (important)
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? context.color.textDefaultColor
                            : context.color.borderColor,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        /// ICON
                        SizedBox(
                          height: 30,
                          width: 30,
                          child: UiUtils.imageType(
                            subCat.url ?? "",
                            color: isSelected
                                ? context.color.textDefaultColor
                                : context.color.textDefaultColor,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 8),

                        /// TEXT (height controlled)
                        SizedBox(
                          height: 32, // 🔥 text area fixed
                          child: Text(
                            subCat.name ?? "",
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? context.color.textDefaultColor
                                  : context.color.textDefaultColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              height: 1.2, // 🔥 line height control
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubCategories() {
    // Check if we have children locally first
    if (_selectedPropertyType?.children != null &&
        _selectedPropertyType!.children!.isNotEmpty) {
      // Pass Level 0 to identify this is the first level of dynamic categories
      return _buildDynamicSubCategoryChips(0, _selectedPropertyType!.children!);
    }

    // Otherwise use BlocBuilder to listen to fetched children
    return BlocProvider.value(
      value: _subCategoryCubit,
      child: BlocBuilder<FetchSubCategoriesCubit, FetchSubCategoriesState>(
        builder: (context, state) {
          if (state is FetchSubCategoriesInProgress) {
            return _buildSubCategoryShimmer();
          }
          if (state is FetchSubCategoriesSuccess) {
            if (state.categories.isEmpty) return const SizedBox.shrink();
            return _buildDynamicSubCategoryChips(0, state.categories);
          }
          if (state is FetchSubCategoriesFailure) {
            return const SizedBox.shrink();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPropertyTypeShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Property Type",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.color.textDefaultColor),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CustomShimmer(
                  width: 100,
                  height: 90,
                  borderRadius: 8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubCategoryShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomShimmer(
          height: 20,
          width: 150,
          borderRadius: 4,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CustomShimmer(
                  width: 100,
                  height: 35,
                  borderRadius: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a LIST of widgets for sequential levels:
  /// Level 1 (if Level 0 selected) -> Level 2 (if Level 1 selected) -> ...
  List<Widget> _buildDynamicCategoryLevels() {
    List<Widget> levels = [];

    // Iterate through the CURRENT path to show the NEXT level for each selection
    for (int i = 0; i < _subCategoryPath.length; i++) {
      CategoryModel currentSelection = _subCategoryPath[i];

      // [NEW] Check if this specific category is loading
      bool isLoading = _loadingCategories[currentSelection.id] == true;
      if (isLoading) {
        levels.add(const SizedBox(height: 12));
        levels.add(_buildSubCategoryShimmer());
      } else if (currentSelection.children != null &&
          currentSelection.children!.isNotEmpty) {
        levels.add(const SizedBox(height: 12));
        // The children of path[i] constitute level i+1
        levels.add(
            _buildDynamicSubCategoryChips(i + 1, currentSelection.children!));
      }
    }
    return levels;
  }

  /// Generic widget to build a row of chips for a specific level
  Widget _buildDynamicSubCategoryChips(
      int levelIndex, List<CategoryModel> subCats) {
    // Determine which item is currently selected at this level (if any)
    CategoryModel? currentlySelectedAtThisLevel;
    if (_subCategoryPath.length > levelIndex) {
      currentlySelectedAtThisLevel = _subCategoryPath[levelIndex];
    }

    // Title logic:
    // If level 0, use PropertyType name.
    // If level > 0, use the name of the parent (which is at levelIndex - 1)
    String titleName = "";
    if (levelIndex == 0) {
      titleName = _selectedPropertyType?.name ?? "";
    } else {
      titleName = _subCategoryPath[levelIndex - 1].name ?? "";
    }

    // Customize suffix using a Map configuration
    // You can add more static mappings here easily
    Map<String, String> suffixMap = {
      'apartment': 'Rooms',
    };

    // Default to 'Categories' if not found in map
    String suffix = suffixMap[titleName.toLowerCase()] ?? 'Categories';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$titleName $suffix",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.color.textDefaultColor,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: subCats.map((child) {
              bool isSelected = currentlySelectedAtThisLevel?.id == child.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(child.name ?? ""),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? context.color.textDefaultColor
                        : context.color.borderColor,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  labelStyle: TextStyle(
                    color: context.color.textDefaultColor,
                  ),
                  // 🔥 CORE SELECTION LOGIC
                  onPressed: () {
                    setState(() {
                      // 1. If we are changing a selection at an existing level,
                      // discard everything deeper than this level.
                      if (_subCategoryPath.length > levelIndex) {
                        // We are re-selecting at this level.
                        // Remove this level and everything after it.
                        _subCategoryPath.removeRange(
                            levelIndex, _subCategoryPath.length);
                      }

                      // 2. Add the new selection
                      _subCategoryPath.add(child);

                      // 3. [NEW] Fetch children for this new selection if needed
                      _fetchChildrenFor(child);
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: MaterialButton(
        onPressed: () {
          _onShowResults();
        },
        height: 50,
        minWidth: double.infinity,
        color: context.color.territoryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Text(
          "Show Results",
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _onShowResults() {
    // 1. Validate Property Type
    if (_selectedPropertyType == null) {
      HelperUtils.showSnackBarMessage(
          context, "Please select a Property Type".translate(context));
      return;
    }

    // 2. Validate chain completion (Ensure user didn't stop at a parent category)
    CategoryModel lastSelected;
    if (_subCategoryPath.isNotEmpty) {
      lastSelected = _subCategoryPath.last;
    } else {
      lastSelected = _selectedPropertyType!;
    }

    if (lastSelected.children != null && lastSelected.children!.isNotEmpty) {
      HelperUtils.showSnackBarMessage(
          context, "Please select sub-category for ${lastSelected.name}");
      return;
    }

    // 3. Validate Dynamic Filters (Strict: All filters from API must have a selection)
    List<CategoryModel> allSelectedCategories = [];
    if (_selectedPropertyType != null) {
      allSelectedCategories.add(_selectedPropertyType!);
    }
    allSelectedCategories.addAll(_subCategoryPath);

    for (var cat in allSelectedCategories) {
      if (cat.filters != null && cat.filters!.isNotEmpty) {
        for (var filter in cat.filters!) {
          // Range Filter Check
          if (filter.type == 'range') {
            String minKey = "${filter.name}_min";
            // Check if min is set (handling loose typing)
            bool isMinSet = _selectedFilters.containsKey(minKey) &&
                _selectedFilters[minKey] != null &&
                _selectedFilters[minKey].toString().isNotEmpty;

            if (!isMinSet) {
              HelperUtils.showSnackBarMessage(
                  context, "Please select range for ${filter.name}");
              return;
            }
          }
          // Other Filters Check
          else {
            if (!_selectedFilters.containsKey(filter.name) ||
                _selectedFilters[filter.name] == null ||
                (_selectedFilters[filter.name] is String &&
                    (_selectedFilters[filter.name] as String).isEmpty) ||
                (_selectedFilters[filter.name] is List &&
                    (_selectedFilters[filter.name] as List).isEmpty)) {
              HelperUtils.showSnackBarMessage(
                  context, "Please select ${filter.name}");
              return;
            }
          }
        }
      }
    }

    List<String> accumulatedIds = [...widget.categoryIds];
    List<CategoryModel> accumulatedModels = [];

    if (_currentTabCategory != null) {
      accumulatedIds.add(_currentTabCategory!.id.toString());
      accumulatedModels.add(_currentTabCategory!);
    }
    if (_selectedPropertyType != null) {
      accumulatedIds.add(_selectedPropertyType!.id.toString());
      accumulatedModels.add(_selectedPropertyType!);
    }

    // Add all dynamically selected sub, nested, etc. categories
    for (var cat in _subCategoryPath) {
      accumulatedIds.add(cat.id.toString());
      accumulatedModels.add(cat);
    }

    CategoryModel targetCat;
    if (_subCategoryPath.isNotEmpty) {
      targetCat = _subCategoryPath.last;
    } else {
      targetCat = _selectedPropertyType ??
          _currentTabCategory ??
          widget.categoryList[0];
    }

    Navigator.pushNamed(context, Routes.itemsList, arguments: {
      'catID': targetCat.id.toString(),
      'catName': targetCat.name,
      "categoryIds": accumulatedIds,
      "selectedCategoryChain": accumulatedModels,
      "selectedFilters": _selectedFilters, // Pass the dynamic filters
    });
  }

  Widget _buildDynamicFilters(List<CategoryFilterModel> filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filters.map((filter) {
        // SPECIAL CASE: AMENITIES
        // Check for "Amenities" or "Amenity" (Case insensitive)
        if (filter.name != null &&
            (filter.name!.toLowerCase().contains("amenit") ||
                filter.name!.toLowerCase() == "features")) {
          // Extract currently selected list for this filter
          List<dynamic> currentSelection = [];
          var rawSelection = _selectedFilters[filter.name];
          if (rawSelection is List) {
            currentSelection = List.from(rawSelection);
          } else if (rawSelection is String && rawSelection.isNotEmpty) {
            // If stored as comma string previously (defensive)
            currentSelection = rawSelection.split(',');
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                filter.name ?? "",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.color.textDefaultColor),
              ),
              const SizedBox(height: 12),

              // 1. Horizontal Scrollable List of ALL options (Chips)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (filter.values ?? []).map((value) {
                    bool isSelected = currentSelection.contains(value);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            // Toggle selection logic
                            if (isSelected) {
                              currentSelection.remove(value);
                            } else {
                              currentSelection.add(value);
                            }

                            if (currentSelection.isEmpty) {
                              _selectedFilters.remove(filter.name);
                            } else {
                              _selectedFilters[filter.name!] = currentSelection;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: context.color.secondaryColor,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                width: isSelected ? 1.5 : 1,
                                color: isSelected
                                    ? context.color.textDefaultColor
                                    : context.color.borderColor),
                          ),
                          child: Text(
                            value.toString(),
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: context.color.textDefaultColor),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // 2. View All Button (Below the list, Blue color)
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AmenitiesFilterScreen(
                          allAmenities: filter.values ?? [],
                          selectedAmenities: currentSelection,
                        ),
                      ),
                    );

                    if (result != null && result is List) {
                      setState(() {
                        if (result.isEmpty) {
                          _selectedFilters.remove(filter.name);
                        } else {
                          _selectedFilters[filter.name!] = result;
                        }
                      });
                    }
                  },
                  child: const Text(
                    "View all >",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue, // Requested Blue color
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
          );
        }

        // TYPE: BUTTON (Selection Chips)
        if (filter.type == 'button') {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                filter.name ?? "",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.color.textDefaultColor),
              ),
              const SizedBox(height: 12),
              // Changed from Wrap to SingleChildScrollView + Row for horizontal scrolling
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (filter.values ?? []).map((value) {
                    bool isSelected = _selectedFilters[filter.name] == value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            // Functionality: Allow Toggle? Target UI behaves like radio for some (Bedroom) or multi (Amenities)?
                            // Current logic is single select per filter name.
                            if (isSelected) {
                              _selectedFilters.remove(filter.name);
                            } else {
                              _selectedFilters[filter.name!] = value;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white, // White usually
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                width: isSelected ? 1.5 : 1,
                                color: isSelected
                                    ? context
                                        .color.textDefaultColor // Black/Dark
                                    : context.color.borderColor), // Grey
                          ),
                          child: Text(
                            value.toString(),
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: context.color.textDefaultColor),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }

        // TYPE: NUMBER (Text Field)
        if (filter.type == 'number') {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                filter.name ?? "",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.color.textDefaultColor),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: context.color.secondaryColor,
                  border: Border.all(color: context.color.borderColor),
                ),
                child: TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        _selectedFilters.remove(filter.name);
                      } else {
                        _selectedFilters[filter.name!] = value;
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: filter.placeholder ?? "Enter ${filter.name}",
                    hintStyle: TextStyle(
                        color: context.color.textDefaultColor.withOpacity(0.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: context.color.textDefaultColor),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }

        // TYPE: RANGE (Min/Max Input + Slider)
        if (filter.type == 'range') {
          double currentMin = double.tryParse(
                  _selectedFilters["${filter.name}_min"]?.toString() ?? '0') ??
              0;
          double currentMax = double.tryParse(
                  _selectedFilters["${filter.name}_max"]?.toString() ??
                      '1000000') ??
              1000000;

          // Dynamic Max: If user types more than default max, expand the slider
          double sliderMax = 1000000;
          if (currentMax > sliderMax) sliderMax = currentMax;
          // Ensure min is also within bounds for slider logic?
          // Actually slider just needs min <= value <= max.
          // Start of slider is 0.

          // Create/Retrieve Persistent Objects
          // Min
          String minKey = "${filter.name}_min";
          TextEditingController minCtrl = _controllers.putIfAbsent(
              minKey,
              () => TextEditingController(
                  text: currentMin == 0 ? "" : currentMin.round().toString()));
          FocusNode minFocus =
              _focusNodes.putIfAbsent(minKey, () => FocusNode());

          // Max
          String maxKey = "${filter.name}_max";
          TextEditingController maxCtrl = _controllers.putIfAbsent(
              maxKey,
              () => TextEditingController(
                  text: currentMax == 1000000
                      ? ""
                      : currentMax.round().toString()));
          FocusNode maxFocus =
              _focusNodes.putIfAbsent(maxKey, () => FocusNode());

          // Sync Logic: If NOT focused, keep text updated with State (Slider drags)
          if (!minFocus.hasFocus) {
            String newVal =
                currentMin == 0 ? "" : currentMin.round().toString();
            if (minCtrl.text != newVal) {
              minCtrl.text = newVal;
            }
          }
          if (!maxFocus.hasFocus) {
            String newVal = currentMax == 1000000 && sliderMax == 1000000
                ? ""
                : currentMax.round().toString();
            // logic: if it's default 1M, show empty? Or show 1000000?
            // Standard UI often leaves max empty if default.
            // But keeping it numeric is safer for "10000".
            if (maxCtrl.text != newVal && newVal != "1000000") {
              // Keep "1000000" hidden if default? Or show? User wants manual control.
              // Let's show actual value unless it's pure init.
              // If I type 10000, I want to see 10000.
              maxCtrl.text = newVal;
            } else if (newVal == "1000000" &&
                sliderMax == 1000000 &&
                maxCtrl.text.isEmpty) {
              // allow empty for default max
            } else if (maxCtrl.text != newVal) {
              maxCtrl.text = newVal;
            }
          }

          // Smart Suffix
          String suffix = "AED";
          if (filter.name!.toLowerCase().contains("area") ||
              filter.name!.toLowerCase().contains("size")) {
            suffix = "Sqft";
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                filter.name ?? "",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.color.textDefaultColor),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: context.color.secondaryColor,
                        border: Border.all(color: context.color.borderColor),
                      ),
                      child: TextField(
                        controller: minCtrl,
                        focusNode: minFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          // Allow empty (reset to 0)
                          double val =
                              value.isEmpty ? 0 : double.tryParse(value) ?? 0;
                          setState(() {
                            _selectedFilters["${filter.name}_min"] =
                                val.toString();
                            // Ensure consistency if min > max?
                            // Usually better to let user type freely and validator handles it,
                            // or clamp silently.
                            // If I type 5000 and max is 1000, momentarily invalid state for Slider?
                            // Slider requires values.start <= values.end.
                            // We must ensure that before passing to slider.
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Min",
                          suffixText: suffix,
                          hintStyle: TextStyle(
                              color: context.color.textDefaultColor
                                  .withOpacity(0.5)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: context.color.textDefaultColor),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("To",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: context.color.secondaryColor,
                        border: Border.all(color: context.color.borderColor),
                      ),
                      child: TextField(
                        controller: maxCtrl,
                        focusNode: maxFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          double val = value.isEmpty
                              ? 1000000
                              : double.tryParse(value) ?? 1000000;
                          setState(() {
                            _selectedFilters["${filter.name}_max"] =
                                val.toString();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Max",
                          suffixText: suffix,
                          hintStyle: TextStyle(
                              color: context.color.textDefaultColor
                                  .withOpacity(0.5)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: context.color.textDefaultColor),
                      ),
                    ),
                  ),
                ],
              ),
              // Slider
              const SizedBox(height: 8),

              RangeSlider(
                values: RangeValues(
                  currentMin.clamp(0, sliderMax),
                  (currentMax < currentMin ? currentMin : currentMax)
                      .clamp(0, sliderMax),
                ),
                min: 0,
                max: sliderMax,
                // divisions: sliderMax > 0 ? 100 : 1,
                labels: RangeLabels(
                  currentMin.round().toString(),
                  currentMax.round().toString(),
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    _selectedFilters["${filter.name}_min"] =
                        values.start.round().toString();
                    _selectedFilters["${filter.name}_max"] =
                        values.end.round().toString();
                  });
                },
              ),

              const SizedBox(height: 12),
            ],
          );
        }

        return const SizedBox.shrink();
      }).toList(),
    );
  }
}
