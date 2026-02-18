import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:Ebozor/ui/screens/widgets/bottom_sheets/create_list_bottom_sheet.dart';

class FavoriteBottomSheet extends StatelessWidget {
  final VoidCallback? onCreateListTap;
  const FavoriteBottomSheet({super.key, this.onCreateListTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Saved to \" All Favorites \"",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.color.textDefaultColor,
              ),
            ),
          ),
          Divider(
            color: Colors.grey.withOpacity(0.3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildListItem(
              context,
              icon: UiUtils.getImage(
                  "https://picsum.photos/seed/fav/200", // Placeholder for list image
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover),
              title: "All Favorites",
              trailing: InkWell(
                // Use InkWell for better touch feedback if interactive
                onTap: () {
                  // Handle trailing action if needed
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),
                ),
              ),
              isDefault: true,
            ),
          ),
          const SizedBox(height: 16),

          ///add to list container
          Container(
            decoration: BoxDecoration(
              color: context.color.borderColor
                  .withOpacity(0.3), // Using borderColor as fallback

              border:
                  Border.all(color: context.color.borderColor.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 16, bottom: 8, left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Add to a List",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.color.textDefaultColor,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          if (onCreateListTap != null) {
                            onCreateListTap!.call();
                          } else {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  const CreateListBottomSheet(),
                            );
                          }
                        },
                        icon: Icon(Icons.add,
                            size: 16,
                            color: context.color
                                .textDefaultColor), // Adjust color as needed
                        label: Text(
                          "New List",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context
                                .color.textDefaultColor, // Ensure consistency
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 8, bottom: 16, left: 16, right: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: context.color.borderColor, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          right: 16, left: 16, top: 10, bottom: 10),
                      child: _buildListItem(
                        context,
                        icon: UiUtils.getImage(
                            "https://picsum.photos/seed/fav2/200", // Placeholder
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover),
                        title: "Create Your first personaliz...",
                        subtitle: "Organize your Favorites",
                        trailing: Padding(
                          padding: const EdgeInsets.only(bottom: 16, left: 16),
                          child: Icon(
                            Icons.more_horiz,
                            color: context.color.textDefaultColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 95,
              height: 3.5,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context,
      {required Widget icon,
      required String title,
      String? subtitle,
      Widget? trailing,
      bool isDefault = false}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 8.0), // Add vertical spacing
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 60,
              height: 60,
              child: icon,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.color.textDefaultColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (isDefault) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(
                          9), // Slightly rounded corners for badge
                    ),
                    child: const Text(
                      "Default",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
