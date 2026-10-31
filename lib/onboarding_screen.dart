import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'garment_art.dart';
import 'l10n/app_localizations.dart';
import 'settings_screen.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// Shown before [HomeScreen] until [WardrobeStore.completeOnboarding]: a
/// welcome, then the setup a step at a time — look and language, the
/// wardrobe's name, the kinds of clothing, the daily reminder — reusing
/// the controls from settings. Finishing it starts the tour of the app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// 0 is the welcome; the setup steps follow.
  static const _setupSteps = 3;

  /// The kinds a wardrobe starts with — changed later in settings.
  static const _startKinds = {'horni', 'dolni', 'boty'};

  int _step = 0;
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _next() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_step < _setupSteps) {
      setState(() => _step++);
      return;
    }
    final store = context.read<WardrobeStore>();
    store.keepOnlyKinds(_startKinds);
    store.completeOnboarding(wardrobeName: _name.text);
  }

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ContentWidth(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _step == 0
                ? _Welcome(key: const ValueKey(0), onStart: _next)
                : _SetupStep(
                    key: ValueKey(_step),
                    step: _step,
                    of: _setupSteps,
                    onBack: _back,
                    onNext: _next,
                    nextLabel: _step == _setupSteps ? l10n.done : l10n.onboardingContinue,
                    title: switch (_step) {
                      1 => l10n.onboardingLooksTitle,
                      2 => l10n.onboardingWardrobeTitle,
                      _ => l10n.onboardingReminderTitle,
                    },
                    body: switch (_step) {
                      1 => l10n.onboardingLooksBody,
                      2 => l10n.onboardingWardrobeBody,
                      _ => l10n.onboardingReminderBody,
                    },
                    // The look is picked by tapping one of the previews;
                    // elsewhere the preview shows what the controls under it
                    // do.
                    preview: switch (_step) {
                      1 => const _LooksPicker(),
                      2 => _WardrobePreview(name: _name),
                      _ => const _ReminderPreview(),
                    },
                    decorative: _step != 1,
                    child: switch (_step) {
                      1 => null,
                      2 => _WardrobeName(controller: _name, onDone: _next),
                      _ => const ReminderCard(),
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

/// A few drawn garments, the app's name, and "Get started".
class _Welcome extends StatelessWidget {
  final VoidCallback onStart;
  const _Welcome({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      // The same distance from the bottom as the setup steps' button.
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(alignment: Alignment.centerRight, child: _LanguageFlag()),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                // The collage keeps its proportions, scaled to the space
                // the text below leaves it (less with large text).
                final u = math.min(box.maxWidth / 340, box.maxHeight / 380).clamp(0.3, 1.4);
                return Center(
                  child: SizedBox(
                    width: 340 * u,
                    height: 360 * u,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 10 * u,
                          top: 10 * u,
                          child: GarmentArtCard(
                            art: GarmentArt.shirt,
                            color: const Color(0xFF7D8F64),
                            width: 150 * u,
                            height: 175 * u,
                            rotationDeg: -5,
                          ),
                        ),
                        Positioned(
                          right: 6 * u,
                          top: 36 * u,
                          child: GarmentArtCard(
                            art: GarmentArt.stripedTee,
                            color: const Color(0xFFE6DFD0),
                            width: 165 * u,
                            height: 180 * u,
                            rotationDeg: 4,
                          ),
                        ),
                        Positioned(
                          left: 86 * u,
                          top: 172 * u,
                          child: GarmentArtCard(
                            art: GarmentArt.trousers,
                            color: const Color(0xFF6E3B2E),
                            width: 150 * u,
                            height: 170 * u,
                            rotationDeg: -2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset('assets/icon/app_icon_small.png', width: 56, height: 56),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.onboardingTitle,
            style: AppText.sans(size: 32, weight: FontWeight.w300, color: AppColors.ink, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          Text(l10n.onboardingSubtitle, style: AppText.sans(size: 15, color: AppColors.label, height: 1.45)),
          const SizedBox(height: 28),
          _PrimaryButton(label: l10n.onboardingStart, onTap: onStart),
        ],
      ),
    );
  }
}

/// The app's language, picked right on the welcome: the flag of the one
/// in use, opening "System default / Čeština / English".
class _LanguageFlag extends StatelessWidget {
  const _LanguageFlag();

  static String _flag(String code) => code == 'cs' ? '🇨🇿' : '🇬🇧';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final picked = store.localeCode ?? 'system';
    // What "System default" comes to here: the phone's language, if the
    // app has it, otherwise English.
    final system = WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'cs' ? 'cs' : 'en';
    return TapArea(
      child: PopupMenuButton<String>(
        tooltip: '',
        useRootNavigator: true,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 8),
        constraints: const BoxConstraints(minWidth: 230, maxWidth: 300),
        menuPadding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
        color: AppColors.surface,
        elevation: 6,
        shadowColor: const Color(0x29000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: AppColors.rowBorder)),
        onSelected: (code) {
          if (code != picked) Haptics.tick();
          store.setLocale(code == 'system' ? null : code);
        },
        // Laid out like the wardrobe menu.
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            enabled: false,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              l10n.sectionLanguage.toUpperCase(),
              style: AppText.mono(size: 9.5, letterSpacing: 1.3, color: AppColors.mutedSoft),
            ),
          ),
          // Each language in its own name, so it reads whichever is active.
          for (final (code, flag, label) in [
            ('system', _flag(system), l10n.languageSystemShort),
            ('cs', _flag('cs'), 'Čeština'),
            ('en', _flag('en'), 'English'),
          ])
            PopupMenuItem<String>(
              value: code,
              height: 48,
              padding: EdgeInsets.zero,
              child: Container(
                height: 44,
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: code == picked ? AppColors.cardFill : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: AppText.sans(
                          size: 14.5,
                          weight: code == picked ? FontWeight.w500 : FontWeight.w400,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (code == picked) Icon(Icons.check, size: 17, color: AppColors.accentText),
                  ],
                ),
              ),
            ),
        ],
        child: Semantics(
          button: true,
          label: l10n.sectionLanguage,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
            decoration: BoxDecoration(
              color: AppColors.cardFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.rowBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_flag(Localizations.localeOf(context).languageCode), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One setup step: back and how far along at the top, a title and a line
/// of explanation, a live [preview] in the room left, the controls
/// ([child]) under it, and the button to go on.
class _SetupStep extends StatelessWidget {
  final int step;
  final int of;
  final String title;
  final String body;
  final Widget preview;

  /// Just a picture of what the controls do (screen readers skip it, and
  /// it gives way to large text) — or itself a control.
  final bool decorative;
  final Widget? child;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _SetupStep({
    super.key,
    required this.step,
    required this.of,
    required this.title,
    required this.body,
    required this.preview,
    this.decorative = true,
    this.child,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    // With large text a decorative preview gives its room to the words.
    final showPreview = !decorative || MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final child = this.child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 24, 0),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: SizedBox(width: 48, height: 48, child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink)),
              ),
              const SizedBox(width: 8),
              Expanded(child: _Progress(step: step, of: of)),
            ],
          ),
        ),
        Expanded(
          // The preview takes whatever room is left; with large text (or a
          // short screen) everything scrolls instead.
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              // A little further down from the progress bar, so the step
              // sits in the screen rather than hugging its top.
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - 64)),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.sans(size: 28, weight: FontWeight.w300, color: AppColors.ink, letterSpacing: -0.4)),
                      const SizedBox(height: 10),
                      Text(body, style: AppText.sans(size: 14, color: AppColors.mutedTag, height: 1.45)),
                      const SizedBox(height: 28),
                      if (showPreview)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: decorative ? ExcludeSemantics(child: preview) : preview),
                          ),
                        ),
                      if (child != null) child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          // Lifted off the bottom edge, for the same reason.
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: _PrimaryButton(label: nextLabel, onTap: onNext),
        ),
      ],
    );
  }
}

