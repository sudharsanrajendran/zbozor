import 'package:flutter/cupertino.dart';import 'dart:async';
import 'dart:math';

import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/ui/screens/widgets/amenities_filter_screen.dart';
import 'package:Ebozor/data/cubits/item/fetch_item_from_category_cubit.dart';
import 'package:Ebozor/data/cubits/category/fetch_sub_categories_cubit.dart';
import 'package:Ebozor/data/model/category_model.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

import 'package:Ebozor/utils/app_icon.dart';
import 'package:Ebozor/utils/sliver_grid_delegate_with_fixed_cross_axis_count_and_fixed_height.dart';
import 'package:Ebozor/data/model/item/item_model.dart';
import 'package:Ebozor/data/model/item_filter_model.dart';

import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/ApiService/api.dart';

import 'package:Ebozor/utils/responsiveSize.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:Ebozor/ui/screens/home/widgets/home_sections_adapter.dart';
import 'package:Ebozor/ui/screens/widgets/errors/no_data_found.dart';
import 'package:Ebozor/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:Ebozor/ui/screens/home/widgets/item_horizontal_card.dart';
import 'package:Ebozor/ui/screens/main_activity.dart';
import 'package:Ebozor/ui/screens/native_ads_screen.dart';
import 'package:Ebozor/ui/screens/widgets/shimmerLoadingContainer.dart';

class ItemsList extends StatefulWidget {
  final String categoryId, categoryName;
  final List<String> categoryIds;
  final List<CategoryModel>? selectedCategoryChain;
  final Map<String, dynamic>? selectedFilters;

  const ItemsList(
      {super.key,
      required this.categoryId,
      required this.categoryName,
      required this.categoryIds,
      this.selectedCategoryChain,
      this.selectedFilters});

  @override
  ItemsListState createState() => ItemsListState();

  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (_) => ItemsList(
        categoryId: arguments?['catID'] as String,
        categoryName: arguments?['catName'],
        categoryIds: arguments?['categoryIds'],
        selectedCategoryChain: arguments?['selectedCategoryChain'],
        selectedFilters: arguments?['selectedFilters'],
      ),
    );
  }
}

class ItemsListState extends State<ItemsList> {
  late ScrollController controller;
  static TextEditingController searchController = TextEditingController();
  bool isFocused = false;
  bool isList = true;
  String previousSearchQuery = "";
  Timer? _searchDelay;
  String? sortBy;
  ItemFilterModel? filter;

  // For dynamic filtering
  late List<CategoryModel> _currentChain;
  late final FetchSubCategoriesCubit _chipFilterCubit;
  List<String> _currentCategoryIds = [];
  Map<String, dynamic> _selectedCustomFields = {};

  bool _showVerifiedOnly = false;

  @override
  void initState() {
    super.initState();
    _chipFilterCubit = FetchSubCategoriesCubit();
    // Initialize chain from arguments or empty
    _currentChain = widget.selectedCategoryChain ?? [];

    // Initialize custom fields from arguments
    _selectedCustomFields =
        widget.selectedFilters != null ? Map.from(widget.selectedFilters!) : {};

    // Fix: Extract Price from custom fields and move to standard filter fields
    String? priceMin, priceMax;
    if (_selectedCustomFields.containsKey("Price_min")) {
      priceMin = _selectedCustomFields["Price_min"].toString();
      _selectedCustomFields.remove("Price_min");
    }
    if (_selectedCustomFields.containsKey("Price_max")) {
      priceMax = _selectedCustomFields["Price_max"].toString();
      _selectedCustomFields.remove("Price_max");
    }

    // Fallback: If chain is empty but we have a main category and it's not "Property" (which is root), add it.
    // Actually, simply relying on arguments is safer.
    // If empty & we have categoryName, maybe add it?
    if (_currentChain.isEmpty && widget.categoryId.isNotEmpty) {
      // Basic fallback
      _currentChain.add(CategoryModel(
          id: int.tryParse(widget.categoryId) ?? 0,
          name: widget.categoryName,
          children: [],
          subcategoriesCount: 0));
    }

    _currentCategoryIds = List.from(widget.categoryIds);
    searchbody = {};
    Constant.itemFilter = null;
    searchController = TextEditingController();
    searchController.addListener(searchItemListener);
    controller = ScrollController()..addListener(_loadMore);

    // Initialize filter with extracted price
    filter = ItemFilterModel(
        country: HiveUtils.getCountryName() ?? "",
        areaId: HiveUtils.getAreaId() != null
            ? int.parse(HiveUtils.getAreaId().toString())
            : null,
        city: HiveUtils.getCityName() ?? "",
        state: HiveUtils.getStateName() ?? "",
        categoryId: widget.categoryId,
        radius: HiveUtils.getNearbyRadius() ?? null,
        latitude: HiveUtils.getLatitude() ?? null,
        longitude: HiveUtils.getLongitude() ?? null,
        minPrice: priceMin,
        maxPrice: priceMax,
        customFields: _selectedCustomFields);

    context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
        categoryId: int.parse(
          widget.categoryId,
        ),
        search: "",
        filter: filter);

    Future.delayed(Duration.zero, () {
      selectedcategoryId = widget.categoryId;
      selectedcategoryName = widget.categoryName;
      searchbody[Api.categoryId] = widget.categoryId;
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.removeListener(_loadMore);
    controller.dispose();
    searchController.dispose();
    _chipFilterCubit.close();
    super.dispose();
  }

  //this will listen and manage search
  void searchItemListener() {
    _searchDelay?.cancel();
    searchCallAfterDelay();
  }

//This will create delay so we don't face rapid api call
  void searchCallAfterDelay() {
    _searchDelay = Timer(const Duration(milliseconds: 500), itemSearch);
  }

  ///This will call api after some delay
  void itemSearch() {
    // if (searchController.text.isNotEmpty) {
    if (previousSearchQuery != searchController.text) {
      context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
          categoryId: int.parse(
            widget.categoryId,
          ),
          search: searchController.text);
      previousSearchQuery = searchController.text;
      sortBy = null;
      setState(() {});
    }
  }

