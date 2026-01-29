// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:math' hide log;
import 'dart:developer';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Ebozor/ui/screens/native_ads_screen.dart';

//import 'package:app_links/app_links.dart';

import 'package:Ebozor/data/cubits/category/fetch_category_cubit.dart';
import 'package:Ebozor/data/cubits/slider_cubit.dart';
import 'package:Ebozor/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:Ebozor/data/cubits/system/get_api_keys_cubit.dart';

import 'package:Ebozor/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:Ebozor/data/cubits/home/fetch_home_screen_cubit.dart';
import 'package:Ebozor/data/cubits/favorite/favorite_cubit.dart';
import 'package:Ebozor/data/cubits/fetch_notifications_cubit.dart';
import 'package:Ebozor/data/cubits/seller/fetch_verification_request_cubit.dart';

import 'package:Ebozor/data/model/home/home_screen_section.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:uni_links/uni_links.dart';

import 'package:Ebozor/utils/ApiService/api.dart';

import 'package:Ebozor/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:Ebozor/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:Ebozor/data/helper/designs.dart';
import 'package:Ebozor/data/model/item/item_model.dart';
import 'package:Ebozor/data/model/system_settings_model.dart';

import 'package:Ebozor/utils/extensions/extensions.dart';

import 'package:Ebozor/utils/ui_utils.dart';
import 'package:Ebozor/ui/screens/ad_banner_screen.dart';
import 'package:Ebozor/ui/screens/widgets/errors/no_internet.dart';
import 'package:Ebozor/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:Ebozor/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:Ebozor/ui/screens/home/widgets/home_sections_adapter.dart';
import 'package:Ebozor/ui/screens/home/widgets/category_widget_home.dart';
// import 'package:Ebozor/ui/screens/home/widgets/new_home_categories_widget.dart';
// import 'package:Ebozor/data/cubits/category/newcategoriescubit.dart';
import 'package:Ebozor/ui/screens/home/widgets/home_search.dart';

import 'package:Ebozor/ui/screens/home/widgets/home_shimmers.dart';

import 'package:Ebozor/ui/screens/home/slider_widget.dart';
import 'package:Ebozor/ui/screens/home/widgets/verification_banner.dart';

const double sidePadding = 16;

class HomeScreen extends StatefulWidget {
  final String? from;

