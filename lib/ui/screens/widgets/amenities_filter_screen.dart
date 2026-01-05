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
          TextButton(
            onPressed: () {
              setState(() {
                _currentSelection.clear();
              });
            },
            child: Text(
              "Clear All",
              style: TextStyle(color: context.color.textLightColor),
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: context.color.backgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_filteredAmenities.length} Results", // Or total results
                style: TextStyle(color: context.color.textLightColor),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.color.territoryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterAmenities,
              decoration: InputDecoration(
                prefixIcon:
                    Icon(Icons.search, color: context.color.textLightColor),
                hintText: "Search any items ..",
                hintStyle: TextStyle(color: context.color.textLightColor),
                filled: true,
                fillColor: context.color.secondaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
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
                            color: isSelected
                                ? context.color.territoryColor
                                : context.color.textLightColor,
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
                            color: context.color.textDefaultColor,
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
