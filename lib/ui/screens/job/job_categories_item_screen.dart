import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Ebozor/ui/screens/job/job_filter_screen.dart';
import 'package:Ebozor/utils/app_icon.dart';
import 'package:flutter/rendering.dart';

class JobCategoriesItemScreen extends StatefulWidget {
  final String categoryName;
  const JobCategoriesItemScreen({super.key, required this.categoryName});

  @override
  State<JobCategoriesItemScreen> createState() =>
      _JobCategoriesItemScreenState();
}

class _JobCategoriesItemScreenState extends State<JobCategoriesItemScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_isFabVisible) {
          setState(() {
            _isFabVisible = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_isFabVisible) {
          setState(() {
            _isFabVisible = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: Container(
          height: 42,
          width: 80,
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/svg/savefiltericon.svg",
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Save",
                    style: TextStyle(
                      color: context.color.textDefaultColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: context.color.secondaryColor,
      appBar: AppBar(
        backgroundColor: context.color.secondaryColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Material(
              clipBehavior: Clip.hardEdge,
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: Directionality(
                    textDirection: Directionality.of(context),
                    child: RotatedBox(
                      quarterTurns:
                          Directionality.of(context) == TextDirection.rtl
                              ? 2
                              : -4,
                      child: UiUtils.getSvg(
                        AppIcons.arrowLeft,
                        fit: BoxFit.none,
                        color: context.color.textDefaultColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        titleSpacing: 6,
        title: Container(
          margin: const EdgeInsets.only(top: 8),
          height: 42,
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.color.borderColor),
          ),
          child: TextField(
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: context.color.textDefaultColor,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: "Search any items ..",
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(start: 6, end: 7),
                child: UiUtils.getSvg(
                  AppIcons.search,
                  color: context.color.territoryColor,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minHeight: 40,
                minWidth: 40,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 9,
                  horizontal: 12), // Top/Bottom 9, Side 12 for text
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Filter Row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const JobFilterScreen(),
                          ),
                        );
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            "assets/svg/jobfiltericon.svg",
                            colorFilter: ColorFilter.mode(
                                context.color.territoryColor, BlendMode.srcIn),
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Filter",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.color.textDefaultColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildFilterChip("City",
                        onTap: () => _showTopFilterSheet(
                            "City", ["Dubai", "Abu Dhabi", "Sharjah"])),
                    _buildFilterChip("Category",
                        onTap: () => _showTopFilterSheet(
                            "Category", ["Finance", "Engineering"])),
                    _buildFilterChip("Salary",
                        onTap: () => _showSalaryFilterSheet()),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

            // CV Banner
            // CV Banner
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                    color: Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(4)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        "assets/svg/resumeicon.svg",
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "80% of the recruiters hire candidates with CV",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: context.color.blackColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: context.color.territoryColor),
                          ),
                          child: Text(
                            "Upload CV",
                            style: TextStyle(
                              color: context.color.territoryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Job List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (context, index) {
                return _buildJobCard();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.color.textDefaultColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: context.color.textDefaultColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showTopFilterSheet(String title, List<String> options) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.color.textDefaultColor,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        color: context.color.textDefaultColor,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showSalaryFilterSheet() {
    double minSalary = 0;
    double maxSalary = 10000;
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
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                Text(
                  "Salary Range",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.color.textDefaultColor,
                  ),
                ),
                const SizedBox(height: 24),
                RangeSlider(
                  values: RangeValues(minSalary, maxSalary),
                  min: 0,
                  max: 20000,
                  divisions: 20,
                  activeColor: context.color.territoryColor,
                  labels: RangeLabels(
                    "AED ${minSalary.toInt()}",
                    "AED ${maxSalary.toInt()}",
                  ),
                  onChanged: (RangeValues values) {
                    setSheetState(() {
                      minSalary = values.start;
                      maxSalary = values.end;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Min: AED ${minSalary.toInt()}",
                        style:
                            TextStyle(color: context.color.textDefaultColor)),
                    Text("Max: AED ${maxSalary.toInt()}",
                        style:
                            TextStyle(color: context.color.textDefaultColor)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.color.territoryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Apply",
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
          );
        });
      },
    );
  }

  Widget _buildJobCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        border: Border(
          bottom: BorderSide(
              color: Colors.grey.withOpacity(0.1), width: 6), // Thick separator
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF3A88EF).withOpacity(0.8),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Text(
              "FEATURED",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hire professional limousine Drivers join our team Todays",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.color.textDefaultColor,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Swiss Luxary Limousine LLC",
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 76),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
              "assets/svg/negotiable.svg", "AED 4,000 - 5,999 Per Month"),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildInfoRow(
                      "assets/svg/jobexperienceicon.svg", "0 - 1 Years Exp")),
              Expanded(
                  child: _buildInfoRow("assets/svg/gendericon.svg", "Any")),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoRow("assets/svg/joblcation.svg", "Thoban , Fujeirah"),
              Text(
                "14 Hours Ago",
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.withOpacity(0.5),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(dynamic icon, String text) {
    return Row(
      children: [
        icon is String
            ? SvgPicture.asset(
                icon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xB2000000),
                  BlendMode.srcIn,
                ),
              )
            : Icon(
                icon,
                size: 16,
                color: const Color(0xB2000000),
              ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xB2000000),
          ),
        ),
      ],
    );
  }
}
