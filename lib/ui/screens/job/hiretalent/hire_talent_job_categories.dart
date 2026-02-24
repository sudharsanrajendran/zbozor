import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:Ebozor/ui/screens/job/hiretalent/hireTalent_itemscreen.dart';

class HiretalentJobCategoriesScreen extends StatelessWidget {
  const HiretalentJobCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> categories = [
      "Account / Finance",
      "Automobile",
      "Beauty / Salon",
      "Cleaner / Housekeeper",
      "Construction",
      "Cook / Chef",
      "Customer Service Call Center",
    ];

    return Scaffold(
      backgroundColor: context.color.secondaryColor,
      appBar: UiUtils.buildAppBar(
        context,
        title: "Jobs",
        showBackButton: true,
        hideBottomBorder: true,
      ),
      body: ListView(
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Text(
                "All in Jobs",
                style: TextStyle(
                  color: context.color.textDefaultColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              iconColor: context.color.textDefaultColor,
              collapsedIconColor: context.color.textDefaultColor,
              children: categories.map((category) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(
                        height: 2,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    ListTile(
                      title: Text(
                        category,
                        style: TextStyle(
                          color:
                              context.color.textDefaultColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => hireTalent_itemscreen(
                              categoryName: category,
                            ),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16)
                          .copyWith(top: 14),
                      dense: true,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              height: 2,
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                "Others",
                style: TextStyle(
                  color: context.color.textDefaultColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              iconColor: context.color.textDefaultColor,
              collapsedIconColor: context.color.textDefaultColor,
              children: [
                ListTile(
                  title: Text(
                    "Other Jobs",
                    style: TextStyle(
                      color: context.color.textDefaultColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const hireTalent_itemscreen(
                          categoryName: "Other Jobs",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
