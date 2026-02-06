import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';

import 'package:flutter/material.dart';

import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/utils/app_icon.dart';
import 'package:Ebozor/utils/ui_utils.dart';

import 'package:Ebozor/ui/screens/home/home_screen.dart';

import 'package:Ebozor/data/cubits/fetch_notifications_cubit.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    Widget buildSearchIcon() {
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: 6, end: 7),
        child: UiUtils.getSvg(
          AppIcons.search,
          color: context.color.territoryColor,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: sidePadding,
        vertical: 20,
      ),
      child: Row(
        children: [
          /// 🔍 SEARCH FIELD
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routes.searchScreenRoute,
                  arguments: {"autoFocus": true},
                );
              },
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1,
                    color: context.color.borderColor.darken(30),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: context.color.secondaryColor,
                ),
                child: AbsorbPointer(
                  child: TextFormField(
                    readOnly: true,
                    textAlignVertical:
                        TextAlignVertical.center, // Align text vertically
                    decoration: InputDecoration(
                      isDense: true, // Reduces default height usage
                      border: InputBorder.none,
                      hintText: "searchHintLbl".translate(context),
                      hintStyle: TextStyle(
                        color: context.color.textDefaultColor.withOpacity(0.5),
                        height: 1.2, // Match text height for better centering
                      ),
                      prefixIcon: buildSearchIcon(),
                      prefixIconConstraints: const BoxConstraints(
                          minHeight: 40, minWidth: 40), // Fix icon size
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10), // Symmetric horizontal padding
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// 📍 LOCATION ICON (outside search)
          GestureDetector(
            onTap: () async {
              Navigator.pushNamed(context, Routes.countriesScreen,
                  arguments: {"from": "home"});
            },
            child: Container(
              width: 40,
              height: 40,
              color: Colors.transparent,
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                "assets/location_home.png",
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// 🔔 NOTIFICATION ICON (outside search)
          BlocBuilder<FetchNotificationsCubit, FetchNotificationsState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is FetchNotificationsSuccess) {
                int total = state.total;
                Set<String> processedIds = {
                  ...HiveUtils.getReadNotificationIds(),
                  ...HiveUtils.getRemovedNotificationIds()
                };
                unreadCount = total - processedIds.length;
                if (unreadCount < 0) unreadCount = 0;
              }

              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, Routes.notificationPage);
                },
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      UiUtils.getSvg(
                        AppIcons.notification,
                        color: context.color.textLightColor,
                        width: 24,
                        height: 24,
                      ),
                      if (unreadCount > 0 && HiveUtils.isUserAuthenticated())
                        PositionedDirectional(
                          end: -4,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: context.color.territoryColor,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9 ? "9+" : unreadCount.toString(),
                                style: TextStyle(
                                  color: context.color.buttonColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
