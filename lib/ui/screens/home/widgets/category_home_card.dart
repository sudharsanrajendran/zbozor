import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';

import 'package:Ebozor/utils/ui_utils.dart';

class CategoryHomeCard extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback onTap;

  const CategoryHomeCard({
    super.key,
    required this.title,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final extension = url.split(".").last.toLowerCase();
    final bool isFullImage = !(extension == "png" || extension == "svg");

    return SizedBox(
      width: 77,
      height: 77,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8), // Equal padding on all sides
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: context.color.borderColor.darken(30).withOpacity(0.6),
                offset: const Offset(0, 2),
                blurRadius: 7,
                spreadRadius: 0,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment
                .spaceBetween, // Changed from center to spaceBetween
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 4), // Add 4px padding above image
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: UiUtils.imageType(
                      url,
                      fit: isFullImage ? BoxFit.contain : BoxFit.cover,
                      color: context.color.territoryColor,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 4,
                    right: 4,
                    bottom: 4), // Add side and bottom padding to text
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11, // Reduced font size for better fit
                    color: context.color.textDefaultColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
