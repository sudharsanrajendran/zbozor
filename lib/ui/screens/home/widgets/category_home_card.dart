
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
      width: 85,
      height: 120,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: UiUtils.imageType(
                  url,
                  fit: isFullImage ? BoxFit.contain : BoxFit.cover,
                ),
              ),
            ),

           // const SizedBox(height: ),

            Expanded(
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.font.small,
                    color: context.color.textDefaultColor,
                    fontWeight: FontWeight.w500,
                  ),
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


