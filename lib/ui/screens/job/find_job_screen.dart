import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';

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
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: context.color.borderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back,
                color: context.color.textDefaultColor,
              ),
            ),
          ),
        ),
        title: Text(
          "Find Jobs",
          style: TextStyle(
            color: context.color.textDefaultColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchField(),
            const SizedBox(height: 20),
            _buildSectionTitle("Popular Jobs"),
            const SizedBox(height: 12),
            _buildPopularJobsList(),
            const SizedBox(height: 20),
            _buildSectionTitle("Jobs By Qualification in all cities"),
            const SizedBox(height: 12),
            _buildQualificationGrid(),
            const SizedBox(height: 20),
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
      height: 50,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.color.borderColor),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search skills, company or title ....",
          hintStyle:
              TextStyle(color: context.color.textDefaultColor.withOpacity(0.5)),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
                decoration: BoxDecoration(
                    color: context.color.territoryColor,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 20,
                )),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: context.color.textDefaultColor,
      ),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                              image: NetworkImage(
                                  "https://picsum.photos/seed/${index + 1}/200"),
                              fit: BoxFit.cover)),
                    ),
                    const SizedBox(width: 12),
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
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (index == 0) ...[
                  _buildJobDetailRow(Icons.access_time, "Full Time"),
                  _buildJobDetailRow(
                      Icons.monetization_on_outlined, "Negotiable"),
                  _buildJobDetailRow(Icons.location_on_outlined, "Fujairah"),
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

  Widget _buildJobDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 14, color: context.color.textDefaultColor.withOpacity(0.6)),
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

  Widget _buildQualificationGrid() {
    final items = [
      {
        "icon": Icons.menu_book,
        "title": "High School / Secondary",
        "count": "1100+ Jobs"
      },
      {
        "icon": Icons.school,
        "title": "Bachelors Degree",
        "count": "1100+ Jobs"
      },
      {
        "icon": Icons.school_outlined,
        "title": "Master Degree",
        "count": "1100+ Jobs"
      },
      {"icon": Icons.book, "title": "PHD", "count": "1100+ Jobs"},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3, // Decreased from 1.4 to give more height
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildGridItem(
          items[index]['icon'] as IconData,
          items[index]['title'] as String,
          items[index]['count'] as String,
        );
      },
    );
  }

  Widget _buildJobTypeGrid() {
    final items = [
      {"icon": Icons.menu_book, "title": "Full Time", "count": "1100+ Jobs"},
      {"icon": Icons.menu_book, "title": "Part Time", "count": "1100+ Jobs"},
      {"icon": Icons.menu_book, "title": "Contract", "count": "1100+ Jobs"},
      {"icon": Icons.menu_book, "title": "Remote", "count": "1100+ Jobs"},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3, // Decreased from 1.4
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildGridItem(
          items[index]['icon'] as IconData,
          items[index]['title'] as String,
          items[index]['count'] as String,
        );
      },
    );
  }

  Widget _buildGridItem(IconData icon, String title, String count) {
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
          Icon(icon, size: 32, color: context.color.textDefaultColor),
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
