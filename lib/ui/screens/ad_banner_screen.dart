import 'dart:io';

import 'package:Ebozor/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  @override
  _AdBannerWidgetState createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  late BannerAd _bannerAd;
  double _opacity = 0.0;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? Constant.bannerAdIdAndroid

          ///Android key
          : Constant.bannerAdIdIOS,

      ///ios key
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
            _opacity = 1.0;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _bannerAd.load();
    });
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) return const SizedBox.shrink();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _opacity,
      child: Container(
        width: _bannerAd.size.width.toDouble(),
        height: _bannerAd.size.height.toDouble(),
        child: AdWidget(
          ad: _bannerAd,
        ),
      ),
    );
  }
}
