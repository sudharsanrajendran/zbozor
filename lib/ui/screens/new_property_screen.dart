import 'package:Ebozor/data/model/newcategorymodel.dart';
import 'package:Ebozor/ui/screens/home/widgets/location_widget.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/app_icon.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:Ebozor/app/routes.dart';

class NewPropertyScreen extends StatefulWidget {
  final NewCategory category;

  const NewPropertyScreen({super.key, required this.category});

  @override
  State<NewPropertyScreen> createState() => _NewPropertyScreenState();
}

class _NewPropertyScreenState extends State<NewPropertyScreen> {
  int _selectedTabIndex = 0;
  NewCategory? _selectedPropertyType;
  final List<NewCategory> _subCategoryPath = [];

  @override
  void initState() {
    super.initState();
    _initializeSelection();
  }

  void _initializeSelection() {
    // If the category has subcategories (e.g. Property -> Sale, Rent)
    // Select the first one by default as the active tab.
    if (widget.category.subcategories != null &&
        widget.category.subcategories!.isNotEmpty) {
      _selectedTabIndex = 0;
      _onTabSelected(widget.category.subcategories![0]);
    }
  }

  void _onTabSelected(NewCategory tabCategory) {
    setState(() {
      _selectedPropertyType = null;
      _subCategoryPath.clear();

      // Auto-select first child of the tab (e.g. Sale -> Residential)
      if (tabCategory.subcategories != null &&
          tabCategory.subcategories!.isNotEmpty) {
        _selectedPropertyType = tabCategory.subcategories![0];
        // Auto-select first child of that (e.g. Residential -> Apartment)
        if (_selectedPropertyType!.subcategories != null &&
            _selectedPropertyType!.subcategories!.isNotEmpty) {
          _subCategoryPath.add(_selectedPropertyType!.subcategories![0]);
        }
      }
    });
  }

