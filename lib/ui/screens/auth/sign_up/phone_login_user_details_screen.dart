import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/data/cubits/auth/auth_cubit.dart';
import 'package:Ebozor/data/cubits/system/user_details.dart';
import 'package:Ebozor/ui/screens/widgets/custom_text_form_field.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/helper_utils.dart';
import 'package:Ebozor/utils/responsiveSize.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Ebozor/data/model/user_model.dart';

class PhoneLoginUserDetailsScreen extends StatefulWidget {
  static const String routeName = "phoneLoginUserDetailsScreen";

  final String? phone;
  final String? countryCode;

  const PhoneLoginUserDetailsScreen({super.key, this.phone, this.countryCode});

  static Route route(RouteSettings routeSettings) {
    Map? args = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
        builder: (_) => PhoneLoginUserDetailsScreen(
              phone: args?['phone'],
              countryCode: args?['countryCode'],
            ));
  }

  @override
  State<PhoneLoginUserDetailsScreen> createState() =>
      _PhoneLoginUserDetailsScreenState();
}

class _PhoneLoginUserDetailsScreenState
    extends State<PhoneLoginUserDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> validateAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        var response = await context.read<AuthCubit>().updateuserdata(context,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            mobile: widget.phone,
            countryCode: widget.countryCode,
            notification: "1", // Enable notifications by default
            personalDetail: 1 // Enable personal details by default
            );

        if (mounted) {
          // Update local user details
          context
              .read<UserDetailsCubit>()
              .copy(UserModel.fromJson(response['data']));

          setState(() {
            isLoading = false;
          });

          // Navigate to Home
          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.main,
            (route) => false,
            arguments: {"from": "login"},
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          HelperUtils.showSnackBarMessage(context, e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: UiUtils.buildAppBar(context,
          title: "Complete Profile".translate(context), showBackButton: true),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Enter Details To Continue".translate(context))
                      .size(context.font.normal)
                      .color(context.color.textColorDark),
                  SizedBox(height: 20.rh(context)),
                  buildTextField(
                    context,
                    title: "FullName",
                    controller: nameController,
                    validator: CustomTextFieldValidator.nullCheck,
                  ),
                  buildTextField(
                    context,
                    title: "Email Address",
                    controller: emailController,
                    validator: CustomTextFieldValidator.email,
                  ),
                  SizedBox(height: 30.rh(context)),
                  UiUtils.buildButton(
                    context,
                    onPressed: () {
                      validateAndSubmit();
                    },
                    height: 48.rh(context),
                    buttonTitle: "continue".translate(context),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Center(
              child: UiUtils.progress(
                normalProgressColor: context.color.territoryColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildTextField(BuildContext context,
      {required String title,
      required TextEditingController controller,
      CustomTextFieldValidator? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15.rh(context)),
        Text(title.translate(context)).color(context.color.textDefaultColor),
        SizedBox(height: 10.rh(context)),
        CustomTextFormField(
          controller: controller,
          validator: validator,
          fillColor: context.color.secondaryColor,
        ),
      ],
    );
  }
}
