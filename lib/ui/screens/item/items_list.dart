import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:math';

import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/ui/screens/widgets/amenities_filter_screen.dart';
import 'package:Ebozor/data/cubits/item/fetch_item_from_category_cubit.dart';
import 'package:Ebozor/data/cubits/item/fetch_item_count_cubit.dart'; // [New]
import 'package:Ebozor/data/repositories/item/item_repository.dart'; // [New]
import 'package:Ebozor/data/cubits/category/fetch_sub_categories_cubit.dart';
import 'package:Ebozor/data/model/category_model.dart';

import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
  late List<CategoryModel>
      _initialChain; // [NEW] To support Reset to initial state
  late final FetchSubCategoriesCubit _chipFilterCubit;
  List<String> _currentCategoryIds = [];
  Map<String, dynamic> _selectedCustomFields = {};

  // [NEW] Item Count Cubit
  late final FetchItemCountCubit _fetchItemCountCubit;

  bool _showVerifiedOnly = false;

  @override
  void initState() {
    super.initState();
    _chipFilterCubit = FetchSubCategoriesCubit();
    // [NEW]
    _fetchItemCountCubit = FetchItemCountCubit(ItemRepository());
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

    // Fallback: Ensure the current category is part of the chain (as the last item)
    // This handles deep links or navigation where chain might only contain parents.
    int currentId = int.tryParse(widget.categoryId) ?? 0;
    if (_currentChain.isEmpty) {
      _currentChain.add(CategoryModel(
          id: currentId,
          name: widget.categoryName,
          children: [],
          subcategoriesCount: 0));
    } else {
      // Check if the last item is the current category
      if (_currentChain.last.id != currentId && currentId != 0) {
        _currentChain.add(CategoryModel(
            id: currentId,
            name: widget.categoryName,
            children: [],
            subcategoriesCount: 0));
      }
    }

    // [NEW] Capture the initial state for Reset functionality
    _initialChain = List.from(_currentChain);

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
    _fetchItemCountCubit.close(); // [New]
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
          search: searchController.text,
          filter: ItemFilterModel(
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
          ));
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
  }

  // Helper function to create location filter
  ItemFilterModel _createLocationFilter({String? minPrice, String? maxPrice, Map<String, dynamic>? customFields}) {
    return ItemFilterModel(
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
      minPrice: minPrice,
      maxPrice: maxPrice,
      customFields: customFields,
    );
  }

  // [NEW] Helper to fetch count for dynamic filter sheet
  // [NEW] Helper to fetch count for dynamic filter sheet
  void _fetchCount(
      {int? overrideCategoryId, int? overrideMinPrice, int? overrideMaxPrice}) {
    // Extract Min/Max Price from custom fields or filter params
    int? minPrice = overrideMinPrice;
    int? maxPrice = overrideMaxPrice;
    String? postedSince;

    // Check specific Price keys as per PropertyFilterScreen logic (ONLY if not overridden)
    if (minPrice == null && maxPrice == null) {
      for (var key in _selectedCustomFields.keys) {
        String lowerKey = key.toLowerCase();
        if (lowerKey.contains('price') || lowerKey.contains('budget')) {
          if (lowerKey.endsWith('_min')) {
            minPrice = int.tryParse(_selectedCustomFields[key].toString());
          } else if (lowerKey.endsWith('_max')) {
            maxPrice = int.tryParse(_selectedCustomFields[key].toString());
          }
        }
      }

      // Also check generic filter object if it was initialized
      if (minPrice == null && filter?.minPrice != null) {
        minPrice = int.tryParse(filter!.minPrice.toString());
      }
      if (maxPrice == null && filter?.maxPrice != null) {
        maxPrice = int.tryParse(filter!.maxPrice.toString());
      }
    }

    // Use override if present, else fall back to current chain or widget.categoryId
    int targetId = overrideCategoryId ??
        (_currentChain.isNotEmpty
            ? _currentChain.last.id!
            : (int.tryParse(widget.categoryId) ?? 0));

    // Ensure we don't send 0 if something went wrong
    if (targetId == 0 && widget.categoryId.isNotEmpty) {
      targetId = int.tryParse(widget.categoryId) ?? 0;
    }

    // Logic: User requested that when switching categories (e.g. Rent to Sale),
    // we should KEEP all existing filters (Price, Custom Fields like Bedrooms)
    // and ONLY change the Category ID.
    _fetchItemCountCubit.fetchItemCount(
      categoryId: targetId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      postedSince: postedSince,
      filter: ItemFilterModel(customFields: _selectedCustomFields),
      search: searchController.text,
      city: HiveUtils.getCityName(),
      state: HiveUtils.getStateName(),
      country: HiveUtils.getCountryName(),
      latitude: HiveUtils.getLatitude(),
      longitude: HiveUtils.getLongitude(),
    );
  }

  Widget searchBarWidget() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          /// 🔍 SEARCH FIELD
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: context.color.borderColor.darken(30),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: context.color.borderColor.darken(30),
                ),
                color: !isList ? Colors.transparent : Colors.transparent,
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: context.color.borderColor.darken(30),
                ),
                color: isList ? Colors.transparent : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Image.asset(
                  "assets/itemlistviewimage.png",
                  width: 20,
                  height: 20,
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

      // [Reset Logic] Revert to the initial category chain
      _currentChain = List.from(_initialChain);
      // Ensure category IDs list matches the initial leaf node
      if (_currentChain.isNotEmpty) {
        _currentCategoryIds = [_currentChain.last.id.toString()];
      } else {
        _currentCategoryIds = [widget.categoryId];
      }

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
      color: Colors.transparent,
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
          search: searchController.text,
          filter: _createLocationFilter());
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
          categoryId: targetId,
          search: searchController.text,
          filter: _createLocationFilter());
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
        // --- CASE 1: Simple Text Only (For Index 0 and Index > 1) ---
        if (chainIndex != 1) {
          // [FIX] Ensure selectedCategory is initialized correctly for Index 0
          CategoryModel? selectedCategory;
          if (_currentChain.length > chainIndex) {
            selectedCategory = _currentChain[chainIndex];
            // Initial fetch count for the currently selected category
            _fetchCount(overrideCategoryId: selectedCategory?.id);
          } else {
            // If no category selected yet (e.g. index 0 but empty chain?), fetch for root/default logic
            _fetchCount(overrideCategoryId: int.tryParse(parentId) ?? 0);
          }

          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: _chipFilterCubit),
              BlocProvider.value(value: _fetchItemCountCubit), // [NEW]
            ],
            child: StatefulBuilder(builder: (context, setModalState) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height *
                      0.5, // Increase height slightly
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
                              return Text(
                                "noOptionsAvailable".translate(context),
                                style: TextStyle(
                                  color: context.color.textDefaultColor,
                                  fontSize: 14,
                                ),
                              );

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
                                      // [NEW] Trigger fetch count logic
                                      _fetchCount(overrideCategoryId: cat.id);
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
                            print("**** SHOW RESULT BUTTON PRESSED (CASE 1)");
                            print(
                                "**** selectedCategory: ${selectedCategory?.id} - ${selectedCategory?.name}");

                            Navigator.pop(context);
                            if (selectedCategory != null) {
                              _updateSelection(chainIndex, selectedCategory!);

                              // [NEW] Force API call with selected category ID
                              int fetchId = selectedCategory!.id!;
                              print(
                                  "**** SHOW RESULT - FORCING API CALL WITH SELECTED ID: $fetchId");
                              context
                                  .read<FetchItemFromCategoryCubit>()
                                  .fetchItemFromCategory(
                                      categoryId: fetchId,
                                      search: searchController.text,
                                      forceRefresh: true);
                              print("**** API CALL EXECUTED (CASE 1)");
                            } else {
                              print("**** ERROR: selectedCategory is null!");
                            }
                          },
                          child: BlocBuilder<FetchItemCountCubit,
                              FetchItemCountState>(builder: (context, state) {
                            String buttonText = "showResult".translate(context);
                            if (state is FetchItemCountInProgress) {
                              buttonText = "calculating".translate(context);
                            } else if (state is FetchItemCountSuccess) {
                              buttonText = "Show ${state.count} Results";
                            }
                            return Text(
                              buttonText,
                              style: TextStyle(
                                color: context.color.buttonColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }),
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
          // Initial fetch count for parent if present
          _fetchCount(overrideCategoryId: selectedParent?.id);
        }
        // [DISABLED] Auto-selection of child - user must manually select
        // if (_currentChain.length > chainIndex + 1) {
        //   selectedChild = _currentChain[chainIndex + 1];
        //   // Initial fetch count for child if present (overrides parent)
        //   _fetchCount(overrideCategoryId: selectedChild?.id);
        // }

        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _chipFilterCubit),
            BlocProvider(create: (_) => FetchSubCategoriesCubit()),
            BlocProvider.value(value: _fetchItemCountCubit), // [NEW]
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
                            // [NEW] Reset count to base
                            _fetchCount(
                                overrideCategoryId:
                                    int.tryParse(widget.categoryId) ?? 0);
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
                            return Text(
                              "noOptionsAvailable".translate(context),
                              style: TextStyle(
                                color: context.color.textDefaultColor,
                                fontSize: 14,
                              ),
                            );
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
                                        // [MODIFIED] Always reset child when parent is selected
                                        // This ensures subcategories are deselected when same parent is clicked
                                        print(
                                            "**** PARENT CLICKED: ${cat.id} - ${cat.name}");
                                        print(
                                            "**** BEFORE - selectedParent: ${selectedParent?.id}, selectedChild: ${selectedChild?.id}");
                                        selectedParent = cat;
                                        selectedChild = null;
                                        print(
                                            "**** AFTER - selectedParent: ${selectedParent?.id}, selectedChild: ${selectedChild?.id}");
                                        // Fetch children immediately
                                        context
                                            .read<FetchSubCategoriesCubit>()
                                            .fetchSubCategories(
                                                categoryId: cat.id!);
                                      });
                                      // [NEW] Update count for parent
                                      _fetchCount(overrideCategoryId: cat.id);
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
                                  "categories".translate(context),
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
                                  "categories".translate(context),
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
                                              print(
                                                  "**** CHILD CLICKED: ${cat.id} - ${cat.name}");
                                              selectedChild = cat;
                                              print(
                                                  "**** selectedChild is now: ${selectedChild?.id}");
                                            });
                                            // [NEW] Update count for child
                                            _fetchCount(
                                                overrideCategoryId: cat.id);
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
                            print("**** SHOW RESULT BUTTON PRESSED");
                            print(
                                "**** selectedParent: ${selectedParent?.id} - ${selectedParent?.name}");
                            print(
                                "**** selectedChild: ${selectedChild?.id} - ${selectedChild?.name}");

                            if (selectedParent != null) {
                              // [MODIFIED] Update state BEFORE closing bottom sheet
                              _updateSelection(chainIndex, selectedParent!);
                              if (selectedChild != null) {
                                _updateSelection(
                                    chainIndex + 1, selectedChild!);
                              } else {
                                // [NEW] Remove child from chain if not selected
                                // This ensures dynamic chip shows "All" instead of old subcategory
                                setState(() {
                                  if (_currentChain.length > chainIndex + 1) {
                                    _currentChain.removeRange(
                                        chainIndex + 1, _currentChain.length);
                                    print(
                                        "**** REMOVED CHILD FROM CHAIN - Chain length now: ${_currentChain.length}");
                                  }
                                });
                              }

                              // [NEW] Force API call with bottom sheet selected category ID
                              // Use selectedChild if available, otherwise selectedParent
                              int fetchId =
                                  selectedChild?.id ?? selectedParent!.id!;
                              print(
                                  "**** SHOW RESULT - FORCING API CALL WITH BOTTOM SHEET SELECTED ID: $fetchId");
                              context
                                  .read<FetchItemFromCategoryCubit>()
                                  .fetchItemFromCategory(
                                      categoryId: fetchId,
                                      search: searchController.text,
                                      forceRefresh: true);
                              print("**** API CALL EXECUTED");

                              // Close bottom sheet AFTER state updates
                              Navigator.pop(context);
                            } else {
                              print("**** ERROR: selectedParent is null!");
                              Navigator.pop(context);
                            }
                          },
                          child: BlocBuilder<FetchItemCountCubit,
                              FetchItemCountState>(builder: (context, state) {
                            String buttonText = "showResult".translate(context);
                            if (state is FetchItemCountInProgress) {
                              buttonText = "calculating".translate(context);
                            } else if (state is FetchItemCountSuccess) {
                              buttonText = "Show ${state.count} Results";
                            }
                            return Text(
                              buttonText,
                              style: TextStyle(
                                color: context.color.buttonColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }),
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
                      : context.color.textDefaultColor.withOpacity(0.7),
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

  // [New] Helper to get the correct ID for fetching items
  int _getCurrentFetchId() {
    if (_currentChain.isEmpty) {
      return int.tryParse(widget.categoryId) ?? 0;
    }
    // If last item is placeholder (-1), use the parent
    if (_currentChain.last.id == -1) {
      return _currentChain.length > 1
          ? _currentChain[_currentChain.length - 2].id!
          : int.tryParse(widget.categoryId) ?? 0;
    }
    return _currentChain.last.id!;
  }

  void _updateSelection(int chainIndex, CategoryModel newSelection) async {
    final oldId =
        _currentChain.length > chainIndex ? _currentChain[chainIndex].id : -1;
    if (oldId == newSelection.id && !_isAllFieldsSelected) return;

    // [New] Smart Migration Logic: Capture potential child to restore

    setState(() {
      _isAllFieldsSelected = false; // Reset All Fields flag

      // [Modified] Always clear filters if ANY category in the chain changes
      // This ensures we don't carry over invalid custom fields or filters to a new category.
      _selectedCustomFields.clear();
      filter = null;

      // 1. Save History for the OLD item being replaced
      // [Modified] We no longer want to restore history, so we can skip saving it,
      // or just save it but NEVER restore it. For now, let's just leave saving (useless)
      // but DISABLE restoration below.
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
        // [Modified] Instead of dummy placeholder immediately, we might restore
        if (_currentChain.length > chainIndex + 1) {
          // Keep placeholder structure but might replace it soon
          _currentChain[chainIndex + 1] = CategoryModel(
              id: -1,
              name: "All",
              url: "",
              children: [],
              subcategoriesCount: 0);
        } else {
          _currentChain.add(CategoryModel(
              id: -1,
              name: "All",
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

      // Clear deeper levels if we just reset
      if (_currentChain.length > chainIndex + 2) {
        _currentChain.removeRange(chainIndex + 2, _currentChain.length);
      }

      // 4. Restore History for the NEW item (if we visited it before)
      // [Modified] DISABLE History Restoration as per user request
      /* if (_selectionHistory.containsKey(newSelection.id)) {
        if (_currentChain.length > chainIndex + 1 &&
            _currentChain[chainIndex + 1].id == -1) {
          _currentChain.removeAt(chainIndex + 1);
        }
        _currentChain.addAll(_selectionHistory[newSelection.id]!);
      } */
    });

    // [New] Smart Migration Execution
    // If we have a pending name validation and NO history found (so we are at placeholder state)
    /* if (pendingChildName != null &&
        !_selectionHistory.containsKey(newSelection.id)) {
      try {
        // Fetch subcategories for the NEW parent
        DataOutput<CategoryModel> result = await CategoryRepository()
            .fetchSubCategories(parentId: newSelection.id!);

        // Look for match
        CategoryModel? match;
        for (var child in result.modelList) {
          if (child.name == pendingChildName) {
            match = child;
            break;
          }
        }

        if (match != null && mounted) {
          setState(() {
            // Replace placeholder with match
            if (_currentChain.length > chainIndex + 1) {
              _currentChain[chainIndex + 1] = match!;
            } else {
              _currentChain.add(match!);
            }

            // Refetch logic will happen below
          });
        }
      } catch (e) {
        print("Smart Migration Failed: $e");
      }
    } */

    if (!mounted) return;

    setState(() {
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

      print("**** SELECTED CATEGORY ID FOR GET-ITEM: $fetchId");
      context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
          categoryId: fetchId, search: searchController.text);
      _fetchCount(overrideCategoryId: fetchId);
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
          color: Colors.transparent,
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
          borderRadius: BorderRadius.circular(1),
          border: Border.all(
            color: context.color.borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 3,
              offset: Offset(5, 5), // x, y
            ),
          ]),
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
            inactiveTrackColor: Colors.grey,
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
        statusBarColor: Colors.transparent,
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
              backgroundColor: context.color.backgroundColor,
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
                    categoryId:
                        _getCurrentFetchId(), // [FIX] Use current selection
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
      color: Colors.transparent,
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
                title: Text('default'.translate(context))
                    .color(context.color.textDefaultColor),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<FetchItemFromCategoryCubit>()
                      .fetchItemFromCategory(
                          categoryId:
                              _getCurrentFetchId(), // [FIX] Use current selection
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
                title: Text('newToOld'.translate(context))
                    .color(context.color.textDefaultColor),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<FetchItemFromCategoryCubit>()
                      .fetchItemFromCategory(
                          categoryId:
                              _getCurrentFetchId(), // [FIX] Use current selection
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
                title: Text('oldToNew'.translate(context))
                    .color(context.color.textDefaultColor),
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
                title: Text('priceHighToLow'.translate(context))
                    .color(context.color.textDefaultColor),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<FetchItemFromCategoryCubit>()
                      .fetchItemFromCategory(
                          categoryId:
                              _getCurrentFetchId(), // [FIX] Use current selection
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
                title: Text('priceLowToHigh'.translate(context))
                    .color(context.color.textDefaultColor),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<FetchItemFromCategoryCubit>()
                      .fetchItemFromCategory(
                          categoryId:
                              _getCurrentFetchId(), // [FIX] Use current selection
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                        categoryId:
                            _getCurrentFetchId(), // [FIX] Use current selection
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
                        categoryId:
                            _getCurrentFetchId(), // [FIX] Use current selection
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

      // [NEW] Get current item count from cubit
      int? currentItemCount;
      final countState = _fetchItemCountCubit.state;
      if (countState is FetchItemCountSuccess) {
        currentItemCount = countState.count;
      }
      print("**** AMENITIES SCREEN - Passing itemCount: $currentItemCount");
      print("**** AMENITIES SCREEN - Count state: $countState");

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: _fetchItemCountCubit,
            child: AmenitiesFilterScreen(
              allAmenities: filterDef!.values ?? [],
              selectedAmenities: currentSelection,
              itemCount: currentItemCount, // [NEW] Pass the count
              onSelectionChanged: (newSelection) {
                // [NEW] Update count dynamically when selection changes
                setState(() {
                  if (newSelection.isEmpty) {
                    _selectedCustomFields.remove(filterName);
                  } else {
                    _selectedCustomFields[filterName] = newSelection;
                  }
                  _fetchCount(); // Fetch new count with updated filters
                });
              },
            ),
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
        // [NEW] Trigger initial count fetch with current values
        // We use a post-frame callback to avoid build-phase side effects if any, though likely safe.
        // Actually, straightforward call is better here as we want to start fetch immediately.
        _fetchCount(
            overrideMinPrice: currentMin?.toInt() ?? min.toInt(),
            overrideMaxPrice: currentMax?.toInt() ?? max.toInt());

        return BlocProvider.value(
          value: _fetchItemCountCubit,
          child: StatefulBuilder(builder: (context, setSheetState) {
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
                          _fetchCount(
                              overrideMinPrice: min.toInt(),
                              overrideMaxPrice: max.toInt());
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
                          color:
                              context.color.textDefaultColor.withOpacity(0.6),
                          fontSize: 13)),

                  const SizedBox(height: 24),

                  // Range Slider
                  RangeSlider(
                    activeColor: context.color.territoryColor,
                    inactiveColor:
                        context.color.territoryColor.withOpacity(0.3),
                    values: RangeValues(
                      (localMin < localMax ? localMin : localMax)
                          .clamp(min, max),
                      (localMin > localMax ? localMin : localMax)
                          .clamp(min, max),
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
                      _fetchCount(
                          overrideMinPrice: localMin.toInt(),
                          overrideMaxPrice: localMax.toInt());
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
                          style:
                              TextStyle(color: context.color.textDefaultColor),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Min",
                            hintStyle: TextStyle(
                                color: context.color.textDefaultColor
                                    .withOpacity(0.5)),
                            suffixText: suffix,
                            suffixStyle: TextStyle(
                                color: context.color.textDefaultColor),
                          ),
                          onChanged: (val) {
                            double? v = double.tryParse(val);
                            if (v != null) {
                              setSheetState(() {
                                localMin = v;
                              });
                              _fetchCount(
                                  overrideMinPrice: localMin.toInt(),
                                  overrideMaxPrice: localMax.toInt());
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
                          style:
                              TextStyle(color: context.color.textDefaultColor),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Max",
                            hintStyle: TextStyle(
                                color: context.color.textDefaultColor
                                    .withOpacity(0.5)),
                            suffixText: suffix,
                            suffixStyle: TextStyle(
                                color: context.color.textDefaultColor),
                          ),
                          onChanged: (val) {
                            double? v = double.tryParse(val);
                            if (v != null) {
                              setSheetState(() {
                                localMax = v;
                              });
                              _fetchCount(
                                  overrideMinPrice: localMin.toInt(),
                                  overrideMaxPrice: localMax.toInt());
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
                      child:
                          BlocBuilder<FetchItemCountCubit, FetchItemCountState>(
                        builder: (context, state) {
                          String buttonText = "Show Results";
                          if (state is FetchItemCountInProgress) {
                            buttonText = "calculating".translate(context);
                          } else if (state is FetchItemCountSuccess) {
                            buttonText = "Show ${state.count} Results";
                          }
                          return Text(
                            buttonText,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
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
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
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
      ),
    );
  }

  Widget _buildSliverGridSection(BuildContext context, int startIndex,
      int itemCount, List<ItemModel> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
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
              child: ItemCard(item: item, radius: 10),
            );
          },
          childCount: itemCount,
        ),
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
