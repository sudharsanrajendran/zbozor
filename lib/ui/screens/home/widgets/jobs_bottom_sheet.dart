import 'package:flutter/material.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/ui_utils.dart';

class JobsBottomSheet extends StatelessWidget {
  const JobsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: context.color.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Top Handle/Indicator
          // Though the prompt asked for a indicator at the bottom "last ta",
          // usually there is one at top too, but I will strictly follow "last ta" (at the last).
          // Wait, "bottomsheet top la right and left radious 6 px panniru" - done.
          // "kila oru chinna gray color oru border mathi last ta" - this is the indicator.
          const SizedBox(height: 20),
          Text(
            "Find Jobs and Hire Talent",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.color.textDefaultColor,
            ),
          ),
          const SizedBox(height: 10), // Gap 10
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 16), // Gap 16

          _buildOption(
            context,
            title: "Find Jobs",
            subtitle: "Get hired at the job you want",
            icon: Icons.work_outline,
            iconBgColor: const Color(0xFFFFEBEE), // Subtle pinkish
            iconColor: const Color(0xFFF44336), // Reddish
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 14),
          _buildOption(
            context,
            title: "Hire Talent",
            subtitle: "Find the right person for the job",
            icon: Icons.person_search_outlined,
            iconBgColor: const Color(0xFFFFEBEE),
            iconColor: const Color(0xFFF44336),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const SizedBox(height: 30),

          // Bottom Indicator
          Center(
            child: Container(
              height: 3.5,
              width: 94.3,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9), // Gray
                borderRadius: BorderRadius.circular(10.50),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: context.color.borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.color.textDefaultColor,
                    ),
                  ),
                  const SizedBox(height: 3), // Gap 3
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.color.textDefaultColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
