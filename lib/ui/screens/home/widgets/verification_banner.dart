import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/data/cubits/seller/fetch_verification_request_cubit.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (HiveUtils.getUserDetails().isVerified == 1) {
      return SizedBox.shrink();
    }

    return BlocBuilder<FetchVerificationRequestsCubit,
        FetchVerificationRequestState>(
      builder: (context, state) {
        String status = "";
        if (state is FetchVerificationRequestSuccess) {
          status = state.data.status ?? "";
        }

        if (status == "approved") {
          return SizedBox.shrink();
        }

        bool isPending = status == "pending" || status == "resubmitted";
        bool isRejected = status == "rejected";

        return GestureDetector(
          onTap: isPending
              ? null
              : () {
                  Navigator.pushNamed(
                      context, Routes.sellerIntroVerificationScreen,
                      arguments: {"isResubmitted": isRejected});
                },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: context.color.bannerColor, // Using theme color
            ),
            child: Stack(
              children: [
                // Background decorations (circles to mimic the design)
                PositionedDirectional(
                  start: -30,
                  top: 10,
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: context.color.buttonColor.withOpacity(0.3),
                  ),
                ),
                PositionedDirectional(
                  start: 30,
                  top: 50,
                  child: CircleAvatar(
                    radius: 3,
                    backgroundColor: context.color.buttonColor.withOpacity(0.3),
                  ),
                ),
                PositionedDirectional(
                  start: 100,
                  top: 20,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: context.color.buttonColor.withOpacity(0.3),
                  ),
                ),
                PositionedDirectional(
                  start: 80,
                  bottom: 40,
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: context.color.buttonColor.withOpacity(0.3),
                  ),
                ),
                PositionedDirectional(
                  end: 120,
                  top: 50,
                  child: CircleAvatar(
                    radius: 2,
                    backgroundColor: context.color.buttonColor.withOpacity(0.3),
                  ),
                ),
                PositionedDirectional(
                  end: 20,
                  bottom: 80,
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: context.color.buttonColor.withOpacity(0.3),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Badge Image
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(end: 12.0),
                              child: Image.asset(
                                "assets/verifiyedbanner.png",
                                height: 80, // Adjust size as needed
                                width: 80,
                                fit: BoxFit.contain,
                              ),
                            ),

                            // Text Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // Align text to start
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isPending
                                        ? "Verification in Process"
                                        : "gotVerifiedBadge".translate(context),
                                    style: TextStyle(
                                        // Using fixed style to match design
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: context.color.buttonColor,
                                        height: 1.2),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isPending
                                        ? "We are currently reviewing your documents. You will be notified once the process is complete."
                                        : "enhanceVisibilityCredibility"
                                            .translate(context),
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: context.color.buttonColor
                                            .withOpacity(0.9),
                                        height: 1.2),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isPending
                              ? null
                              : () {
                                  Navigator.pushNamed(context,
                                      Routes.sellerIntroVerificationScreen,
                                      arguments: {"isResubmitted": isRejected});
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.color.buttonColor,
                            foregroundColor: context.color
                                .territoryColor, // Red color from theme usually
                            disabledBackgroundColor:
                                context.color.buttonColor.withOpacity(0.6),
                            disabledForegroundColor:
                                context.color.territoryColor.withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isPending
                                ? "In Process"
                                : "getStarted".translate(context),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
