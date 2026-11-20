import 'dart:io';

import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

/// Getting the app rated: the system's popup ([request]) at a good moment
/// (see [WardrobeStore.maybeAskForReview]) — which the platform may quietly
/// not show (iOS: three times a year at most, never in TestFlight) — and
/// the store's review page ([openStore]), from settings, which always
/// opens.
class ReviewPrompt {
  ReviewPrompt._();

  static const appStoreId = '6802752111';
  static const _playId = 'eu.oscillator.outfits';

  /// The App Store's "write a review" form, or the app's Play page.
  static String get storeUrl => Platform.isAndroid
      ? 'https://play.google.com/store/apps/details?id=$_playId'
      : 'https://apps.apple.com/app/id$appStoreId?action=write-review';

  static Future<bool> openStore() async {
    try {
      return await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// The system's rating popup; returns whether the platform offers it at
  /// all. Best-effort: without the plugin (tests) it quietly does nothing.
  static Future<bool> request() async {
    try {
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return false;
      await review.requestReview();
      return true;
    } catch (_) {
      return false;
    }
  }
}