  const HomeScreen({super.key, this.from});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<HomeScreen> {
  //
  @override
  bool get wantKeepAlive => true;

  //
  List<ItemModel> itemLocalList = [];

  //
  bool isCategoryEmpty = false;

  //
  late final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Future<void> _refreshData() async {
    try {
      var city = HiveUtils.getCityName();
      var areaId = HiveUtils.getAreaId();
      var country = HiveUtils.getCountryName();
      var state = HiveUtils.getStateName();
      var radius = HiveUtils.getNearbyRadius();
      var longitude = HiveUtils.getLongitude();
      var latitude = HiveUtils.getLatitude();

      print("DEBUG: HomeScreen Refresh - Using Location:");
      print("City: $city");
      print("State: $state");
      print("Country: $country");
      print("Lat/Lng: $latitude, $longitude");

      context
          .read<FetchHomeScreenCubit>()
          .fetch(city: city, areaId: areaId, country: country, state: state);

      context.read<FetchHomeAllItemsCubit>().fetch(
          city: city,
          areaId: areaId,
          radius: radius,
          longitude: longitude,
          latitude: latitude,
          country: country,
          state: state);
    } catch (e) {}

    if (HiveUtils.isUserAuthenticated()) {
      context.read<FetchNotificationsCubit>().fetchNotifications();
      context
          .read<FetchVerificationRequestsCubit>()
          .fetchVerificationRequests();
    }
  }

  @override
  void initState() {
    initializeSettings();
    addPageScrollListener();
    notificationPermissionChecker();
    // LocalAwsomeNotification().init(context); // Removed redundant init call
    ///////////////////////////////////////

    // NotificationService.init(context); // Removed redundant init call
    context.read<SliderCubit>().fetchSlider(context);
    context.read<FetchCategoryCubit>().fetchCategories();
    // context.read<NewCategoriesCubit>().fetchCategories();
    _refreshData();

    if (HiveUtils.isUserAuthenticated()) {
      context.read<FavoriteCubit>().getFavorite();
      //fetchApiKeys();
      context.read<GetBuyerChatListCubit>().fetch();
      context.read<BlockedUsersListCubit>().blockedUsersList();
      context
          .read<FetchVerificationRequestsCubit>()
          .fetchVerificationRequests();
    }

    _scrollController.addListener(() {
      if (_scrollController.isEndReached()) {
        if (context.read<FetchHomeAllItemsCubit>().hasMoreData()) {
          context.read<FetchHomeAllItemsCubit>().fetchMore(
                city: HiveUtils.getCityName(),
                areaId: HiveUtils.getAreaId(),
                radius: HiveUtils.getNearbyRadius(),
                longitude: HiveUtils.getLongitude(),
                latitude: HiveUtils.getLatitude(),
                country: HiveUtils.getCountryName(),
                stateName: HiveUtils.getStateName(),
              );
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initializeSettings() {
    final settingsCubit = context.read<FetchSystemSettingsCubit>();
    if (!const bool.fromEnvironment("force-disable-demo-mode",
        defaultValue: false)) {
      Constant.isDemoModeOn =
          settingsCubit.getSetting(SystemSetting.demoMode) ?? false;
    }
  }

  void addPageScrollListener() {
    //homeScreenController.addListener(pageScrollListener);
  }

  void fetchApiKeys() {
    context.read<GetApiKeysCubit>().fetch();
  }

  /*void pageScrollListener() {
    ///This will load data on page end
    if (homeScreenController.isEndReached()) {
      if (mounted) {
        if (context.read<FetchHomeItemsCubit>().hasMoreData()) {
          if (context.read<FetchHomeItemsCubit>().hasMoreData()) {
            context.read<FetchHomeItemsCubit>().fetchMoreItem();
          }
        }
      }
    }
  }*/

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print(context.watch<SliderCubit>().state);

    return SafeArea(
      child: Scaffold(
        /*   appBar: AppBar(
          elevation: 0,
          leadingWidth: double.maxFinite,
          leading: Padding(
              padding: EdgeInsetsDirectional.only(
                  start: sidePadding.rw(context), end: sidePadding.rw(context)),
              child: const LocationWidget()),
          /* HiveUtils.getCityName() != null
                    ? const LocationWidget()
                    : const SizedBox.shrink()),*/
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        ),*/
        backgroundColor: context.color.backgroundColor,
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          color: context.color.territoryColor,
          onRefresh: _refreshData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: BlocBuilder<FetchHomeScreenCubit, FetchHomeScreenState>(
                  builder: (context, state) {
                    if (state is FetchHomeScreenInProgress) {
                      return shimmerEffect();
                    }
                    if (state is FetchHomeScreenSuccess) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HomeSearchField(),
                          const SliderWidget(),
                          const CategoryWidgetHome(),
                          // const NewHomeCategoriesWidget(),
                          if (HiveUtils.isUserAuthenticated())
                            BlocBuilder<FetchVerificationRequestsCubit,
                                FetchVerificationRequestState>(
                              builder: (context, state) {
                                bool isLocallyVerified =
                                    HiveUtils.getUserDetails().isVerified == 1;
                                bool isRemotelyVerified = false;

                                if (state is FetchVerificationRequestSuccess) {
                                  isRemotelyVerified =
                                      state.data.status == "approved";
                                }

                                if (!isLocallyVerified && !isRemotelyVerified) {
                                  return const VerificationBanner();
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ...List.generate(state.sections.length, (index) {
                            HomeScreenSection section = state.sections[index];
                            if (state.sections.isNotEmpty) {
                              return HomeSectionsAdapter(
                                section: section,
                              );
                            } else {
                              return SizedBox.shrink();
                            }
                          }),
                          if (state.sections.isNotEmpty &&
                              Constant.isGoogleBannerAdsEnabled == "1") ...[
                            Container(
                              padding: EdgeInsets.only(top: 5),
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: AdBannerWidget(),
                            )
                          ] else ...[
                            SizedBox(
                              height: 10,
                            )
                          ],
                        ],
                      );
                    }
                    if (state is FetchHomeScreenFail) {
                      print('hey bro ${state.error}');
                    }
                    return SizedBox.shrink();
                  },
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 10)),
              const AllItemsSliverWidget(),
              SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }

  Widget shimmerEffect() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 24,
          horizontal: defaultPadding,
        ),
        child: Column(
          children: [
            ClipRRect(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              child: CustomShimmer(height: 52, width: double.maxFinite),
            ),
            SizedBox(
              height: 12,
            ),
            ClipRRect(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              child: CustomShimmer(height: 170, width: double.maxFinite),
            ),
            SizedBox(
              height: 12,
            ),
            Container(
              height: 100,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 10,
                physics: NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 8.0),
                    child: const Column(
                      children: [
                        ClipRRect(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          child: CustomShimmer(
                            height: 70,
                            width: 66,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        CustomShimmer(
                          height: 10,
                          width: 48,
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        const CustomShimmer(
                          height: 10,
                          width: 60,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomShimmer(
                  height: 20,
                  width: 150,
                ),
                /* CustomShimmer(
                  height: 20,
                  width: 50,
                ),*/
              ],
            ),
            Container(
              height: 214,
              margin: EdgeInsets.only(top: 10),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 5,
                physics: NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 10.0),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          child: CustomShimmer(
                            height: 147,
                            width: 250,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        CustomShimmer(
                          height: 15,
                          width: 90,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        const CustomShimmer(
                          height: 14,
                          width: 230,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        const CustomShimmer(
                          height: 14,
                          width: 200,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 20),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: 16,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        child: CustomShimmer(
                          height: 147,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      CustomShimmer(
                        height: 15,
                        width: 70,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      const CustomShimmer(
                        height: 14,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      const CustomShimmer(
                        height: 14,
                        width: 130,
                      ),
                    ],
                  );
                },
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisExtent: 215,
                  crossAxisCount: 2, // Single column grid
                  mainAxisSpacing: 15.0,
                  crossAxisSpacing: 15.0,
                  // You may adjust this aspect ratio as needed
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sliderWidget() {
    return BlocConsumer<SliderCubit, SliderState>(
      listener: (context, state) {
        if (state is SliderFetchSuccess) {
          setState(() {});
        }
      },
      builder: (context, state) {
        log('State is  $state');
        if (state is SliderFetchInProgress) {
          return const SliderShimmer();
        }
        if (state is SliderFetchFailure) {
          return Container();
        }
        if (state is SliderFetchSuccess) {
          if (state.sliderlist.isNotEmpty) {
            return const SliderWidget();
          }
        }
        return Container();
      },
    );
  }
}

//// recently added
class AllItemsSliverWidget extends StatelessWidget {
  const AllItemsSliverWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchHomeAllItemsCubit, FetchHomeAllItemsState>(
      builder: (context, state) {
        if (state is FetchHomeAllItemsSuccess) {
          if (state.items.isNotEmpty) {
            // Flatten items into Headers, Rows, and Ads
            List<dynamic> cachedList = [];

            // 1. Header
            cachedList.add("Header");

            // 2. Items paired into Rows, with Ads interspersed
            int gridCount = Constant.nativeAdsAfterItemNumber;
            int total = state.items.length;
            int itemIndex = 0;

            // We assume crossAxisCount = 2

            while (itemIndex < total) {
              // Add a chunk of items (up to gridCount)
              int chunkEnd = min(itemIndex + gridCount, total);

              // Process this chunk as Pairs (Rows)
              for (int i = itemIndex; i < chunkEnd; i += 2) {
                List<ItemModel> pair = [];
                pair.add(state.items[i]);
                if (i + 1 < chunkEnd) {
                  pair.add(state.items[i + 1]);
                }
                cachedList.add(pair);
              }

              itemIndex = chunkEnd;

              // If we are not at end, add Ad
              if (itemIndex < total) {
                cachedList.add("Ad");
              }
            }

            if (state.isLoadingMore) {
              cachedList.add("Loading");
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  var obj = cachedList[index];

                  if (obj == "Header") {
                    return TitleHeader(
                      title: "recentlyAdded".translate(context),
                      onTap: () {},
                      hideSeeAll: true,
                    );
                  }

                  if (obj == "Ad") {
                    return NativeAdWidget(type: TemplateType.medium);
                  }

                  if (obj == "Loading") {
                    return UiUtils.progress();
                  }

                  if (obj is List<ItemModel>) {
                    // Render Row of Items
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: sidePadding, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ItemCard(
                              radius: 5,
                              item: obj[0],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: obj.length > 1
                                ? ItemCard(
                                    radius: 5,
                                    item: obj[1],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  }

                  return SizedBox.shrink();
                },
                childCount: cachedList.length,
              ),
            );
          } else {
            return SliverToBoxAdapter(child: SizedBox.shrink());
          }
        }
        if (state is FetchHomeAllItemsFail) {
          if (state.error is ApiException) {
            if (state.error.error == "no-internet") {
              return SliverToBoxAdapter(child: Center(child: NoInternet()));
            }
          }
          return SliverToBoxAdapter(child: const SomethingWentWrong());
        }
        return SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}

Future<void> notificationPermissionChecker() async {
  if (!(await Permission.notification.isGranted)) {
    await Permission.notification.request();
  }
}
