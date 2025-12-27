import 'package:Ebozor/data/helper/designs.dart';
import 'package:Ebozor/ui/screens/settings/notifications.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/responsiveSize.dart';
import 'package:flutter/material.dart';

import 'package:Ebozor/utils/ui_utils.dart';
import 'package:Ebozor/ui/screens/widgets/animated_routes/blur_page_route.dart';

class NotificationDetail extends StatefulWidget {
  const NotificationDetail({super.key});

  @override
  State<NotificationDetail> createState() => _NotificationDetailState();

  static Route route(RouteSettings routeSettings) {
    return BlurredRouter(
      builder: (_) => const NotificationDetail(),
    );
  }
}

class _NotificationDetailState extends State<NotificationDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: UiUtils.buildAppBar(context,
          title: "notifications".translate(context),
          showBackButton: true),
      body: ListView(children: <Widget>[
        if (selectedNotification.image!.isNotEmpty)
          setNetworkImg(selectedNotification.image!,
              width: double.maxFinite,
              height: 200.rh(context),
              boxFit: BoxFit.cover),
        const SizedBox(height: 10),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: detailWidget())
      ]),
    );
  }

  @override
  void dispose() {
    //Routes.currentRoute = Routes.previousCustomerRoute;
    super.dispose();
  }

  Column detailWidget() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            selectedNotification.title!,
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .merge(const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 5),
          Text(
            selectedNotification.message!,
            style: Theme.of(context).textTheme.bodySmall!,
          ),
        ]);
  }
}
