import 'package:flutter/material.dart';

class PhoneLoginUserDetailsScreen extends StatefulWidget {
  static const String routeName = "phoneLoginUserDetailsScreen";

  static Route route(RouteSettings routeSettings) {
    return MaterialPageRoute(
      builder: (_) => const PhoneLoginUserDetailsScreen(),
    );
  }

  const PhoneLoginUserDetailsScreen({super.key});

  @override
  State<PhoneLoginUserDetailsScreen> createState() =>
      _PhoneLoginUserDetailsScreenState();
}

class _PhoneLoginUserDetailsScreenState
    extends State<PhoneLoginUserDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Profile")),
      body: const Center(child: Text("User Details Screen Placeholder")),
    );
  }
}