/// How far along the setup is: a dash per step, filled up to this one.
class _Progress extends StatelessWidget {
  final int step;
  final int of;
  const _Progress({required this.step, required this.of});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$step / $of',
      child: Row(
        children: [
          for (var i = 1; i <= of; i++) ...[
            if (i > 1) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step ? AppColors.accentText : AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WardrobeName extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onDone;
  const _WardrobeName({required this.controller, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.cardBorder),
    );
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onDone(),
      decoration: InputDecoration(
        // Used as the name if the field is left blank.
        hintText: l10n.defaultWardrobeName,
        hintStyle: AppText.sans(size: 16, color: AppColors.mutedTag),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border,
        enabledBorder: border,
      ),
      style: AppText.sans(size: 16, color: AppColors.ink),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(27)),
          alignment: Alignment.center,
          child: Text(label, style: AppText.sans(size: 15, weight: FontWeight.w500, color: Colors.white)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Previews: what each step's choices look like, kept up to date as they
// change. Decoration only — screen readers skip them.

const _shirtColor = Color(0xFF7D8F64);
const _creamColor = Color(0xFFE6DFD0);
const _trouserColor = Color(0xFF6E3B2E);
const _navyColor = Color(0xFF2E3B58);

/// The look: a big live preview of the app as it'll look — half light,
/// half dark when it follows the system — and System / Light / Dark under
/// it. (The whole app switches along, too.)
class _LooksPicker extends StatelessWidget {
  const _LooksPicker();

  static const _modes = [null, 'light', 'dark'];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final code = store.themeModeCode;
    final button = l10n.saveOutfitButton;
    // As big as fits nicely (less with large text, which needs the room).
    final room = math.min(MediaQuery.sizeOf(context).width, kMaxContentWidth) - 48;
    final width = math.min(MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 130.0 : 196.0, room * 0.6);
    final screen = switch (code) {
      'light' => _PhoneScreen(palette: AppPalette.light, button: button),
      'dark' => _PhoneScreen(palette: AppPalette.dark, button: button),
      _ => Stack(
        fit: StackFit.expand,
        children: [
          _PhoneScreen(palette: AppPalette.light, button: button),
          ClipPath(clipper: _LowerRightHalf(), child: _PhoneScreen(palette: AppPalette.dark, button: button)),
        ],
      ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _PhoneMock(key: ValueKey(code), width: width, screen: screen),
          ),
        ),
        const SizedBox(height: 28),
        Segmented(
          labels: [l10n.languageSystemShort, l10n.themeLight, l10n.themeDark],
          selected: _modes.indexOf(code),
          onSelect: (i) => store.setThemeMode(_modes[i]),
          height: 46,
          expand: true,
        ),
      ],
    );
  }
}

/// A phone [width] wide showing [screen].
class _PhoneMock extends StatelessWidget {
  final double width;
  final Widget screen;
  const _PhoneMock({super.key, required this.width, required this.screen});

