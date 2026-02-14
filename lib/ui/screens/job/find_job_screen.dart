import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:Ebozor/utils/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FindJobScreen extends StatefulWidget {
  const FindJobScreen({super.key});

  @override
  State<FindJobScreen> createState() => _FindJobScreenState();
}

class _FindJobScreenState extends State<FindJobScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.color.backgroundColor,
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
        title: Text(
          "Ebozor",
          style: TextStyle(
            color: context.color.textDefaultColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: context.color.borderColor,
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Discover Better Opportunities\nEasily with EBOZOR",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: context.color.textDefaultColor,
                height: 1.2,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 18),
            _buildSearchField(),
            const SizedBox(height: 20),
            _buildSectionTitle("Popular Jobs"),
            const SizedBox(height: 12),
            _buildPopularJobsList(),
            const SizedBox(height: 16),
            _buildSectionTitle("Jobs By Category", onViewAll: () {}),
            const SizedBox(height: 12),
            _buildCategoryGrid(),
            const SizedBox(height: 16),
            _buildSectionTitle("Jobs By Qualification in all cities"),
            const SizedBox(height: 12),
            _buildQualificationGrid(),
            const SizedBox(height: 16),
            _buildSectionTitle("Jobs By Type in All Cities"),
            const SizedBox(height: 12),
            _buildJobTypeGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.color.borderColor),
      ),
      child: TextField(
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          hintText: "Search skills, company or title ....",
          hintStyle: TextStyle(
              color: context.color.textDefaultColor.withOpacity(0.5),
              fontWeight: FontWeight.w400,
              fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                    color: context.color.territoryColor,
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: SvgPicture.asset(
                    "assets/svg/jobsearchicon.svg",
                    width: 20,
                    height: 20,
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                )),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.color.textDefaultColor,
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              "View all",
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPopularJobsList() {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 280,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.color.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                              image: NetworkImage(
                                  "https://picsum.photos/seed/${index + 1}/200"),
                              fit: BoxFit.cover)),
                    ),
                    const SizedBox(width: 12),
                    ///// side padding
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            index == 0
                                ? "Sale Marketing Executive"
                                : "Sales / Business Developer",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.color.textDefaultColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            index == 0
                                ? "Transport & construction"
                                : "200+ Jobs",
                            style: TextStyle(
                              fontSize: 12,
                              color: jobBlueColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (index == 0) ...[
                  _buildJobDetailRow("assets/svg/fulltimejob.svg", "Full Time"),
                  _buildJobDetailRow("assets/svg/negotiable.svg", "Negotiable"),
                  _buildJobDetailRow("assets/svg/joblcation.svg", "Fujairah"),
                ] else ...[
                  Text(
                    "200+ Jobs",
                    style: TextStyle(
                      fontSize: 12,
                      color: context.color.textDefaultColor.withOpacity(0.6),
                    ),
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobDetailRow(String iconPath, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            width: 14,
            height: 14,
            colorFilter: ColorFilter.mode(
              context.color.textDefaultColor.withOpacity(0.6),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: context.color.textDefaultColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.87,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          // height: 178, // Removed fixed height to let grid control it
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.color.borderColor.darken(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 110,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: Image.network(
                    "https://picsum.photos/seed/${index + 10}/200",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 8,
                  end: 8,
                  top: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sales / Business Development",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.color.textDefaultColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "200+ Jobs",
                      style: TextStyle(
                        fontSize: 12,
                        color: jobBlueColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualificationGrid() {
    final items = [
      {
        "icon": "assets/svg/bookjob.svg",
        "title": "High School / Secondary",
        "count": "1100+ Jobs"
      },
      {
        "icon": "assets/svg/degree.svg",
        "title": "Bachelors Degree",
        "count": "1100+ Jobs"
      },
      {
        "icon": "assets/svg/masterdegreee.svg",
        "title": "Master Degree",
        "count": "1100+ Jobs"
      },
      {"icon": "assets/svg/bookjob.svg", "title": "PHD", "count": "1100+ Jobs"},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildGridItem(
          items[index]['icon'] as String,
          items[index]['title'] as String,
          items[index]['count'] as String,
        );
      },
    );
  }

  Widget _buildJobTypeGrid() {
    final items = [
      {
        "icon": "assets/svg/bookjob.svg",
        "title": "Full Time",
        "count": "1100+ Jobs"
      },
      {
        "icon": "assets/svg/bookjob.svg",
        "title": "Part Time",
        "count": "1100+ Jobs"
      },
      {
        "icon": "assets/svg/bookjob.svg",
        "title": "Contract",
        "count": "1100+ Jobs"
      },
      {
        "icon": "assets/svg/bookjob.svg",
        "title": "Remote",
        "count": "1100+ Jobs"
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildGridItem(
          items[index]['icon'] as String,
          items[index]['title'] as String,
          items[index]['count'] as String,
        );
      },
    );
  }

  Widget _buildGridItem(String iconPath, String title, String count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              context.color.textDefaultColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: context.color.textDefaultColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 11,
              color: context.color.textDefaultColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
