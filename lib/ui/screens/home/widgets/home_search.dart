import 'package:Ebozor/ui/screens/home/widgets/location_widget.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/responsiveSize.dart';
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
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
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
                height: 56.rh(context),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1,
                    color: context.color.borderColor.darken(30),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: context.color.secondaryColor,
                ),
                child: AbsorbPointer(
                  child: TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "searchHintLbl".translate(context),
                      hintStyle: TextStyle(
                        color: context.color.textDefaultColor.withOpacity(0.5),
                      ),
                      prefixIcon: buildSearchIcon(),
                      prefixIconConstraints:
                          const BoxConstraints(minHeight: 5, minWidth: 5),
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
            child: UiUtils.getSvg(
              AppIcons.location,
              color: Colors.grey,
              width: 32,
              height: 32,
            ),
          ),

          const SizedBox(width: 10),

          /// 🔔 NOTIFICATION ICON (outside search)
          BlocBuilder<FetchNotificationsCubit, FetchNotificationsState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is FetchNotificationsSuccess) {
                int total = state.total;
                int lastSeen = HiveUtils.getNotificationTotal();
                unreadCount = total - lastSeen;
                if (unreadCount < 0) unreadCount = 0;
              }

              return GestureDetector(
                onTap: () {
                   Navigator.pushNamed(context, Routes.notificationPage);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UiUtils.getSvg(
                      AppIcons.notification,
                      color: Colors.grey,
                      width: 32,
                      height: 32,
                    ),
                    if (unreadCount > 0)
                      PositionedDirectional(
                        end: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? "9+" : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

