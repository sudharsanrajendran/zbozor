import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:Ebozor/utils/app_icon.dart';
import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/utils/helper_utils.dart';
import 'package:Ebozor/data/cubits/report/fetch_item_report_reason_list.dart';
import 'package:Ebozor/data/cubits/report/item_report_cubit.dart';
import 'package:Ebozor/data/model/report_item/reason_model.dart';
import 'package:Ebozor/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HiretalentDetailsScreen extends StatefulWidget {
  const HiretalentDetailsScreen({super.key});

  @override
  State<HiretalentDetailsScreen> createState() =>
      _HiretalentDetailsScreenState();
}

class _HiretalentDetailsScreenState extends State<HiretalentDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  bool _isFavorite = false;
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
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset > 50) {
      if (!_showTitle) setState(() => _showTitle = true);
    } else {
      if (_showTitle) setState(() => _showTitle = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.secondaryColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              backgroundColor: context.color.secondaryColor,
              surfaceTintColor: context.color.secondaryColor,
              elevation: 0,
              leading: Material(
                clipBehavior: Clip.antiAlias,
                color: Colors.transparent,
                type: MaterialType.circle,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Directionality(
                      textDirection: Directionality.of(context),
                      child: RotatedBox(
                        quarterTurns: Directionality.of(context) ==
                                dart_ui.TextDirection.rtl
                            ? 2
                            : -4,
                        child: UiUtils.getSvg(AppIcons.arrowLeft,
                            fit: BoxFit.none,
                            color: context.color.textDefaultColor),
                      ),
                    ),
                  ),
                ),
              ),
              title: _showTitle
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Senior Accountant",
                          style: TextStyle(
                            color: context.color.textDefaultColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Al Karama, Dubai, UAE",
                          style: TextStyle(
                            color: context.color.textDefaultColor,
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : null,
              centerTitle: false,
              actions: [
                Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                    child: Center(
                      child: UiUtils.getSvg(
                        _isFavorite ? AppIcons.like_fill : AppIcons.like,
                        color: _isFavorite
                            ? context.color.territoryColor
                            : context.color.textDefaultColor.withOpacity(0.7),
                        width: 22,
                        height: 22,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsetsDirectional.only(end: 16, start: 5),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {},
                    child: Center(
                      child: Icon(
                        Icons.share_outlined,
                        size: 22,
                        color: context.color.textDefaultColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header equivalent when not scrolled (since JobDetailsScreen also had this inside body)
              // The user asked the upper text to disappear and it's basically the big title
              Text(
                "Senior Accountant",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.color.textDefaultColor,
                ),
              ),
              const SizedBox(height: 10),
              Divider(
                  thickness: 1,
                  color: context.color.textDefaultColor.withOpacity(0.1)),
              const SizedBox(height: 10),

              Text(
                "Details",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.color.textDefaultColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow("Work experience", "5-10 Years", context),
              _buildDetailRow("Education level", "Masters Degree", context),
              _buildDetailRow("Commitment", "Full Time", context),
              _buildDetailRow("Desired Salary", "6,000 - 7,999", context),
              _buildDetailRow("Job Role", "Account Executive", context),
              _buildDetailRow("Posted On", "22 Feb, 2026", context),

              const SizedBox(height: 16),
              Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
              const SizedBox(height: 16),

              Text(
                "Description",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.color.textDefaultColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Dear Recruiter,\n\nI am looking for job post of Senior Accountant 10 years of gulf experience Notice period Immediate joiner",
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: context.color.textDefaultColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Show more description",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
              const SizedBox(height: 16),

              Text(
                "locationLbl".translate(context),
              ).bold().size(context.font.large),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3.0),
                    child: SvgPicture.asset(
                      AppIcons.location,
                      colorFilter: ColorFilter.mode(
                          context.color.textDefaultColor.withOpacity(0.3),
                          BlendMode.srcIn),
                      height: 20,
                      width: 20,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: 5.0, top: 3),
                      child: Text("Al Karama, Dubai, UAE")
                          .color(context.color.textLightColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      GoogleMap(
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        compassEnabled: false,
                        mapToolbarEnabled: false,
                        liteModeEnabled: true,
                        zoomGesturesEnabled: false,
                        scrollGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        initialCameraPosition: CameraPosition(
                            target: LatLng(25.2443, 55.3060), zoom: 14),
                        mapType: MapType.normal,
                        markers: {
                          Marker(
                            markerId: MarkerId('currentPosition'),
                            position: LatLng(25.2443, 55.3060),
                          )
                        },
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            // Can add navigation to GoogleMapScreen here if needed later
                          },
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Divider(color: Colors.grey.withOpacity(0.3)),
              const SizedBox(height: 4),
              setReportAd(),
              Divider(color: Colors.grey.withOpacity(0.3)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.color.backgroundColor,
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914), // Red button
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              "See all details and CV of this candidate",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.color.textDefaultColor,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: context.color.textDefaultColor.withOpacity(0.8),
              ),
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

        if (!Constant.isDemoModeOn && state is ItemReportInSuccess) {
          setState(() {
            isShowReportAds = false;
          });
        }
      },
      child: Column(
        children: [
          SizedBox(height: 5),
          InkWell(
            onTap: () {
              UiUtils.checkUser(
                  onNotGuest: () {
                    _bottomSheet(0); // Dummy Item ID or correct item
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
          SizedBox(height: 6),
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
                  itemCount: reasons!.length,
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
                                : context.color.textLightColor.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            reasons![index].reason.toString(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (selectedId == -10 || selectedId == -100) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _reportmessageController,
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a reason";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        hintText: "Reason",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10))),
                  ),
                ],
                if (isBottomPaddingNegative) ...[
                  SizedBox(height: bottomPadding.abs())
                ]
              ],
            ),
          ),
        ),
      );
    });
  }
}
