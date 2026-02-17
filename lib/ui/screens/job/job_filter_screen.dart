import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';

class JobFilterScreen extends StatefulWidget {
  const JobFilterScreen({super.key});

  @override
  State<JobFilterScreen> createState() => _JobFilterScreenState();
}

class _JobFilterScreenState extends State<JobFilterScreen> {
  // Mock selections
  String selectedCity = "All cities";
  String selectedSalary = "Negotiable";
  String selectedEducation = "N/A";
  String selectedExperience = "0-1 years";
  String selectedEmploymentType = "Full Time";
  String selectedRemote = "Yes";
  String selectedAdsPosted = "Past 24 hours";

  bool adsWithVideo = false;
  bool adsWith360 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.secondaryColor,
      appBar: AppBar(
        backgroundColor: context.color.secondaryColor,
        elevation: 0,
        leading: BackButton(color: context.color.textDefaultColor),
        centerTitle: true,
        title: Text(
          "Filter",
          style: TextStyle(
            color: context.color.textDefaultColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Reset logic here
            },
            child: const Text(
              "Reset",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Citys"),
                  _buildChipGroup(
                    ["All cities", "Dubai", "Abu Dhabi", "Ras Al Khaimah"],
                    selectedCity,
                    (val) => setState(() => selectedCity = val),
                  ),
                  _buildSectionTitle("Category"),
                  _buildSearchInput("Accounting / Finance"),
                  _buildSectionTitle("Role"),
                  _buildSearchInput("Accounting / Finance"),
                  _buildSectionTitle("salary"),
                  _buildChipGroup(
                    ["Negotiable", "Less than 2,000", "2,000 to 3,000"],
                    selectedSalary,
                    (val) => setState(() => selectedSalary = val),
                  ),
                  _buildSectionTitle("Education"),
                  _buildChipGroup(
                    ["N/A", "High-school/secondary", "Phd"],
                    selectedEducation,
                    (val) => setState(() => selectedEducation = val),
                  ),
                  _buildSectionTitle("Experience"),
                  _buildChipGroup(
                    ["0-1 years", "1-2 years", "2-3 years", "4-5 years"],
                    selectedExperience,
                    (val) => setState(() => selectedExperience = val),
                  ),
                  _buildSectionTitle("Employment Type"),
                  _buildChipGroup(
                    ["Full Time", "Part Time", "Contract", "Temporary"],
                    selectedEmploymentType,
                    (val) => setState(() => selectedEmploymentType = val),
                  ),
                  _buildSectionTitle("Remote Job"),
                  _buildChipGroup(
                    ["Yes", "NO"],
                    selectedRemote,
                    (val) => setState(() => selectedRemote = val),
                  ),
                  _buildSectionTitle("Ads Posted"),
                  _buildChipGroup(
                    ["Past 24 hours", "Past 7 days", "Past 30 days"],
                    selectedAdsPosted,
                    (val) => setState(() => selectedAdsPosted = val),
                  ),
                  _buildSectionTitle("More Filters"),
                  Row(
                    children: [
                      _buildBoxFilter("Ads With\nVideo",
                          Icons.videocam_outlined, adsWithVideo, () {
                        setState(() => adsWithVideo = !adsWithVideo);
                      }),
                      const SizedBox(width: 12),
                      _buildBoxFilter(
                          "Ads With\n360 Tour", Icons.threesixty, adsWith360,
                          () {
                        setState(() => adsWith360 = !adsWith360);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Using red as per design
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Show 10,642 Results",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: context.color.textDefaultColor,
        ),
      ),
    );
  }

  Widget _buildChipGroup(
      List<String> options, String selected, Function(String) onSelect) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onSelect(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? context.color.textDefaultColor
                    : Colors.grey.withOpacity(0.3),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected
                    ? context.color.textDefaultColor
                    : Colors.grey.withOpacity(0.5),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchInput(String hint) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBoxFilter(
      String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? context.color.textDefaultColor
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
