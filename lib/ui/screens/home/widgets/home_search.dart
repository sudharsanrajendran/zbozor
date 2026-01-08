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
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:Ebozor/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:Ebozor/data/cubits/home/fetch_home_screen_cubit.dart';
import 'package:Ebozor/utils/helper_utils.dart';

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
            onLongPress: () {
              Navigator.pushNamed(context, Routes.countriesScreen,
                  arguments: {"from": "home"});
            },
            onTap: () async {
              await _fastFetchLocation(context);
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

  Future<void> _fastFetchLocation(BuildContext context) async {
    try {
      // Show feedback
      HelperUtils.showSnackBarMessage(
          context, "fetchingLocation".translate(context));

      // 1. Get last known position for potentially instant result
      Position? position = await Geolocator.getLastKnownPosition();

      // 2. Fetch fresh position if last known is old or null
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      // 3. Get Address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // 4. Update Hive
        HiveUtils.setLocation(
          city: place.locality,
          state: place.administrativeArea,
          country: place.country,
          area: place.subLocality,
          latitude: position.latitude,
          longitude: position.longitude,
          areaId: null,
        );

        // 5. Refresh Cubits
        if (context.mounted) {
          context.read<FetchHomeScreenCubit>().fetch(
                city: HiveUtils.getCityName(),
                country: HiveUtils.getCountryName(),
                state: HiveUtils.getStateName(),
                areaId: null,
              );

          context.read<FetchHomeAllItemsCubit>().fetch(
                city: HiveUtils.getCityName(),
                country: HiveUtils.getCountryName(),
                state: HiveUtils.getStateName(),
                latitude: position.latitude,
                longitude: position.longitude,
                radius: HiveUtils.getNearbyRadius(),
                areaId: null,
              );

          HelperUtils.showSnackBarMessage(
            context,
            "locationUpdated".translate(context),
            type: MessageType.success,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        HelperUtils.showSnackBarMessage(
          context,
          e.toString(),
          type: MessageType.error,
        );
      }
    }
  }
}
