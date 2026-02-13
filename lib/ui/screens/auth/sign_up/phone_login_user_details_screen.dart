import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/data/cubits/auth/auth_cubit.dart';
import 'package:Ebozor/data/cubits/system/user_details.dart';
import 'package:Ebozor/data/model/user_model.dart';
import 'package:Ebozor/ui/screens/widgets/custom_text_form_field.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/helper_utils.dart';
import 'package:Ebozor/utils/responsiveSize.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PhoneLoginUserDetailsScreen extends StatefulWidget {
  final String? phone;
  final String? countryCode;

  const PhoneLoginUserDetailsScreen({
    super.key,
    this.phone,
    this.countryCode,
  });

  @override
  State<PhoneLoginUserDetailsScreen> createState() =>
      _PhoneLoginUserDetailsScreenState();

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return CupertinoPageRoute(
      builder: (_) => PhoneLoginUserDetailsScreen(
        phone: arguments['phone'],
        countryCode: arguments['countryCode'],
      ),
    );
  }
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

  void _onTapSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        var response = await context.read<AuthCubit>().updateuserdata(
              context,
              name: nameController.text.trim(),
              email: emailController.text.trim(),
              mobile: widget.phone,
              countryCode: widget.countryCode,
              notification: "1", // Enable notifications by default
            );

        Future.delayed(Duration.zero, () {
          context
              .read<UserDetailsCubit>()
              .copy(UserModel.fromJson(response['data']));
          setState(() {
            isLoading = false;
          });

          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.main,
            (route) => false,
            arguments: {"from": "login"},
          );
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        HelperUtils.showSnackBarMessage(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiUtils.buildAppBar(context,
          showBackButton: false, title: "completeProfile".translate(context)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTextField(
                    context,
                    title: "fullName",
                    controller: nameController,
                    validator: CustomTextFieldValidator.nullCheck,
                  ),
                  buildTextField(
                    context,
                    title: "emailAddress",
                    controller: emailController,
                    validator: CustomTextFieldValidator.email,
                  ),
                  SizedBox(height: 30.rh(context)),
                  UiUtils.buildButton(
                    context,
                    onPressed: _onTapSubmit,
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
        SizedBox(height: 10.rh(context)),
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