  void _onPropertyTypeSelected(NewCategory propertyType) {
    setState(() {
      _selectedPropertyType = propertyType;
      _subCategoryPath.clear();

      // Auto selecting first sub-category if available
      if (propertyType.subcategories != null &&
          propertyType.subcategories!.isNotEmpty) {
        _subCategoryPath.add(propertyType.subcategories![0]);
      }
    });
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
        widget.category.name,
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
              _initializeSelection();
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
    // If no subcategories at all, just showing basic screen or nothing?
    // Assuming structure: Property -> [Sale, Rent] -> [Residential] -> [Apartment]
    List<NewCategory> tabs = widget.category.subcategories ?? [];

    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
          context: context, statusBarColor: context.color.backgroundColor),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: _buildAppBar(context),
        body: Container(
          color: context.color.secondaryColor,
          child: Column(
            children: [
              _buildTabs(tabs),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationSection(),
                      const SizedBox(height: 12),
                      if (tabs.isNotEmpty &&
                          _selectedTabIndex < tabs.length) ...[
                        _buildContentForTab(tabs[_selectedTabIndex]),
                      ]
                    ],
                  ),
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(List<NewCategory> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: context.color.secondaryColor,
      child: Row(
        children: [
          for (int index = 0; index < categories.length; index++) ...[
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = index;
                    _onTabSelected(categories[index]);
                  });
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
                    categories[index].name,
                    textAlign: TextAlign.center,
                    maxLines: MediaQuery.of(context).size.width < 390 ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _selectedTabIndex == index
                          ? context.color.textDefaultColor
                          : context.color.textLightColor,
                      fontWeight: _selectedTabIndex == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            if (index != categories.length - 1) const SizedBox(width: 20),
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
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.color.borderColor),
          ),
          child: const LocationWidget(),
        ),
        const SizedBox(height: 12),
        Text(
          "Select the cities neighbourhoods or building that you want to search property in .",
          style: TextStyle(
              fontSize: 12,
              color: context.color.textDefaultColor.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _buildContentForTab(NewCategory tabCategory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tabCategory.subcategories != null &&
            tabCategory.subcategories!.isNotEmpty) ...[
          _buildPropertyTypesList(tabCategory.subcategories!),
          const SizedBox(height: 12),
        ],

        // Dynamic Levels (Sub-Categories of Property Type)
        // E.g. Apartment, Villa
        if (_selectedPropertyType != null &&
            _selectedPropertyType!.subcategories != null &&
            _selectedPropertyType!.subcategories!.isNotEmpty) ...[
          _buildDynamicSubCategoryChips(
              0, _selectedPropertyType!.subcategories!),
        ],

        // Further recursive levels
        ..._buildRecursiveLevels(),
      ],
    );
  }

  // PROPERTY TYPE ROW (e.g. Residential, Commercial)
  Widget _buildPropertyTypesList(List<NewCategory> propertyTypes) {
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
                    height: 90,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.color.secondaryColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? context.color.textDefaultColor
                            : context.color.borderColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 30,
                          width: 30,
                          child: Center(
                            child: UiUtils.imageType(
                              subCat.image,
                              color: isSelected
                                  ? context.color.textDefaultColor
                                  : context.color.textDefaultColor,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            subCat.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? context.color.textDefaultColor
                                  : context.color.textLightColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              height: 1.2,
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

  List<Widget> _buildRecursiveLevels() {
    List<Widget> levels = [];
    for (int i = 0; i < _subCategoryPath.length; i++) {
      NewCategory currentSelection = _subCategoryPath[i];
      if (currentSelection.subcategories != null &&
          currentSelection.subcategories!.isNotEmpty) {
        levels.add(const SizedBox(height: 12));
        levels.add(_buildDynamicSubCategoryChips(
            i + 1, currentSelection.subcategories!));
      }
    }
    return levels;
  }

  Widget _buildDynamicSubCategoryChips(
      int levelIndex, List<NewCategory> subCats) {
    NewCategory? currentlySelectedAtThisLevel;
    // Determine selection:
    // If level 0 (children of PropertyType), check path[0]
    // If level 1 (children of path[0]), check path[1]

    // Note: _buildDynamicSubCategoryChips(0,...) is for children of _selectedPropertyType.
    // So if _subCategoryPath has element at 0, that's the selection.

    if (_subCategoryPath.length > levelIndex) {
      currentlySelectedAtThisLevel = _subCategoryPath[levelIndex];
    }

    String titleName = "";
    if (levelIndex == 0) {
      titleName = _selectedPropertyType?.name ?? "";
    } else {
      titleName = _subCategoryPath[levelIndex - 1].name;
    }

    String suffix = "Categories"; // Default suffix

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
                  label: Text(child.name),
                  backgroundColor: context.color.secondaryColor,
                  side: BorderSide(
                    color: isSelected
                        ? context.color.textDefaultColor
                        : context.color.borderColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? context.color.textDefaultColor
                        : context.color.textLightColor,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_subCategoryPath.length > levelIndex) {
                        _subCategoryPath.removeRange(
                            levelIndex, _subCategoryPath.length);
                      }
                      _subCategoryPath.add(child);
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
          style: TextStyle(
              color: context.color.buttonColor,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _onShowResults() {
    // Gather all IDs
    List<String> ids = [];
    String finalName = widget.category.name;

    // 1. Root Category (e.g. Property) - usually handled by logic, but API might expect root ID
    ids.add(widget.category.id.toString());

    // 2. Tab Category (e.g. Sale)
    if (widget.category.subcategories != null &&
        widget.category.subcategories!.isNotEmpty) {
      if (_selectedTabIndex < widget.category.subcategories!.length) {
        var tab = widget.category.subcategories![_selectedTabIndex];
        ids.add(tab.id.toString());
        finalName = tab.name;
      }
    }

    // 3. Property Type (e.g. Residential)
    if (_selectedPropertyType != null) {
      ids.add(_selectedPropertyType!.id.toString());
      finalName = _selectedPropertyType!.name;
    }

    // 4. Path (e.g. Apartment)
    for (var cat in _subCategoryPath) {
      ids.add(cat.id.toString());
      finalName = cat.name;
    }

    // Navigate with the most specific ID available as catID
    // And list of all parent IDs just in case
    Navigator.pushNamed(context, Routes.itemsList, arguments: {
      'catID': ids.last,
      'catName': finalName,
      "categoryIds": ids,
    });
  }
}
