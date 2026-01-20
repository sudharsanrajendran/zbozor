import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/ui/theme/theme.dart';

import 'package:flutter/material.dart';

class AmenitiesFilterScreen extends StatefulWidget {
  final List<dynamic> allAmenities;
  final List<dynamic> selectedAmenities;

  const AmenitiesFilterScreen({
    Key? key,
    required this.allAmenities,
    required this.selectedAmenities,
  }) : super(key: key);

  @override
  State<AmenitiesFilterScreen> createState() => _AmenitiesFilterScreenState();
}

class _AmenitiesFilterScreenState extends State<AmenitiesFilterScreen> {
  late List<dynamic> _currentSelection;
  late List<dynamic> _filteredAmenities;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentSelection = List.from(widget.selectedAmenities);
    _filteredAmenities = List.from(widget.allAmenities);
  }

  void _filterAmenities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAmenities = List.from(widget.allAmenities);
      } else {
        _filteredAmenities = widget.allAmenities
            .where((element) =>
                element.toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.color.secondaryColor,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios, color: context.color.textDefaultColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Amenities",
          style: TextStyle(
            color: context.color.textDefaultColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: TextButton(
              onPressed: _currentSelection.isNotEmpty
                  ? () {
                      setState(() {
                        _currentSelection.clear();
                      });
                    }
                  : null,
              child: Text(
                "Clear All",
                style: TextStyle(
                  color: _currentSelection.isNotEmpty
                      ? context.color.territoryColor
                      : context.color.textLightColor,
                ),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
        color: context.color.backgroundColor,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_filteredAmenities.length} Results",
                style: TextStyle(
                  color: context.color.deactivateColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.color.territoryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context, _currentSelection);
                  },
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.color.borderColor),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterAmenities,
                textAlignVertical:
                    TextAlignVertical.center, // Align text vertically
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding:
                        const EdgeInsets.all(12.0), // Adjust padding for icon
                    child: Image.asset(
                      "assets/amentiessearch.png",
                      width: 10,
                      height: 10,
                    ),
                  ),
                  hintText: "Search any items ..",
                  hintStyle: TextStyle(
                    color: context.color.textLightColor,
                    fontSize: 14, // Ensure appropriate font size
                  ),
                  border: InputBorder.none,
                  filled: false,
                  isDense: true, // Helps with vertical alignment
                  contentPadding: EdgeInsets
                      .zero, // Remove default padding to let centers adhere
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // Use a SliverGridDelegate to create 2 columns as requested
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5, // Adjust based on density
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filteredAmenities.length,
              itemBuilder: (context, index) {
                final amenity = _filteredAmenities[index];
                final isSelected = _currentSelection.contains(amenity);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _currentSelection.remove(amenity);
                      } else {
                        _currentSelection.add(amenity);
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle, // Checkbox style
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: context.color.territoryColor,
                            width: 1.5,
                          ),
                          color: isSelected
                              ? context.color.territoryColor
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          amenity.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? context.color.textDefaultColor
                                : context.color.textLightColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
