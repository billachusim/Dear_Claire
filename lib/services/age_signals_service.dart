import 'package:age_range_signals/age_range_signals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Age bands from Play Age Signals (Android) / DeclaredAgeRange (iOS).
///
/// These match the brackets in California's Digital Age Assurance Act
/// (AB 1043): under 13, 13-15, 16-17, 18+.
enum AgeBand { under13, teen13to15, teen16to17, adult, unknown }

extension AgeBandX on AgeBand {
  bool get isMinor =>
      this == AgeBand.under13 ||
      this == AgeBand.teen13to15 ||
      this == AgeBand.teen16to17;

  String get key => name;

  static AgeBand fromKey(String? key) => AgeBand.values
      .firstWhere((b) => b.name == key, orElse: () => AgeBand.unknown);
}

/// Requests the user's age band from the app store on every launch and keeps
/// the latest answer.
///
/// Laws in California (from 1 Jan 2027), Brazil (Digital ECA) and Texas
/// require apps to request this signal on download/launch and to treat it as
/// actual knowledge of the user's age. Only the band is stored, never a birth
/// date.
///
/// This file is shared across our Flutter apps; keep it self-contained so it
/// can be copied as-is.
class AgeSignalsService {
  AgeSignalsService._();
  static final AgeSignalsService instance = AgeSignalsService._();

  static const _prefsBandKey = 'age_signals_band';
  static const _prefsVerificationKey = 'age_signals_verification_required';

  /// Latest known band. Starts from the cached value, then updates after the
  /// store answers.
  final ValueNotifier<AgeBand> band = ValueNotifier(AgeBand.unknown);

  /// True when the store says the user must verify their age in the Play
  /// Store app before a signal is available (mandatory-sharing regions).
  bool verificationRequired = false;

  bool _started = false;

  bool get isMinor => band.value.isMinor;
  bool get isUnder13 => band.value == AgeBand.under13;

  /// Loads the cached band, then asks the store in the background.
  /// Safe to call more than once; only the first call per launch runs.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _loadCached();
    // Do not block app start-up on the store.
    _refresh();
  }

  Future<void> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      band.value = AgeBandX.fromKey(prefs.getString(_prefsBandKey));
      verificationRequired = prefs.getBool(_prefsVerificationKey) ?? false;
      await _applyAdsConfig();
    } catch (e) {
      debugPrint('AgeSignals: cache read failed: $e');
    }
  }

  Future<void> _refresh() async {
    if (kIsWeb) return;
    try {
      final plugin = AgeRangeSignals.instance;
      await plugin.initialize(ageGates: const [13, 16, 18]);

      final result = await plugin.checkAgeSignals();
      switch (result.status) {
        case AgeSignalsStatus.verified:
          // Verified 18+ (Android) or meets the highest gate (iOS).
          await _save(
              result.ageLower != null || result.ageUpper != null
                  ? _bandFrom(result.ageLower, result.ageUpper)
                  : AgeBand.adult,
              verification: false);
        case AgeSignalsStatus.declined:
        case AgeSignalsStatus.unknown:
          // Not shared or not available here. Keep any band we already knew.
          verificationRequired = false;
        default:
          // Supervised, declared, or approval pending/denied: use the range.
          await _save(_bandFrom(result.ageLower, result.ageUpper),
              verification: false);
      }
    } on AgeSignalsException catch (e) {
      // Unsupported OS version, no Play Store, offline, etc.
      debugPrint('AgeSignals: ${e.runtimeType}: $e');
    } catch (e) {
      debugPrint('AgeSignals: unexpected error: $e');
    }
  }

  static AgeBand _bandFrom(int? lower, int? upper) {
    if (lower == null && upper == null) return AgeBand.unknown;
    if (upper != null && upper < 13) return AgeBand.under13;
    if (lower != null && lower >= 18) return AgeBand.adult;
    if (upper != null && upper <= 15) return AgeBand.teen13to15;
    if (upper != null && upper <= 17) return AgeBand.teen16to17;
    // Open-ended or wide range below 18: be conservative.
    if (lower != null && lower >= 16) return AgeBand.teen16to17;
    if (lower != null && lower >= 13) return AgeBand.teen13to15;
    return AgeBand.unknown;
  }

  Future<void> _save(AgeBand newBand, {required bool verification}) async {
    // An unknown answer never overwrites a band we already know.
    if (newBand != AgeBand.unknown) band.value = newBand;
    verificationRequired = verification;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsBandKey, band.value.key);
      await prefs.setBool(_prefsVerificationKey, verification);
    } catch (_) {}
    await _applyAdsConfig();
    if (newBand == AgeBand.unknown) return;
    try {
      await FirebaseAnalytics.instance
          .setUserProperty(name: 'age_band', value: newBand.key);
    } catch (_) {}
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'ageBand': newBand.key,
        'ageBandUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AgeSignals: profile write failed: $e');
    }
  }

  /// Minors only get non-personalised ads.
  Future<void> _applyAdsConfig() async {
    try {
      final current = await MobileAds.instance.getRequestConfiguration();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: current.testDeviceIds,
          tagForUnderAgeOfConsent: isMinor
              ? TagForUnderAgeOfConsent.yes
              : TagForUnderAgeOfConsent.unspecified,
          tagForChildDirectedTreatment: isUnder13
              ? TagForChildDirectedTreatment.yes
              : TagForChildDirectedTreatment.unspecified,
          maxAdContentRating:
              isMinor ? MaxAdContentRating.t : current.maxAdContentRating,
        ),
      );
    } catch (e) {
      debugPrint('AgeSignals: ads config failed: $e');
    }
  }
}