  void _loadMore() async {
    if (controller.isEndReached()) {
      if (context.read<FetchItemFromCategoryCubit>().hasMoreData()) {
        context.read<FetchItemFromCategoryCubit>().fetchItemFromCategoryMore(
            catId: int.parse(
              widget.categoryId,
            ),
            search: searchController.text,
            sortBy: sortBy,
            filter: ItemFilterModel(
              country: HiveUtils.getCountryName() ?? "",
              areaId: HiveUtils.getAreaId() != null
                  ? int.parse(HiveUtils.getAreaId().toString())
                  : null,
              city: HiveUtils.getCityName() ?? "",
              state: HiveUtils.getStateName() ?? "",
              categoryId: widget.categoryId,
            ));
      }
    }
  }

  Widget searchBarWidget() {
    return Container(
      color: context.color.secondaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          /// 🔍 SEARCH FIELD
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 0.1,
                  color: context.color.borderColor.darken(30),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                color: context.color.backgroundColor,
              ),
              child: TextFormField(
                controller: searchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  hintText: 'searchHintLbl'.translate(context),
                  prefixIcon: setSearchIcon(),
                  prefixIconConstraints:
                      const BoxConstraints(minHeight: 40, minWidth: 40),
                ),
                enableSuggestions: true,
                onEditingComplete: () {
                  setState(() {
                    isFocused = false;
                    FocusScope.of(context).unfocus();
                  });
                },
                onTap: () {
                  setState(() {
                    isFocused = true;
                  });
                },
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// 🔲 GRID VIEW ONLY
          GestureDetector(
            onTap: () {
              setState(() {
                isList = false; // 🔥 always GRID
              });
            },
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: context.color.borderColor.darken(30),
                ),
                color: !isList
                    ? context.color.backgroundColor
                    : context.color.secondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: UiUtils.getSvg(
                  AppIcons.gridViewIcon,
                  color: !isList
                      ? context.color.territoryColor
                      : context.color.textDefaultColor.withOpacity(0.2),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// ☰ MENU → LIST VIEW ONLY
          GestureDetector(
            onTap: () {
              setState(() {
                isList = true; // 🔥 always LIST
              });
            },
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: context.color.borderColor.darken(30),
                ),
                color: isList
                    ? context.color.backgroundColor
                    : context.color.secondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: UiUtils.getSvg(
                  AppIcons
                      .listViewIcon, // Was Icon(Icons.menu), switching to SVG for consistency if available, OR keeping Icon but fixing color
                  color: isList
                      ? context.color.territoryColor
                      : context.color.textDefaultColor.withOpacity(0.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onResetTap() {
    setState(() {
      searchController.clear();
      previousSearchQuery = "";
      filter = null;
      _selectedCustomFields.clear(); // Clear selected custom chips
      _currentCategoryIds = [widget.categoryId];
      _isAllFieldsSelected = true;

      context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
          categoryId: int.parse(widget.categoryId),
          search: "",
          filter: ItemFilterModel(
              country: HiveUtils.getCountryName() ?? "",
              areaId: HiveUtils.getAreaId() != null // Restore Area ID if exists
                  ? int.parse(HiveUtils.getAreaId().toString())
                  : null,
              city: HiveUtils.getCityName() ?? "",
              state: HiveUtils.getStateName() ?? "",
              categoryId: widget.categoryId,
              radius: HiveUtils.getNearbyRadius() ?? null,
              latitude: HiveUtils.getLatitude() ?? null,
              longitude: HiveUtils.getLongitude() ?? null));
    });
  }

  Widget _buildFilterChips() {
    return Container(
      color: context.color.secondaryColor,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Dynamic Chips - Show ALL items in chain
            ...List.generate(_currentChain.length, (index) {
              if (index == 2) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildDynamicChip(index),
              );
            }),

            // Static Price Filter
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                label: "budgetLbl".translate(context),
                isActive: filter?.minPrice != null || filter?.maxPrice != null,
                onTap: () => _onFilterChipTap("price"),
              ),
            ),

            // Static Area Filter

            // Dynamic Chips - All Available Filters in Chain
            ..._currentChain.expand((cat) => cat.filters ?? []).map((filter) {
              // Skip Price if handled explicitly (assuming naming convention)
              if (filter.name!.toLowerCase().contains("price")) {
                return const SizedBox.shrink();
              }

              String label = filter.name ?? "";
              bool isActive = false;

              // Check for Range keys (suffix _min / _max)
              if (_selectedCustomFields.containsKey("${filter.name}_min") ||
                  _selectedCustomFields.containsKey("${filter.name}_max")) {
                isActive = true;
              }
              // Check for standard key
              else if (_selectedCustomFields.containsKey(filter.name)) {
                isActive = true;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildChip(
                  label: label,
                  isActive: isActive,
                  onTap: () => _onFilterChipTap(filter.name!),
                ),
              );
            }).toList(),

            // All Fields Chip
            _buildChip(
                label: "lblall".translate(context),
                isActive: _isAllFieldsSelected,
                onTap: _onAllFieldsTap),

            const SizedBox(width: 15),

            // Reset Button
            GestureDetector(
              onTap: _onResetTap,
              child: Text("reset".translate(context),
                  style: TextStyle(
                      color: (_selectedCustomFields.isNotEmpty ||
                              filter != null ||
                              searchController.text.isNotEmpty)
                          ? context.color.deactivateColor
                          : context.color.textDefaultColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicChip(int chainIndex) {
    CategoryModel currentModel = _currentChain[chainIndex];
    return _buildChip(
      label: currentModel.name ?? "",
      isActive: true, // Always show as active/visible
      onTap: () {
        if (_isAllFieldsSelected) {
          _restoreSelection(chainIndex);
        } else {
          _showDynamicFilterBottomSheet(chainIndex);
        }
      },
    );
  }

  bool _isAllFieldsSelected = false;
  final Map<int, List<CategoryModel>> _selectionHistory = {};

  void _onAllFieldsTap() {
    setState(() {
      // Do not clear the chain, just reset the search to root
      _isAllFieldsSelected = true;
      _currentCategoryIds = [widget.categoryId];

      context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
          categoryId: int.tryParse(widget.categoryId) ?? 0,
          search: searchController.text);
    });
  }

  void _restoreSelection(int chainIndex) {
    setState(() {
      _isAllFieldsSelected = false;

      // Truncate chain after chainIndex
      if (_currentChain.length > chainIndex + 1) {
        _currentChain.removeRange(chainIndex + 1, _currentChain.length);
      }

      List<String> newIds = [widget.categoryId];
      for (var cat in _currentChain) {
        newIds.add(cat.id.toString());
      }
      _currentCategoryIds = newIds;

      // Fetch
      CategoryModel? targetCat =
          _currentChain.isNotEmpty ? _currentChain.last : null;
      int targetId = targetCat?.id ?? int.tryParse(widget.categoryId) ?? 0;

      context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
          categoryId: targetId, search: searchController.text);
    });
  }

  void _showDynamicFilterBottomSheet(int chainIndex) {
    // Determine the Parent ID to fetch siblings from.
    String parentId;
    if (chainIndex == 0) {
      parentId = widget.categoryIds.isNotEmpty ? widget.categoryIds[0] : "0";
    } else {
      if (chainIndex - 1 < _currentChain.length) {
        parentId = _currentChain[chainIndex - 1].id.toString();
      } else {
        return; // Error state
      }
    }

    // Fetch from API
    _chipFilterCubit.fetchSubCategories(
        categoryId: int.tryParse(parentId) ?? 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // --- CASE 1: Simple Text Only (For Index 0 and Index > 1) ---
        if (chainIndex != 1) {
          // [FIX] Ensure selectedCategory is initialized correctly for Index 0
          CategoryModel? selectedCategory;
          if (_currentChain.length > chainIndex) {
            selectedCategory = _currentChain[chainIndex];
          }

          return BlocProvider.value(
            value: _chipFilterCubit,
            child: StatefulBuilder(builder: (context, setModalState) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height *
                      0.4, // Max Height 40%
                ),
                decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20))),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            chainIndex == 0
                                ? "type".translate(context)
                                : "selectLbl".translate(context),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.color.textDefaultColor)),
                      ],
                    ),
                    if (chainIndex == 0) ...[
                      const SizedBox(height: 16),
                      Text(
                        "chooseItemType".translate(context),
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              context.color.textDefaultColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Grid Text Only
                    Flexible(
                      child: BlocBuilder<FetchSubCategoriesCubit,
                          FetchSubCategoriesState>(
                        builder: (context, state) {
                          if (state is FetchSubCategoriesInProgress) {
                            return SizedBox(
                              height: 50,
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount: 5,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  return const CustomShimmer(
                                    height: 50,
                                    width: 110,
                                    borderRadius: 10,
                                  );
                                },
                              ),
                            );
                          }
                          if (state is FetchSubCategoriesSuccess) {
                            if (state.categories.isEmpty)
                              return const Text("No options");

                            return SizedBox(
                              height: 50,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: state.categories.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 12), // Clean gap
                                itemBuilder: (context, index) {
                                  CategoryModel cat = state.categories[index];
                                  bool isSelected =
                                      selectedCategory?.id == cat.id;
                                  // Pass width constraint or handle in card
                                  return SizedBox(
                                    width:
                                        110, // Fixed width for horizontal items
                                    child: _buildCategoryCard(
                                        context, cat, isSelected, () {
                                      setModalState(() {
                                        selectedCategory = cat;
                                      });
                                    }),
                                  );
                                },
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                    SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.color.territoryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            if (selectedCategory != null) {
                              _updateSelection(chainIndex, selectedCategory!);
                            }
                          },
                          child: Text(
                            "Show ${NumberFormat.decimalPattern().format(context.read<FetchItemFromCategoryCubit>().state is FetchItemFromCategorySuccess ? (context.read<FetchItemFromCategoryCubit>().state as FetchItemFromCategorySuccess).total : 0)} Results",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            }),
          );
        }

