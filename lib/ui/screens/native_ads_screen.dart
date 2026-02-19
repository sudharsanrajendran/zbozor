import 'dart:io';

import 'package:Ebozor/ui/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:Ebozor/utils/constant.dart';

class NativeAdWidget extends StatefulWidget {
  final TemplateType type;

  const NativeAdWidget({
    super.key,
    required this.type,
  });

  @override
  _NativeAdWidgetState createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _loadNativeAd();
    });
  }

  void _loadNativeAd() {
    if (Constant.isGoogleNativeAdsEnabled != "1") {
      return;
    }
    _nativeAd = NativeAd(
      adUnitId: Platform.isAndroid
          ? Constant.nativeAdIdAndroid //Android interstitial ad id
          : Constant.nativeAdIdIOS,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
          // Required: Choose a template.
          templateType: widget.type,
          cornerRadius: 10.0),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
            _opacity = 1.0;
          });
        },
        onAdFailedToLoad: (ad, error) {
          setState(() {
            _isAdLoaded = false;
            ad.dispose();
            print('Native ad failed to load: $error');
          });
        },
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _opacity,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 200, // minimum recommended width
            minHeight: 200, // minimum recommended height
            maxWidth: 250,
            maxHeight: 200,
          ),
          margin: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 10),
          //padding: EdgeInsets.all(15),

          child: AdWidget(ad: _nativeAd!),
        ),
      );
    }

    return Container();
  }
}
