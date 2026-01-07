import 'dart:async'; // Search debounce
import 'dart:developer';
import 'dart:io';

import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/ui/screens/home/home_screen.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';

import 'package:Ebozor/utils/ui_utils.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:Ebozor/utils/helper_utils.dart';
import 'package:Ebozor/utils/google_geocoding_helper.dart';
import 'package:Ebozor/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:Ebozor/data/cubits/home/fetch_home_screen_cubit.dart';
import 'package:Ebozor/ui/screens/item/add_item_screen/confirm_location_screen.dart';
import 'package:Ebozor/ui/screens/widgets/animated_routes/blur_page_route.dart';

class NearbyLocationScreen extends StatefulWidget {
  final String from;

  const NearbyLocationScreen({
    super.key,
    required this.from,
  });

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;

    return BlurredRouter(
        builder: (context) => NearbyLocationScreen(
              from: arguments?['from'],
            ));
  }

  @override
  NearbyLocationScreenState createState() => NearbyLocationScreenState();
}

class NearbyLocationScreenState extends State<NearbyLocationScreen>
    with WidgetsBindingObserver {
  double radius = 1.0;
  late GoogleMapController mapController;
  CameraPosition? _cameraPosition;
  final Set<Marker> _markers = Set();
  Set<Circle> circles = Set.from([]);
  var markerMove = false;
  bool _openedAppSettings = false;
  String currentLocation = '';
  double? latitude, longitude;
  AddressComponent? formatedAddress;

  // Search related
  TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission;

    // Check location permission status
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      if (Platform.isAndroid) {
        await Geolocator.openLocationSettings();
        _getCurrentLocation();
      }
      _showLocationServiceInstructions();
    } else if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setDefaultLocation();
      } else {
        _getCurrentLocation();
      }
    } else {
      // Permission is granted, proceed to get the current location
      preFillLocationWhileEdit();
    }
  }

  void setDefaultLocation() {
    latitude = double.parse(Constant.defaultLatitude);
    longitude = double.parse(Constant.defaultLongitude);
    getLocationFromLatitudeLongitude(latLng: LatLng(latitude!, longitude!));
    _cameraPosition = CameraPosition(
      target: LatLng(latitude!, longitude!),
      zoom: 14.4746,
      bearing: 0,
    );
    _markers.add(Marker(
      markerId: const MarkerId('currentLocation'),
      position: LatLng(latitude!, longitude!),
    ));
    _addCircle(LatLng(latitude!, longitude!), radius);
    setState(() {});
  }

  Future<void> preFillLocationWhileEdit() async {
    latitude = HiveUtils.getLatitude();
    longitude = HiveUtils.getLongitude();
    if (latitude != "" &&
        latitude != null &&
        longitude != "" &&
        longitude != null) {
      getLocationFromLatitudeLongitude(latLng: LatLng(latitude!, longitude!));
      _cameraPosition = CameraPosition(
        target: LatLng(latitude!, longitude!),
        zoom: 14.4746,
        bearing: 0,
      );
      _markers.add(Marker(
        markerId: const MarkerId('currentLocation'),
        position: LatLng(latitude!, longitude!),
      ));
      _addCircle(LatLng(latitude!, longitude!), radius);
      setState(() {});
    } else {
      currentLocation = [
        HiveUtils.getCurrentAreaName(),
        HiveUtils.getCurrentCityName(),
        HiveUtils.getCurrentStateName(),
        HiveUtils.getCurrentCountryName()
      ].where((part) => part != null && part.isNotEmpty).join(', ');
      if (currentLocation == "") {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        print(
            "DEBUG: Raw Position (preFill) - Lat:${position.latitude}, Lng:${position.longitude}");
        _cameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.4746,
          bearing: 0,
        );
        getLocationFromLatitudeLongitude(
            latLng: LatLng(position.latitude, position.longitude));
        _markers.add(Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(position.latitude, position.longitude),
        ));
        latitude = position.latitude;
        longitude = position.longitude;
        _addCircle(LatLng(position.latitude, position.longitude), radius);
      } else {
        formatedAddress = AddressComponent(
            area: HiveUtils.getCurrentAreaName(),
            areaId: null,
            city: HiveUtils.getCurrentCityName(),
            country: HiveUtils.getCurrentCountryName(),
            state: HiveUtils.getCurrentStateName());
        latitude = HiveUtils.getCurrentLatitude();
        longitude = HiveUtils.getCurrentLongitude();
        _cameraPosition = CameraPosition(
          target: LatLng(latitude!, longitude!),
          zoom: 14.4746,
          bearing: 0,
        );
        _addCircle(LatLng(latitude!, longitude!), radius);
        getLocationFromLatitudeLongitude(latLng: LatLng(latitude!, longitude!));
        _markers.add(Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(latitude!, longitude!),
        ));
      }
    }

    setState(() {});
  }

  Future<void> getLocationFromLatitudeLongitude({LatLng? latLng}) async {
    try {
      if (Platform.isIOS) {
        var googleAddress = await GoogleGeocodingHelper.getAddress(
            latLng?.latitude ?? _cameraPosition!.target.latitude,
            latLng?.longitude ?? _cameraPosition!.target.longitude);
        if (googleAddress != null) {
          formatedAddress = AddressComponent(
              area: googleAddress['area'],
              areaId: null,
              city: googleAddress['city'],
              country: googleAddress['country'],
              state: googleAddress['state']);
        }
      } else {
        Placemark? placeMark = (await placemarkFromCoordinates(
                latLng?.latitude ?? _cameraPosition!.target.latitude,
                latLng?.longitude ?? _cameraPosition!.target.longitude))
            .first;

        formatedAddress = AddressComponent(
            area: placeMark.subLocality,
            areaId: null,
            city: placeMark.locality,
            country: placeMark.country,
            state: placeMark.administrativeArea);
      }

      // Update Search Text Only if not focusing? No, user wants to see current location text probably.
      // But if user is typing, we shouldn't overwrite.
      // We can update it if it's empty or we just fetched location from map drag/current location tap.
      // Let's format address for text field
      if (formatedAddress != null) {
        List<String> addressParts = [];
        if (formatedAddress!.area != null && formatedAddress!.area!.isNotEmpty)
          addressParts.add(formatedAddress!.area!);
        if (formatedAddress!.city != null && formatedAddress!.city!.isNotEmpty)
          addressParts.add(formatedAddress!.city!);
        if (formatedAddress!.state != null &&
            formatedAddress!.state!.isNotEmpty)
          addressParts.add(formatedAddress!.state!);
        if (formatedAddress!.country != null &&
            formatedAddress!.country!.isNotEmpty)
          addressParts.add(formatedAddress!.country!);

        // Only update text if user is NOT searching (we can track this via focus or just policy)
        // Usually good UX: Set text on map idle/click, but don't interrupt typing.
        // Since this function is called on tap or map idle, updating text is consistent.
        // However, be careful with the debounce loop.
        // If this was triggered by search, we might not want to overwrite formatted query?
        // Actually, replacing query with standardized address is usually fine after search completes.

        // To avoid cursor jumping if user is typing and this gets called, we might check active focus or if came from search.
        // For now, let's update it to provide feedback on "What location did I pick?".
        if (!searchController.selection.isValid ||
            searchController.text.isEmpty) {
          // Simple check
          searchController.text = addressParts.join(", ");
        } else {
          // If text exists, we might overwrite it unless it matches current location...
          // Let's just overwrite it as "Confirmation" of location found.
          // But if user is typing "New Y", we don't want to replace with "Old Location" before they finish.
          // This method is called on CameraIdle. If user types -> search -> camera moves -> idle -> this called.
          // So overwriting is OK as it "Corrects" the input.
          searchController.text = addressParts.join(", ");
        }
      }

      print("DEBUG: Fetched Location - Lat: $latitude, Lng: $longitude");
      print("DEBUG: Address: ${formatedAddress?.city}"); // Simplified print

      setState(() {});
    } catch (e) {
      log(e.toString());
      formatedAddress = null;
      setState(() {});
    }
  }

  void _showLocationServiceInstructions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('pleaseEnableLocationServicesManually'.translate(context)),
        action: SnackBarAction(
          label: 'ok'.translate(context),
          textColor: context.color.secondaryColor,
          onPressed: () {
            openAppSettings();
            setState(() {
              _openedAppSettings = true;
            });

            // Optionally handle action button press
          },
        ),
      ),
    );
  }

  // Search Function
  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 1000), () {
      if (query.isNotEmpty) {
        _searchLocation(query);
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location loc = locations.first;
        LatLng newPos = LatLng(loc.latitude, loc.longitude);

        setState(() {
          latitude = loc.latitude;
          longitude = loc.longitude;
          _markers.clear();
          _markers.add(Marker(
              markerId: const MarkerId('searchedLocation'), position: newPos));
          _cameraPosition = CameraPosition(target: newPos, zoom: 14.4746);

          _addCircle(newPos, radius);
        });

        mapController.animateCamera(CameraUpdate.newLatLng(newPos));
        getLocationFromLatitudeLongitude(latLng: newPos);
      }
    } catch (e) {
      log("Search Error: $e");
      // Optionally show toast "Location not found"
    }
  }

  void _addCircle(LatLng position, double radiusInKm) {
    // Fix: Prevent executing with null position, although LatLng shouldn't have nulls, defensive check.
    if (latitude == null || longitude == null) return;

    // Ensure radius is treated as integer then converted back to double for metrics if needed
    // User wants "slider static", "height reduced", "color fix".
    // AND "radius is integer" implicitly from UI (1..100).
    final double radiusInMeters = radiusInKm * 1000; // Convert km to meters

    setState(() {
      circles.clear(); // Clear any existing circles
      circles.add(
        Circle(
          circleId: CircleId("radius_circle"),
          center: position,
          radius: radiusInMeters,
          // Set radius in meters
          fillColor: context.color.territoryColor.withOpacity(0.15),
          strokeColor: context.color.territoryColor,
          strokeWidth: 2,
        ),
      );
    });
  }

  Widget bottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          color: context.color.backgroundColor,
          thickness: 1.5,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          child: Column(
            children: [
              UiUtils.buildButton(context, radius: 8, fontSize: 16,
                  onPressed: () {
                setState(() {
                  radius = 1;
                  searchController.clear(); // Clear search on reset
                  _addCircle(LatLng(latitude!, longitude!), radius);
                });
              },
                  buttonTitle: "reset".translate(context),
                  height: 48,
                  border: BorderSide(color: context.color.territoryColor),
                  textColor: context.color.territoryColor,
                  buttonColor: context.color.secondaryColor),
              const SizedBox(height: 10),
              UiUtils.buildButton(context, radius: 8, fontSize: 16,
                  onPressed: () {
                print("DEBUG: Apply Button CLICKED in UI");
                HiveUtils.setNearbyRadius(radius.toInt());
                applyOnPressed();
              },
                  buttonTitle: "apply".translate(context),
                  height: 48,
                  textColor: context.color.buttonColor,
                  buttonColor: context.color.territoryColor),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void applyOnPressed() {
    print("DEBUG: applyOnPressed function ENTERED");
    if (formatedAddress == null) {
      print("DEBUG: ERROR - formatedAddress is NULL. Cannot apply location.");
      return;
    }

    print("DEBUG: Apply Pressed - Applying Location:");
    print("City: ${formatedAddress!.city}");
    print("State: ${formatedAddress!.state}");
    print("Country: ${formatedAddress!.country}");
    print("Coordinates: $latitude, $longitude");

    if (widget.from == "home") {
      HiveUtils.setLocation(
          city: formatedAddress!.city,
          state: formatedAddress!.state,
          area: formatedAddress!.area,
          country: formatedAddress!.country,
          latitude: latitude,
          longitude: longitude);

      Future.delayed(
        Duration.zero,
        () {
          context.read<FetchHomeScreenCubit>().fetch(
              country: formatedAddress!.country,
              state: formatedAddress!.state,
              city: formatedAddress!.city);
          context.read<FetchHomeAllItemsCubit>().fetch(
              country: formatedAddress!.country,
              state: formatedAddress!.state,
              city: formatedAddress!.city,
              radius: radius.toInt(),
              latitude: latitude,
              longitude: longitude);
        },
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (widget.from == "location") {
      HiveUtils.setLocation(
          city: formatedAddress!.city,
          state: formatedAddress!.state,
          area: formatedAddress!.area,
          country: formatedAddress!.country,
          latitude: latitude,
          longitude: longitude);
      Map<String, dynamic> result = {
        'area_id': null,
        'area': formatedAddress!.area,
        'state': formatedAddress!.state,
        'country': formatedAddress!.country,
        'city': formatedAddress!.city,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius.toInt() // Add radius to result
      };
      Navigator.pop(context);
      Navigator.pop(context, result);
    } else {
      Map<String, dynamic> result = {
        'area_id': null,
        'area': formatedAddress!.area,
        'state': formatedAddress!.state,
        'country': formatedAddress!.country,
        'city': formatedAddress!.city,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius.toInt()
      };
      Navigator.pop(context);
      Navigator.pop(context, result);
    }
  }

  Set<Factory<OneSequenceGestureRecognizer>> getMapGestureRecognizers() {
    return <Factory<OneSequenceGestureRecognizer>>{}
      ..add(Factory<PanGestureRecognizer>(
          () => PanGestureRecognizer()..onUpdate = (dragUpdateDetails) {}))
      ..add(Factory<ScaleGestureRecognizer>(
          () => ScaleGestureRecognizer()..onStart = (dragUpdateDetails) {}))
      ..add(Factory<TapGestureRecognizer>(() => TapGestureRecognizer()))
      ..add(Factory<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer()
            ..onDown = (dragUpdateDetails) {
              if (markerMove == false) {
              } else {
                setState(() {
                  markerMove = false;
                });
              }
            }));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.backgroundColor,
      ),
      child: Scaffold(
        bottomNavigationBar: bottomBar(),
        backgroundColor: context.color.backgroundColor,
        appBar: UiUtils.buildAppBar(context,
            showBackButton: true,
            title: "nearbyListings".translate(context),
            backgroundColor: context.color.backgroundColor),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: sidePadding),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      child: _cameraPosition != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: context.color.backgroundColor,
                                    ),
                                    child: GoogleMap(
                                      onCameraMove: (position) {
                                        _cameraPosition = position;
                                      },
                                      onCameraIdle: () async {
                                        if (markerMove == false) {
                                          if (LatLng(latitude!, longitude!) ==
                                              LatLng(
                                                  _cameraPosition!
                                                      .target.latitude,
                                                  _cameraPosition!
                                                      .target.longitude)) {
                                          } else {
                                            getLocationFromLatitudeLongitude();
                                          }
                                        }
                                      },
                                      initialCameraPosition: _cameraPosition!,
                                      circles: circles,
                                      markers: _markers,
                                      zoomControlsEnabled: false,
                                      minMaxZoomPreference:
                                          const MinMaxZoomPreference(0, 16),
                                      compassEnabled: true,
                                      indoorViewEnabled: true,
                                      mapToolbarEnabled: true,
                                      myLocationButtonEnabled: true,
                                      mapType: MapType.normal,
                                      gestureRecognizers:
                                          getMapGestureRecognizers(),
                                      onMapCreated:
                                          (GoogleMapController controller) {
                                        Future.delayed(const Duration(
                                                milliseconds: 500))
                                            .then((value) {
                                          mapController = (controller);
                                          mapController.animateCamera(
                                            CameraUpdate.newCameraPosition(
                                              _cameraPosition!,
                                            ),
                                          );
                                        });
                                      },
                                      onTap: (latLng) {
                                        setState(() {
                                          _markers.clear();
                                          _markers.add(Marker(
                                            markerId:
                                                MarkerId('selectedLocation'),
                                            position: latLng,
                                          ));
                                          latitude = latLng.latitude;
                                          longitude = latLng.longitude;

                                          getLocationFromLatitudeLongitude(
                                              latLng: latLng);
                                          _addCircle(
                                              LatLng(latitude!, longitude!),
                                              radius);
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                // Search Bar Overlay
                                Positioned(
                                  top: 15,
                                  left: 15,
                                  right: 15,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: context.color.secondaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: searchController,
                                      onChanged: _onSearchChanged,
                                      decoration: InputDecoration(
                                        hintText: "Search location...",
                                        border: InputBorder.none,
                                        prefixIcon: Icon(Icons.search,
                                            color:
                                                context.color.textDefaultColor),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 14),
                                      ),
                                    ),
                                  ),
                                ),

                                // Current Location Button
                                PositionedDirectional(
                                  end: 15,
                                  bottom: 15,
                                  child: InkWell(
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: context.color.borderColor,
                                          width: Constant.borderWidth,
                                        ),
                                        color: context.color.secondaryColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.my_location_sharp,
                                        color: context.color.territoryColor,
                                      ),
                                    ),
                                    onTap: () async {
                                      searchController.clear();
                                      Position position =
                                          await Geolocator.getCurrentPosition(
                                        desiredAccuracy: LocationAccuracy.high,
                                      );

                                      _markers.clear();
                                      _markers.add(Marker(
                                        markerId: MarkerId('selectedLocation'),
                                        position: LatLng(position.latitude,
                                            position.longitude),
                                      ));

                                      _cameraPosition = CameraPosition(
                                        target: LatLng(position.latitude,
                                            position.longitude),
                                        zoom: 14.4746,
                                        bearing: 0,
                                      );
                                      latitude = position.latitude;
                                      longitude = position.longitude;
                                      getLocationFromLatitudeLongitude();
                                      _addCircle(
                                          LatLng(position.latitude,
                                              position.longitude),
                                          radius);
                                      mapController.animateCamera(
                                        CameraUpdate.newCameraPosition(
                                            _cameraPosition!),
                                      );
                                      setState(() {});
                                    },
                                  ),
                                )
                              ],
                            )
                          : Center(child: UiUtils.progress()),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Section for Slider
            Container(
              color: context.color.backgroundColor,
              padding: const EdgeInsets.only(bottom: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: sidePadding),
                    child: Text(
                      'selectAreaRange'.translate(context),
                    )
                        .color(context.color.textDefaultColor)
                        .bold(weight: FontWeight.w600),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    height: 30, // Reduced height for the slider container
                    child: Slider(
                      value: radius,
                      min: 1,
                      max: 100,
                      divisions: 99,
                      activeColor: context.color.territoryColor,
                      thumbColor: context.color.territoryColor,
                      label: '${radius.toInt()}\t${"km".translate(context)}',
                      onChanged: (value) {
                        setState(() {
                          radius = value;
                          if (latitude != null && longitude != null) {
                            _addCircle(LatLng(latitude!, longitude!), radius);
                          }
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: sidePadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1\t${"km".translate(context)}')
                            .color(context.color.textDefaultColor)
                            .bold(weight: FontWeight.w500),
                        Text('100\t${"km".translate(context)}')
                            .color(context.color.textDefaultColor)
                            .bold(weight: FontWeight.w500),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
