import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Ebozor/data/cubits/report/fetch_item_report_reason_list.dart';
import 'package:Ebozor/data/cubits/report/item_report_cubit.dart';
import 'package:Ebozor/data/model/report_item/reason_model.dart';
import 'package:Ebozor/ui/screens/native_ads_screen.dart';
import 'package:Ebozor/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/utils/helper_utils.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool isShowReportAds = true;
  List<ReportReason>? reasons = [];
  late int selectedId;
  final TextEditingController _reportmessageController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    context.read<FetchItemReportReasonsListCubit>().fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: "",
        backgroundColor: context.color.backgroundColor,
        hideTopBorder: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sales Marketing Executive",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.color.textDefaultColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Transport & Construction Communication...",
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              context.color.textDefaultColor.withOpacity(0.6),
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 60,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(
                          "https://picsum.photos/seed/job_details/200"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _buildInfoRow(context, "assets/svg/negotiable.svg", "Negotiable"),
            _buildInfoRow(
                context, "assets/svg/location_icon.svg", "Thoban , Fujeirah"),
            _buildInfoRow(context, "assets/svg/fulltimejob.svg", "Full Time"),
            _buildInfoRow(
                context, "assets/svg/jobexperienceicon.svg", "2-5 Years"),
            _buildInfoRow(context, "assets/svg/gendericon.svg",
                "Any"), // Using profile icon for Gender as placeholder

            const SizedBox(height: 14),
            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF191919), // Dark/Black
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () {},
                child: const Text(
                  "Apply",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Status
            RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 14, color: context.color.textDefaultColor),
                children: [
                  const TextSpan(
                    text: "37 Applications . ",
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                  const TextSpan(
                    text: "Posted 3 Hours Ago",
                    style: TextStyle(
                      color: Color(0xFF26A69A), // Teal color
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Job Details
            Text(
              "Job Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.color.textDefaultColor,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Free Download Intersex 19 SVG Vector File In Monocolor And Multicolor Type For Sketch And Figma From Intersex 19 Vectors Svg Vector Collection. Intersex 19 Vectors SVG Vector Illustration\n\nقم بتنزيل ملف Intersex 19 SVG مجانًا، بنسختيه أحادية اللون ومتعددة الألوان، لاستخدامه في Sketch وFigma. من مجموعة Intersex 19 Vectors. رسم توضيحي بصيغة Intersex 19 لـ SVG.",
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: context.color.textDefaultColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Read More",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),
            // Key Value Rows
            _buildAttributeRow(
                context, "Minimum \nEducation Level", "Bachelors Degree"),
            _buildAttributeRow(context, "Company Size", "51-200 Employees"),
            _buildAttributeRow(context, "Industry", "Transportation"),
            _buildAttributeRow(context, "Remote Job", "NO"),
            const SizedBox(height: 14),
            Divider(color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 4),
            setReportAd(),
            Divider(color: Colors.grey.withOpacity(0.3)),
            // Illustration
            if (Constant.isGoogleBannerAdsEnabled == "1") ...[
              Container(
                height: 90,
                alignment: AlignmentDirectional.center,
                child: NativeAdWidget(type: TemplateType.small),
              ),
              const SizedBox(height: 10),
            ],

            // Footer Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.color.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "6 More Steps to get hired faster",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.color.textDefaultColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          "assets/svg/jobprofileicon.svg",
                          width: 26,
                          height: 26,
                          colorFilter: ColorFilter.mode(
                              Color(0xB2000000), BlendMode.srcIn),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Add Basic Info",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: context.color.textDefaultColor,
                            ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.3))),
                          child: const Center(
                            child:
                                Icon(Icons.add, color: Colors.blue, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        6,
                        (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == 0
                                    ? Colors.grey[600]
                                    : Colors.grey[300],
                              ),
                            )),
                  ),



                  //footer appl button

                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF191919), // Dark/Black
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () {},
                child: const Text(
                  "Apply",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                height: 3.5,
                width: 94.3,
                decoration: BoxDecoration(
                  color: context.color.deactivateColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10.50),
                ),
              ),
            ),
            const SizedBox(height: 12),

          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String iconPath, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              Color(0xB2000000),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: context.color.textDefaultColor.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 14,
                color: context.color.textDefaultColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            height: 2,
            width: 6,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: Colors.grey,
              border: Border.all(width: 2, color: Colors.grey.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                ),
                Text(
                  value,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.color.textDefaultColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget setReportAd() {
    if (!isShowReportAds) return SizedBox.shrink();

    return BlocListener<ItemReportCubit, ItemReportState>(
      listener: (context, state) {
        if (state is ItemReportFailure) {
          debugPrint("Report Ad Failure: ${state.error}");
          HelperUtils.showSnackBarMessage(context, "Failed to report ad");
        }
        if (state is ItemReportInSuccess) {
          HelperUtils.showSnackBarMessage(
              context, state.responseMessage.toString());
        }

        if (!Constant.isDemoModeOn && state is ItemReportInSuccess)
          setState(() {
            isShowReportAds = false;
          });
      },
      child: Column(
        children: [
          SizedBox(
            height: 10,
          ),
          InkWell(
            onTap: () {
              UiUtils.checkUser(
                  onNotGuest: () {
                    _bottomSheet(0); // Dummy Item ID
                  },
                  context: context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: Color(0xB2000000),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text("reportThisAd".translate(context))
                      .color(context.color.textDefaultColor)
                      .size(context.font.large)
                      .bold(weight: FontWeight.w500),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 12,
          ),
        ],
      ),
    );
  }

  Future<void> _bottomSheet(int itemId) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
          title: "reportItem".translate(context),
          content: reportReason(),
          isAcceptContainesPush: true,
          onAccept: () => Future.value().then((_) {
                if (selectedId.isNegative) {
                  if (_formKey.currentState!.validate()) {
                    context.read<ItemReportCubit>().report(
                          item_id: itemId,
                          reason_id: selectedId,
                          message: _reportmessageController.text,
                        );
                    Navigator.pop(context);
                    return;
                  }
                } else {
                  context.read<ItemReportCubit>().report(
                        item_id: itemId,
                        reason_id: selectedId,
                      );
                  Navigator.pop(context);
                  return;
                }
              })),
    );
  }

  Widget reportReason() {
    double bottomPadding = MediaQuery.of(context).viewInsets.bottom - 50;
    bool isBottomPaddingNegative = bottomPadding.isNegative;
    reasons = context.read<FetchItemReportReasonsListCubit>().getList() ?? [];

    if (reasons!.isEmpty) {
      selectedId = -10;
    } else {
      selectedId = reasons!.first.id;
    }
    setState(() {});
    return StatefulBuilder(builder: (context, setState) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: reasons?.length ?? 0,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 10);
                  },
                  itemBuilder: (context, index) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          selectedId = reasons![index].id;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.color.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedId == reasons![index].id
                                ? context.color.territoryColor
                                : context.color.borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Text(
                            reasons![index].reason.firstUpperCase() ?? "",
                          ).color(
                            selectedId == reasons![index].id
                                ? context.color.territoryColor
                                : context.color.textColorDark,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (selectedId.isNegative)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      bottom: isBottomPaddingNegative ? 0 : bottomPadding,
                      start: 0,
                      end: 0,
                    ),
                    child: TextFormField(
                      maxLines: null,
                      controller: _reportmessageController,
                      cursorColor: context.color.territoryColor,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "addReportReason".translate(context);
                        } else {
                          return null;
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "writeReasonHere".translate(context),
                        focusColor: context.color.territoryColor,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: context.color.territoryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