        // --- CASE 2: Index 1 ONLY (Nested Parent + Child) ---
        // State variables preserved in this closure
        CategoryModel? selectedParent;
        CategoryModel? selectedChild;

        // Initialize from current chain
        if (_currentChain.length > chainIndex) {
          selectedParent = _currentChain[chainIndex];
        }
        if (_currentChain.length > chainIndex + 1) {
          selectedChild = _currentChain[chainIndex + 1];
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _chipFilterCubit),
            BlocProvider(create: (_) => FetchSubCategoriesCubit()),
          ],
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              // Auto-fetch children if parent is selected and child cubit is empty
              if (selectedParent != null) {
                final childCubit = context.read<FetchSubCategoriesCubit>();
                if (childCubit.state is FetchSubCategoriesInitial) {
                  if (selectedParent!.children != null &&
                      selectedParent!.children!.isNotEmpty) {
                    childCubit.emitSuccess(selectedParent!.children!);
                  } else {
                    childCubit.fetchSubCategories(
                        categoryId: selectedParent!.id!);
                  }
                }
              }

              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20))),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // ... (rest of header)
                      children: [
                        Text("type".translate(context),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.color.textDefaultColor)),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              selectedParent = null;
                              selectedChild = null;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            alignment: Alignment.centerRight,
                          ),
                          child: Text(
                            "reset".translate(context),
                            style: TextStyle(
                              color: context.color.territoryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      "chooseItemType".translate(context),
                      style: TextStyle(
                        fontSize: 14,
                        color: context.color.textDefaultColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// Parent Grid
                    BlocBuilder<FetchSubCategoriesCubit,
                        FetchSubCategoriesState>(
                      bloc: _chipFilterCubit,
                      builder: (context, state) {
                        if (state is FetchSubCategoriesInProgress) {
                          return SizedBox(
                            height: 50,
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return const CustomShimmer(
                                  height: 100,
                                  width: 100,
                                  borderRadius: 10,
                                );
                              },
                            ),
                          );
                        }
                        if (state is FetchSubCategoriesSuccess) {
                          if (state.categories.isEmpty)
                            return const Text("No options");
                          return SizedBox(
                              height: 100, // Taller for parent images
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: state.categories.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  CategoryModel cat = state.categories[index];
                                  bool isSelected =
                                      selectedParent?.id == cat.id;
                                  return SizedBox(
                                    width: 100,
                                    child: _buildCategoryCard(
                                        context, cat, isSelected, () {
                                      setModalState(() {
                                        if (selectedParent?.id != cat.id) {
                                          selectedParent = cat;
                                          selectedChild = null;
                                          // Fetch children immediately
                                          context
                                              .read<FetchSubCategoriesCubit>()
                                              .fetchSubCategories(
                                                  categoryId: cat.id!);
                                        }
                                      });
                                    }, showImage: true),
                                  );
                                },
                              ));
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    /// Child Grid
                    if (selectedParent != null) ...[
                      const SizedBox(height: 24),
                      BlocBuilder<FetchSubCategoriesCubit,
                          FetchSubCategoriesState>(
                        builder: (context, state) {
                          if (state is FetchSubCategoriesInProgress) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Categories",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: context.color.textDefaultColor),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 50,
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 5,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      return const CustomShimmer(
                                        height: 50,
                                        width: 110,
                                        borderRadius: 10,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                          if (state is FetchSubCategoriesSuccess) {
                            if (state.categories.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Categories",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: context.color.textDefaultColor),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                    height: 50,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: state.categories.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        CategoryModel cat =
                                            state.categories[index];
                                        bool isSelected =
                                            selectedChild?.id == cat.id;
                                        return SizedBox(
                                          width: 110,
                                          child: _buildCategoryCard(
                                              context, cat, isSelected, () {
                                            setModalState(() {
                                              selectedChild = cat;
                                            });
                                          }),
                                        );
                                      },
                                    )),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],

                    /// Button
                    const SizedBox(height: 20),
                    SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.color.territoryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            if (selectedParent != null) {
                              _updateSelection(chainIndex, selectedParent!);
                              if (selectedChild != null) {
                                _updateSelection(
                                    chainIndex + 1, selectedChild!);
                              }
                            }
                          },
                          child: Text(
                            "Show ${NumberFormat.decimalPattern().format(context.read<FetchItemFromCategoryCubit>().state is FetchItemFromCategorySuccess ? (context.read<FetchItemFromCategoryCubit>().state as FetchItemFromCategorySuccess).total : 0)} Results",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

///// bottom show agura buildcards
  Widget _buildCategoryCard(BuildContext context, CategoryModel cat,
      bool isSelected, VoidCallback onTap,
      {bool showImage = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? context.color.textDefaultColor
                : context.color.borderColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showImage && cat.url != null && cat.url!.isNotEmpty) ...[
              SizedBox(
                height: 50,
                width: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: UiUtils.imageType(cat.url!,
                      fit: BoxFit.cover,
                      color: isSelected ? null : null, // Optional tint
                      width: 50,
                      height: 50),
                ),
              ),
              const SizedBox(height: 5),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              child: Text(
                cat.name ?? "",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? context.color.textDefaultColor
                      : context.color.deactivateColor.withOpacity(0.8),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSelection(int chainIndex, CategoryModel newSelection) {
    final oldId =
        _currentChain.length > chainIndex ? _currentChain[chainIndex].id : -1;
    if (oldId == newSelection.id && !_isAllFieldsSelected) return;

    setState(() {
      _isAllFieldsSelected = false; // Reset All Fields flag

      // 1. Save History for the OLD item being replaced
      if (_currentChain.length > chainIndex) {
        int currentOldId = _currentChain[chainIndex].id!;
        if (_currentChain.length > chainIndex + 1) {
          _selectionHistory[currentOldId] =
              List.from(_currentChain.sublist(chainIndex + 1));
        }
      }

      // 2. Update the chain at this index
      if (_currentChain.length > chainIndex) {
        _currentChain[chainIndex] = newSelection;
      } else {
        _currentChain.add(newSelection);
      }

      // 3. Handle Child Slots
      // Only add placeholder if the new selection HAS subcategories
      if ((newSelection.subcategoriesCount ?? 0) > 0) {
        if (_currentChain.length > chainIndex + 1) {
          _currentChain[chainIndex + 1] = CategoryModel(
              id: -1, // Dummy ID
              name: "All", // Placeholder Name
              url: "",
              children: [],
              subcategoriesCount: 0);
        } else {
          _currentChain.add(CategoryModel(
              id: -1, // Dummy ID
              name: "All", // Placeholder Name
              url: "",
              children: [],
              subcategoriesCount: 0));
        }
      } else {
        // If no subcategories, truncate immediately after this item
        if (_currentChain.length > chainIndex + 1) {
          _currentChain.removeRange(chainIndex + 1, _currentChain.length);
        }
      }

      // Also ensure we clean up anything after the placeholder if we set one
      if ((newSelection.subcategoriesCount ?? 0) > 0) {
        if (_currentChain.length > chainIndex + 2) {
          _currentChain.removeRange(chainIndex + 2, _currentChain.length);
        }
      }

      // 4. Restore History for the NEW item (if we visited it before)
      if (_selectionHistory.containsKey(newSelection.id)) {
        // Apply history
        // First, define if we should overwrite the placeholder or append?
        // If history exists, it means we went deeper.
        // So we replace the placeholder with the history.

        // Remove placeholder first
        if (_currentChain.length > chainIndex + 1 &&
            _currentChain[chainIndex + 1].id == -1) {
          _currentChain.removeAt(chainIndex + 1);
        }
        _currentChain.addAll(_selectionHistory[newSelection.id]!);
      }

      // 5. Re-calculate categoryIds chain
      List<String> newIds = [];
      if (widget.categoryIds.isNotEmpty) newIds.add(widget.categoryIds[0]);

      for (var cat in _currentChain) {
        if (cat.id != -1) {
          newIds.add(cat.id.toString());
        }
      }
      _currentCategoryIds = newIds;

      // 6. Trigger API refresh
      int fetchId;
      if (_currentChain.last.id == -1) {
        fetchId = _currentChain.length > 1
            ? _currentChain[_currentChain.length - 2].id!
            : int.tryParse(widget.categoryId) ?? 0;
      } else {
        fetchId = _currentChain.last.id!;
      }

      context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
          categoryId: fetchId, search: searchController.text);
    });
  }

  //// etha dynamic scroll chips oda ui
  Widget _buildChip(
      {required String label, required bool isActive, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: context.color.primaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isActive
                  ? context.color.blackColor
                  : context
                      .color.borderColor), // Same border for now or customize
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: context.color.textDefaultColor,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                size: 16, color: context.color.textDefaultColor)
          ],
        ),
      ),
    );
  }