  /// The size [_PhoneScreen] is drawn at, before scaling to [width].
  static const _designSize = Size(116, 206);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22 * width / _designSize.width);
    return Container(
      width: width,
      height: width * _designSize.height / _designSize.width,
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.cardBorder, width: 2),
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 30, offset: Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: FittedBox(
          child: SizedBox.fromSize(size: _designSize, child: screen),
        ),
      ),
    );
  }
}

/// The outfit screen in miniature, in [palette]'s colors.
class _PhoneScreen extends StatelessWidget {
  final AppPalette palette;
  final String button;
  const _PhoneScreen({required this.palette, required this.button});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      color: p.background,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 28, height: 4, decoration: BoxDecoration(color: p.muted, borderRadius: BorderRadius.circular(2))),
              const Spacer(),
              Container(width: 6, height: 6, decoration: BoxDecoration(color: p.muted, shape: BoxShape.circle)),
            ],
          ),
          const Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(left: 4, top: 10, child: GarmentArtCard(art: GarmentArt.shirt, color: _shirtColor, width: 48, height: 56, rotationDeg: -4)),
                Positioned(right: 4, top: 46, child: GarmentArtCard(art: GarmentArt.trousers, color: _trouserColor, width: 46, height: 54, rotationDeg: 3)),
                Positioned(left: 14, bottom: 4, child: GarmentArtCard(art: GarmentArt.sneaker, color: _creamColor, width: 44, height: 40, rotationDeg: -2)),
              ],
            ),
          ),
          Container(
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(10)),
            child: Text(
              button,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
              style: AppText.sans(size: 8.5, weight: FontWeight.w500, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// The half of a rectangle below its diagonal from top right to bottom
/// left — the dark half of "follow the system".
class _LowerRightHalf extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_LowerRightHalf old) => false;
}

/// A rail with a few things hanging on it, and a tag with the wardrobe's
/// name as it's typed (or the one it gets if left blank).
class _WardrobePreview extends StatelessWidget {
  final TextEditingController name;
  const _WardrobePreview({required this.name});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 280,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 14,
            left: 10,
            right: 10,
            child: Container(height: 6, decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(3))),
          ),
          for (final (x, art, color, deg) in const [
            (24.0, GarmentArt.shirt, _shirtColor, -3.0),
            (102.0, GarmentArt.dress, _navyColor, 2.0),
            (178.0, GarmentArt.stripedTee, _creamColor, -2.0),
          ]) ...[
            Positioned(left: x + 37, top: 8, child: Container(width: 4, height: 22, color: AppColors.muted)),
            Positioned(
              left: x,
              top: 28,
              child: GarmentArtCard(art: art, color: color, width: 78, height: 96, rotationDeg: deg),
            ),
          ],
          Positioned(
            bottom: 8,
            child: ValueListenableBuilder(
              valueListenable: name,
              builder: (context, value, _) {
                final text = value.text.trim();
                return Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.fromLTRB(12, 9, 16, 9),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The same hanger as by the wardrobe's name in the app.
                      Icon(Icons.checkroom_outlined, size: 17, color: AppColors.muted),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          text.isEmpty ? l10n.defaultWardrobeName : text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(size: 15, weight: FontWeight.w500, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The reminder as it would arrive: the app's icon, the time and the
/// words.
class _ReminderPreview extends StatelessWidget {
  const _ReminderPreview();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final time = TimeOfDay(hour: store.reminderMinutes ~/ 60, minute: store.reminderMinutes % 60).format(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.rowBorder),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset('assets/icon/app_icon_small.png', width: 38, height: 38),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Outfits', style: AppText.sans(size: 13, weight: FontWeight.w600, color: AppColors.ink))),
                    Text(time, style: AppText.sans(size: 12, color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(l10n.reminderTitle, style: AppText.sans(size: 13.5, weight: FontWeight.w500, color: AppColors.ink)),
                const SizedBox(height: 1),
                Text(l10n.reminderBody, style: AppText.sans(size: 13.5, color: AppColors.label, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

