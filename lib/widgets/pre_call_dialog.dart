import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ui/ego-profile/top_up_loves_page.dart';

// A model to hold the data from the dialog
class CallSetupDetails {
  final String title;
  final int moodId;
  final bool isPrivate;
  final bool repliesEnabled;
  final bool locationEnabled;
  final String locationData;

  CallSetupDetails({
    required this.title,
    required this.moodId,
    required this.isPrivate,
    required this.repliesEnabled,
    required this.locationEnabled,
    required this.locationData,
  });
}

/// Shows a pre-call setup dialog and returns the details if the user proceeds.
Future<CallSetupDetails?> showPreCallDialog(BuildContext context, {required bool isVideoCall}) async {
  final TextEditingController titleController = TextEditingController(text: isVideoCall ? "Live Session" : "Companion Call");

  String selectedMood = AppConstants.USER_SESSION_MOODS[17]; // Default to Claire mood 🌺
  bool isPrivate = true;
  bool repliesEnabled = false;
  bool locationEnabled = false;
  String locationData = '';
  bool isFetchingLocation = false;
  bool _isVerifying = false;

  // --- Location fetching logic from setup_autoDiary_widget.dart ---
  Future<void> determinePositionAndSave(Function(void Function()) setState) async {
    setState(() => isFetchingLocation = true);
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showToast('Location services are disabled.');
      setState(() {
        locationEnabled = false;
        isFetchingLocation = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showToast('Location permissions are denied.');
        setState(() {
          locationEnabled = false;
          isFetchingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showToast('Location permissions are permanently denied. Please enable it from settings.');
      openAppSettings();
      setState(() {
        locationEnabled = false;
        isFetchingLocation = false;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      locationData = "in ${place.administrativeArea}, ${place.country}";
      showToast("Location captured: $locationData");
    } catch (e) {
      showToast("Could not determine location.");
      locationEnabled = false; // Toggle back if fetching fails
    } finally {
      setState(() => isFetchingLocation = false);
    }
  }

  return showDialog<CallSetupDetails>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Pallet.colorBottomNav,
            title: Text(
              isVideoCall ? 'Prepare Live Session' : 'Prepare Companion Call',
              style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Title Field ---
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Call Title',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Pallet.colorSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Mood Selector ---
                  Text('Set a Mood', style: TextStyle(color: Colors.white70)),
                  DropdownButton<String>(
                    value: selectedMood,
                    isExpanded: true,
                    dropdownColor: Pallet.colorBottomNav,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMood = newValue!;
                      });
                    },
                    items: AppConstants.USER_SESSION_MOODS.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // --- Privacy Toggles ---
                  SwitchListTile(
                    title: const Text('Private Session', style: TextStyle(color: Colors.white)),
                    value: isPrivate,
                    onChanged: (bool value) => setState(() => isPrivate = value),
                    activeThumbColor: Pallet.colorSecondary,
                  ),
                  SwitchListTile(
                    title: const Text('Enable Replies', style: TextStyle(color: Colors.white)),
                    value: repliesEnabled,
                    onChanged: (bool value) => setState(() => repliesEnabled = value),
                    activeThumbColor: Pallet.colorSecondary,
                  ),

                  // --- Location Toggle ---
                  SwitchListTile(
                    title: const Text('Tag Location', style: TextStyle(color: Colors.white)),
                    value: locationEnabled,
                    secondary: isFetchingLocation
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : null,
                    onChanged: (bool value) {
                      setState(() => locationEnabled = value);
                      if (value) {
                        determinePositionAndSave(setState);
                      } else {
                        locationData = ''; // Clear location data if toggled off
                      }
                    },
                    activeThumbColor: Pallet.colorSecondary,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                onPressed: () {
                  Navigator.of(context).pop(); // Return null
                },
              ),
              _isVerifying
                  ? const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth:2)),
              )
                  : TextButton(
                child: Text('Start Call', style: TextStyle(color: Pallet.colorSecondary, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  setState(() => _isVerifying = true);

                  try {
                    // 1. Check Love Balance
                    final user = await firebaseServices.getUserInfo();
                    final double balance = (user.currentLoveCount ?? 0).toDouble();

                    if (balance < 500) {
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => TopUpLovesPage(
                              feature: isVideoCall ? 'live_call' : 'companion_call'
                          ),
                        ));
                      }
                      return;
                    }

                    // 2. Proceed if balance is sufficient
                    final details = CallSetupDetails(
                      title: titleController.text.trim().isEmpty
                          ? (isVideoCall ? "Live Session" : "Companion Call")
                          : titleController.text.trim(),
                      moodId: AppConstants.USER_SESSION_MOODS.indexOf(selectedMood),
                      isPrivate: isPrivate,
                      repliesEnabled: repliesEnabled,
                      locationEnabled: locationEnabled,
                      locationData: locationData,
                    );

                    if (context.mounted) Navigator.of(context).pop(details);

                  } catch (e) {
                    showToast("Error verifying balance. Try again.");
                  } finally {
                    if (context.mounted) setState(() => _isVerifying = false);
                  }
                },
              ),

            ],
          );
        },
      );
    },
  );
}