////////////////// show verified belwlo
  Widget _buildVerifiedToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Show verified properties first",
            style: TextStyle(
              color: context.color.textDefaultColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          /// 🍎 iOS style toggle
          CupertinoSwitch(
            value: _showVerifiedOnly,
            activeTrackColor: context.color.territoryColor, // green when ON
            onChanged: (val) {
              setState(() {
                _showVerifiedOnly = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget setSearchIcon() {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: UiUtils.getSvg(AppIcons.search,
            color: context.color.territoryColor));
  }

  Widget setSuffixIcon() {
    return GestureDetector(
      onTap: () {
        searchController.clear();
        isFocused = false; //set icon color to black back
        FocusScope.of(context).unfocus(); //dismiss keyboard
        setState(() {});
      },
      child: Icon(
        Icons.close_rounded,
        color: Theme.of(context).colorScheme.blackColor,
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return bodyWidget();
  }

/////////////////////////////
  //////////////////////////////
  //// ethu tha all categries short agi show agura screen
  Widget bodyWidget() {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.backgroundColor,
      ),
      child: PopScope(
        canPop: true,
        onPopInvoked: (isPop) {
          Constant.itemFilter = null;
        },
        child: Scaffold(
          backgroundColor: context.color.backgroundColor,
          appBar: UiUtils.buildAppBar(context,
              showBackButton: true,
              title: selectedcategoryName == ""
                  ? widget.categoryName
                  : selectedcategoryName),
          bottomNavigationBar: bottomWidget(),
          body: RefreshIndicator(
            backgroundColor: context.color.backgroundColor,
            onRefresh: () async {
              // Debug log to check if onRefresh is triggered

              searchbody = {};
              Constant.itemFilter = null;

              context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
                    categoryId: int.parse(widget.categoryId),
                    search: "",
                    forceRefresh: true, // [FIX] Force refresh
                  );
            },
            color: context.color.territoryColor,
            child: Column(
              children: [
                SizedBox(
                  height: 8,
                ),
                SizedBox(
                  height: 8,
                ),
                searchBarWidget(),
                SizedBox(
                  height: 8,
                ),
                _buildFilterChips(),
                _buildVerifiedToggle(),
                SizedBox(
                  height: 8,
                ),
                Expanded(child: fetchItems()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void getFilterValue(ItemFilterModel model) {
    // When "regular" filters return, we want to Keep our custom fields if they are not part of the standard filter model?
    // ItemFilterModel now has customFields.
    // So if the filter screen returns custom fields, we use them.
    // If not, we might lose them? The FilterScreen DOES handle custom fields if implemented there.
    // But assuming FilterScreen is for static filters (Price, Loc, etc), we should merge or preserve.

    // Actually, usually FilterScreen returns a NEW model.
    // If we want to preserve our local custom fields:
    filter = model.copyWith(customFields: {
      ..._selectedCustomFields,
      ...(model.customFields ?? {})
    });

    setState(() {});
  }

  Container bottomWidget() {
    return Container(
      color: context.color.secondaryColor,
      padding: const EdgeInsets.only(top: 3, bottom: 15),
      height: 70,
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: filterByWidget(),
          ),
          SizedBox(
            height: 40,
            child: VerticalDivider(
              color: context.color.borderColor.darken(50),
              thickness: 1,
            ),
          ),
          Expanded(
            child: sortByWidget(),
          ),
        ],
      ),
    );
  }

  Widget filterByWidget() {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.filterScreen,
          arguments: {
            "update": getFilterValue,
            "from": "itemsList",
            "categoryIds": widget.categoryIds
          },
        ).then((value) {
          if (value == true && filter != null) {
            ItemFilterModel updatedFilter =
                filter!.copyWith(categoryId: widget.categoryId);

            context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
                  categoryId: int.parse(widget.categoryId),
                  search: searchController.text,
                  filter: updatedFilter,
                );
          }
          setState(() {});
        });
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 16, // smaller icon height
              width: 16, // smaller icon width
              child: UiUtils.getSvg(
                AppIcons.filterByIcon,
                color: context.color.textDefaultColor,
              ),
            ),
            const SizedBox(width: 7),
            Text("filterTitle".translate(context)),
          ],
        ),
      ),
    );
  }

  Widget sortByWidget() {
    return InkWell(
      onTap: showSortByBottomSheet,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UiUtils.getSvg(AppIcons.sortByIcon,
                color: context.color.textDefaultColor),
            const SizedBox(width: 7),
            Text("sortBy".translate(context)),
          ],
        ),
      ),
    );
  }

  void showSortByBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: context.color.borderColor,
                    ),
                    height: 6,
                    width: 60,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 17, horizontal: 20),
                child: Text(
                  'sortBy'.translate(context),
                  textAlign: TextAlign.start,
                ).bold(weight: FontWeight.bold).size(context.font.large),
              ),

              Divider(height: 1), // Add some space between title and options
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Text('default'.translate(context)),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<FetchItemFromCategoryCubit>()
                      .fetchItemFromCategory(
                          categoryId: int.parse(
                            widget.categoryId,
                          ),
                          search: searchController.text.toString(),
                          filter: filter,
                          sortBy: null);

                  setState(() {
                    sortBy = null;
                    print("isfocus$isFocused");

                    FocusManager.instance.primaryFocus?.unfocus();
                  });

                  // Handle option 1 selection
                },
              ),
              Divider(height: 1), // Divider between option 1 and option 2
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Text('newToOld'.translate(context)),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<FetchItemFromCategoryCubit>()
                      .fetchItemFromCategory(
                          categoryId: int.parse(
                            widget.categoryId,
                          ),
                          search: searchController.text.toString(),
                          filter: filter,
                          sortBy: "new-to-old");
                  setState(() {
                    sortBy = "new-to-old";
                    FocusManager.instance.primaryFocus?.unfocus();
                  });
                },
              ),
              Divider(height: 1), // Divider between option 2 and option 3
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Text('oldToNew'.translate(context)),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<FetchItemFromCategoryCubit>()
                      .fetchItemFromCategory(
                          categoryId: int.parse(
                            widget.categoryId,
                          ),
                          search: searchController.text.toString(),
                          filter: filter,
                          sortBy: "old-to-new");
                  setState(() {
                    sortBy = "old-to-new";
                    FocusManager.instance.primaryFocus?.unfocus();
                  });
                },
              ),
              Divider(height: 1), // Divider between option 3 and option 4
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Text('priceHighToLow'.translate(context)),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<FetchItemFromCategoryCubit>()
                      .fetchItemFromCategory(
                          categoryId: int.parse(
                            widget.categoryId,
                          ),
                          search: searchController.text.toString(),
                          filter: filter,
                          sortBy: "price-high-to-low");
                  setState(() {
                    sortBy = "price-high-to-low";
                    FocusManager.instance.primaryFocus?.unfocus();
                  });
                },
              ),
              Divider(height: 1), // Divider between option 4 and option 5
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Text('priceLowToHigh'.translate(context)),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<FetchItemFromCategoryCubit>()
                      .fetchItemFromCategory(
                          categoryId: int.parse(
                            widget.categoryId,
                          ),
                          search: searchController.text.toString(),
                          filter: filter,
                          sortBy: "price-low-to-high");
                  setState(() {
                    sortBy = "price-low-to-high";
                    FocusManager.instance.primaryFocus?.unfocus();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget fetchItems() {
    return BlocBuilder<FetchItemFromCategoryCubit, FetchItemFromCategoryState>(
        builder: (context, state) {
      if (state is FetchItemFromCategoryInProgress) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          itemCount: 10,
          itemBuilder: (context, index) {
            return buildItemsShimmer(context);
          },
        );
      }

      if (state is FetchItemFromCategoryFailure) {
        print("ITEM LIST ERROR: ${state.errorMessage}");
        return const Center(
          child: SomethingWentWrong(),
        );
      }
      if (state is FetchItemFromCategorySuccess) {
        if (state.itemModel.isEmpty) {
          return Center(
            child: NoDataFound(
              onTap: () {
                context
                    .read<FetchItemFromCategoryCubit>()
                    .fetchItemFromCategory(
                        categoryId: int.parse(
                          widget.categoryId,
                        ),
                        search: searchController.text.toString());
              },
            ),
          );
        }
        List<ItemModel> displayItems = state.itemModel;
        if (_showVerifiedOnly) {
          displayItems =
              displayItems.where((item) => item.user?.isVerified == 1).toList();
        }

        if (displayItems.isEmpty &&
            _showVerifiedOnly &&
            state.itemModel.isNotEmpty) {
          // Show message if filter hides everything? Or just "No Data Found" (reusing existing widget might be confusing if it triggers refetch)
          // For now, let's just let it show empty or maybe a specific message.
          // Re-using NoDataFound is okay, but user might think there are NO items at all.
          // Let's stick to showing empty list or the standard NoDataFound logic if the result is truly empty.
        }

        if (displayItems.isEmpty) {
          return Center(
            child: NoDataFound(
              onTap: () {
                // If empty due to filter, maybe just reset filter?
                // But for now, standard retry.
                context
                    .read<FetchItemFromCategoryCubit>()
                    .fetchItemFromCategory(
                        categoryId: int.parse(
                          widget.categoryId,
                        ),
                        search: searchController.text.toString());
              },
            ),
          );
        }

        return Column(
          children: [
            Expanded(child: mainChildren(displayItems)
                /* isList
                  ? ListView.builder(
                      shrinkWrap: true,
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 3),
                      itemCount: calculateItemCount(state.itemModel.length),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        if ((index + 1) % 4 == 0) {
                          return NativeAdWidget(type: TemplateType.medium);
                        }

                        int itemIndex = index - (index ~/ 4);
                        ItemModel item = state.itemModel[itemIndex];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.adDetailsScreen,
                              arguments: {
                                'model': item,
                              },
                            );
                          },
                          child: ItemHorizontalCard(
                            item: item,
                          ),
                        );
                      },
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                              crossAxisCount: 2,
                              height: MediaQuery.of(context).size.height /
                                  3.5.rh(context),
                              mainAxisSpacing: 7,
                              crossAxisSpacing: 10),
                      itemCount: calculateItemCount(state.itemModel.length),
                      itemBuilder: (context, index) {
                        if ((index + 1) % 4 == 0) {
                          return NativeAdWidget(type: TemplateType.medium);
                        }

                        int itemIndex = index - (index ~/ 4);
                        ItemModel item = state.itemModel[itemIndex];

                        return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                Routes.adDetailsScreen,
                                arguments: {
                                  'model': item,
                                },
                              );
                            },
                            child: ItemCard(
                              item: item,
                            ));
                      },
                    ),*/
                ),
          ],
        );
      }
      return Container();
    });
  }

  ///
  ///  DYNAMIC FILTER EDIT LOGIC
  ///

  void _onFilterChipTap(String filterName) async {
    // 1. Check for Price or Area Size (Static/Special Handling)
    if (filterName.toLowerCase().contains("price") ||
        filterName.toLowerCase().contains("budget")) {
      _showRangeFilterSheet(
        title: "budgetLbl".translate(context),
        min: 0,
        max: 1000000, // Default Max, maybe fetch from API?
        currentMin: double.tryParse(filter?.minPrice ?? "0"),
        currentMax: double.tryParse(filter?.maxPrice ?? "1000000"),
        onApply: (min, max) {
          setState(() {
            // Update Filter Model
            filter = filter?.copyWith(
                    minPrice: min.toInt().toString(),
                    maxPrice: max.toInt().toString()) ??
                ItemFilterModel(
                    minPrice: min.toInt().toString(),
                    maxPrice: max.toInt().toString(),
                    country: HiveUtils.getCountryName() ?? "",
                    city: HiveUtils.getCityName() ?? "",
                    categoryId: widget.categoryId);

            // Trigger Fetch
            _fetchItemsWithFilter(); // Refactored fetch call
          });
        },
      );
      return;
    }

    // Check for "Area"
    // Check for "Area" or "Size" (Dynamic)
    if (filterName.toLowerCase().contains("area") ||
        filterName.toLowerCase().contains("size")) {
      double? initialMin;
      double? initialMax;

      // Try to parse existing value from _min / _max keys first property style
      String minKey = "${filterName}_min";
      String maxKey = "${filterName}_max";

      if (_selectedCustomFields.containsKey(minKey)) {
        initialMin =
            double.tryParse(_selectedCustomFields[minKey]?.toString() ?? "");
      }
      if (_selectedCustomFields.containsKey(maxKey)) {
        initialMax =
            double.tryParse(_selectedCustomFields[maxKey]?.toString() ?? "");
      }

      // Fallback: Check "min-max" string format if stored that way
      if (initialMin == null && _selectedCustomFields.containsKey(filterName)) {
        var val = _selectedCustomFields[filterName];
        if (val is List && val.isNotEmpty) {
          String rangeStr = val[0].toString(); // "100-500"
          List<String> parts = rangeStr.split("-");
          if (parts.length == 2) {
            initialMin = double.tryParse(parts[0]);
            initialMax = double.tryParse(parts[1]);
          }
        }
      }

      _showRangeFilterSheet(
          title: filterName, // Use dynamic name
          min: 0,
          max: 5000,
          currentMin: initialMin,
          currentMax: initialMax,
          onApply: (min, max) {
            setState(() {
              // Store using _min / _max keys for PropertyScreen compatibility
              _selectedCustomFields["${filterName}_min"] =
                  min.toInt().toString();
              _selectedCustomFields["${filterName}_max"] =
                  max.toInt().toString();

              // Clear generic key if mixed
              _selectedCustomFields.remove(filterName);

              // Update Model
              filter = filter?.copyWith(customFields: _selectedCustomFields);
              _fetchItemsWithFilter(); // Trigger Fetch
            });
          });
      return;
    }

    // 2. Find the filter definition (CategoryFilterModel) in the chain
    CategoryFilterModel? filterDef;

    // Search from deepest to root, as deeper definitions might override?
    // Or just search all. usually filters are distributed.
    for (var cat in _currentChain) {
      if (cat.filters != null) {
        for (var f in cat.filters!) {
          if (f.name == filterName) {
            filterDef = f;
            break;
          }
        }
      }
      if (filterDef != null) break;
    }

    if (filterDef == null) {
      // Logic for fallback or if we want to show generic even if not defined (e.g. Price if manual)
      print("Filter definition for $filterName not found in chain.");
      return;
    }

    // 3. Open appropriate editor
    // Check for "Amenities" (Case insensitive)
    if (filterName.toLowerCase().contains("amenit") ||
        filterName.toLowerCase() == "features") {
      // Use AmenitiesFilterScreen
      // Current selection
      List<dynamic> currentSelection = [];
      var raw = _selectedCustomFields[filterName];
      if (raw is List)
        currentSelection = List.from(raw);
      else if (raw != null) currentSelection = [raw];

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AmenitiesFilterScreen(
            allAmenities: filterDef!.values ?? [],
            selectedAmenities: currentSelection,
          ),
        ),
      );

      if (result != null && result is List) {
        _updateCustomFilter(filterName, result);
      }
    } else {
      // Generic Sheet for other filters
      _showGenericFilterSheet(filterDef);
    }
  }

  void _fetchItemsWithFilter() {
    context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
        categoryId: int.parse(widget.categoryId),
        search: searchController.text,
        filter: filter ??
            ItemFilterModel(
              country: HiveUtils.getCountryName() ?? "",
              areaId: HiveUtils.getAreaId() != null
                  ? int.parse(HiveUtils.getAreaId().toString())
                  : null,
              city: HiveUtils.getCityName() ?? "",
              state: HiveUtils.getStateName() ?? "",
              categoryId: widget.categoryId,
              radius: HiveUtils.getNearbyRadius() ?? null,
              latitude: HiveUtils.getLatitude() ?? null,
              customFields: _selectedCustomFields,
            ));
  }

  void _showRangeFilterSheet({
    required String title,
    required double min,
    required double max,
    double? currentMin,
    double? currentMax,
    required Function(double min, double max) onApply,
  }) {
    double localMin = currentMin ?? min;
    double localMax = currentMax ?? max;
    if (localMin < min) localMin = min;
    if (localMax > max) localMax = max;

    // Safety check
    if (localMin > localMax) {
      localMin = min;
      localMax = max;
    }

    TextEditingController minCtrl =
        TextEditingController(text: localMin.toStringAsFixed(0));
    TextEditingController maxCtrl =
        TextEditingController(text: localMax.toStringAsFixed(0));

    String suffix = title.toLowerCase().contains("area") ||
            title.toLowerCase().contains("size")
        ? "Sqft"
        : "AED";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.color.textDefaultColor)),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          localMin = min;
                          localMax = max;
                          minCtrl.text = min.toStringAsFixed(0);
                          maxCtrl.text = max.toStringAsFixed(0);
                        });
                      },
                      child: Text("Reset",
                          style: TextStyle(
                              color: context.color.textDefaultColor
                                  .withOpacity(0.6))),
                    )
                  ],
                ),
                Text("Set your desired ${title.toLowerCase()}",
                    style: TextStyle(
                        color: context.color.textDefaultColor.withOpacity(0.6),
                        fontSize: 13)),

                const SizedBox(height: 24),

                // Range Slider
                RangeSlider(
                  activeColor: context.color.territoryColor,
                  inactiveColor: context.color.territoryColor.withOpacity(0.3),
                  values: RangeValues(
                    (localMin < localMax ? localMin : localMax).clamp(min, max),
                    (localMin > localMax ? localMin : localMax).clamp(min, max),
                  ),
                  min: min,
                  max: max,
                  onChanged: (RangeValues values) {
                    setSheetState(() {
                      localMin = values.start;
                      localMax = values.end;
                      minCtrl.text = localMin.toStringAsFixed(0);
                      maxCtrl.text = localMax.toStringAsFixed(0);
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Inputs
                Row(
                  children: [
                    Expanded(
                        child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.color.borderColor),
                      ),
                      child: TextField(
                        controller: minCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: context.color.textDefaultColor),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Min",
                          hintStyle: TextStyle(
                              color: context.color.textDefaultColor
                                  .withOpacity(0.5)),
                          suffixText: suffix, // Use dynamic suffix
                          suffixStyle:
                              TextStyle(color: context.color.textDefaultColor),
                        ),
                        onChanged: (val) {
                          double? v = double.tryParse(val);
                          if (v != null) {
                            setSheetState(() {
                              localMin = v;
                            });
                          }
                        },
                      ),
                    )),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text("to",
                            style: TextStyle(
                                color: context.color.textDefaultColor))),
                    Expanded(
                        child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.color.borderColor),
                      ),
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: context.color.textDefaultColor),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Max",
                          hintStyle: TextStyle(
                              color: context.color.textDefaultColor
                                  .withOpacity(0.5)),
                          suffixText: suffix, // Use dynamic suffix
                          suffixStyle: TextStyle(
                              color:
                                  context.color.textDefaultColor), // Max input
                        ),
                        onChanged: (val) {
                          double? v = double.tryParse(val);
                          if (v != null) {
                            setSheetState(() {
                              localMax = v;
                            });
                          }
                        },
                      ),
                    )),
                  ],
                ),

                const SizedBox(height: 24),

                // Show Results Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.color.territoryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onApply(localMin, localMax);
                    },
                    child: Text(
                      "Show Results", // Maybe update with count implicitly?
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showGenericFilterSheet(CategoryFilterModel filterDef) {
    List<dynamic> options = filterDef.values ?? [];
    List<dynamic> currentSelection = [];
    var raw = _selectedCustomFields[filterDef.name];
    if (raw is List)
      currentSelection = List.from(raw);
    else if (raw != null) currentSelection = [raw];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      filterDef.name ?? "Filter",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.color.textDefaultColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: context.color.textDefaultColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      var option = options[index];
                      // Single Select: Check if this option is the one selected
                      // currentSelection should have max 1 item
                      // bool isSelected = currentSelection.isNotEmpty && currentSelection.first == option; // Unused

                      return RadioListTile(
                        value: option,
                        groupValue: currentSelection.isNotEmpty
                            ? currentSelection.first
                            : null,
                        title: Text(option.toString(),
                            style: TextStyle(
                                color: context.color.textDefaultColor)),
                        activeColor: context.color.territoryColor,
                        onChanged: (val) {
                          setSheetState(() {
                            if (val != null) {
                              currentSelection.clear();
                              currentSelection.add(val);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.color.territoryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, currentSelection);
                    },
                    child: const Text(
                      "Apply",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    ).then((result) {
      if (result != null && result is List) {
        _updateCustomFilter(filterDef.name!, result);
      }
    });
  }

  void _updateCustomFilter(String key, List<dynamic> values) {
    setState(() {
      if (values.isEmpty) {
        _selectedCustomFields.remove(key);
      } else {
        _selectedCustomFields[key] = values;
      }

      // Update Filter Model
      if (filter != null) {
        filter = filter!.copyWith(customFields: _selectedCustomFields);
      } else {
        filter = ItemFilterModel(
          country: HiveUtils.getCountryName() ?? "",
          areaId: HiveUtils.getAreaId() != null
              ? int.parse(HiveUtils.getAreaId().toString())
              : null,
          city: HiveUtils.getCityName() ?? "",
          state: HiveUtils.getStateName() ?? "",
          categoryId: widget.categoryId,
          radius: HiveUtils.getNearbyRadius() ?? null,
          latitude: HiveUtils.getLatitude() ?? null,
          longitude: HiveUtils.getLongitude() ?? null,
          customFields: _selectedCustomFields,
        );
      }

      _fetchItemsWithFilter();
    });
  }

  void _navigateToDetails(BuildContext context, ItemModel item) {
    Navigator.pushNamed(
      context,
      Routes.adDetailsScreen,
      arguments: {'model': item},
    );
  }

  Widget mainChildren(List<ItemModel> items) {
    List<Widget> slivers = [];
    int gridCount = Constant.nativeAdsAfterItemNumber;
    int total = items.length;

    for (int i = 0; i < total; i += gridCount) {
      if (isList) {
        slivers.add(_buildSliverListSection(
            context, i, min(gridCount, total - i), items));
      } else {
        slivers.add(_buildSliverGridSection(
            context, i, min(gridCount, total - i), items));
      }

      int remainingItems = total - i - gridCount;
      if (remainingItems > 0) {
        slivers.add(SliverToBoxAdapter(
            child: NativeAdWidget(type: TemplateType.medium)));
      }
    }

    var state = context.read<FetchItemFromCategoryCubit>().state;
    if (state is FetchItemFromCategorySuccess && state.isLoadingMore) {
      slivers.add(SliverToBoxAdapter(child: UiUtils.progress()));
    }

    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      slivers: slivers,
    );
  }

  Widget _buildSliverListSection(BuildContext context, int startIndex,
      int itemCount, List<ItemModel> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          ItemModel item = items[startIndex + index];
          return GestureDetector(
            onTap: () => _navigateToDetails(context, item),
            child: ItemHorizontalCard(item: item),
          );
        },
        childCount: itemCount,
      ),
    );
  }

  Widget _buildSliverGridSection(BuildContext context, int startIndex,
      int itemCount, List<ItemModel> items) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
          crossAxisCount: 2,
          height: MediaQuery.of(context).size.height / 3.9.rh(context),
          mainAxisSpacing: 7,
          crossAxisSpacing: 5),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          ItemModel item = items[startIndex + index];
          return GestureDetector(
            onTap: () => _navigateToDetails(context, item),
            child: ItemCard(item: item, radius: 5),
          );
        },
        childCount: itemCount,
      ),
    );
  }

  Widget buildItemsShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 120.rh(context),
        decoration: BoxDecoration(
            border: Border.all(width: 1.5, color: context.color.borderColor),
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            CustomShimmer(
              height: 120.rh(context),
              width: 100.rw(context),
            ),
            SizedBox(
              width: 10.rw(context),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomShimmer(
                  width: 100.rw(context),
                  height: 10,
                  borderRadius: 7,
                ),
                CustomShimmer(
                  width: 150.rw(context),
                  height: 10,
                  borderRadius: 7,
                ),
                CustomShimmer(
                  width: 120.rw(context),
                  height: 10,
                  borderRadius: 7,
                ),
                CustomShimmer(
                  width: 80.rw(context),
                  height: 10,
                  borderRadius: 7,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
