import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'garment_art.dart';
import 'l10n/app_localizations.dart';
import 'settings_screen.dart';
import 'sheets.dart';
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
  static const _setupSteps = 4;

  int _step = 0;
  final _name = TextEditingController();

  /// The kinds to keep — all of them, unless unticked.
  late final Set<String> _kinds = {for (final k in context.read<WardrobeStore>().kinds) k.id};

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
    store.keepOnlyKinds(_kinds);
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
                      3 => l10n.onboardingKindsTitle,
                      _ => l10n.onboardingReminderTitle,
                    },
                    body: switch (_step) {
                      1 => l10n.onboardingLooksBody,
                      2 => l10n.onboardingWardrobeBody,
                      3 => l10n.onboardingKindsBody,
                      _ => l10n.onboardingReminderBody,
                    },
                    child: switch (_step) {
                      1 => const SettingsContent(uppercaseLabels: true),
                      2 => _WardrobeName(controller: _name, onDone: _next),
                      3 => _KindPicker(selected: _kinds, onChanged: () => setState(() {})),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

/// One setup step: back and "n / N" at the top, a title and a line of
/// explanation, the controls, and the button to go on.
class _SetupStep extends StatelessWidget {
  final int step;
  final int of;
  final String title;
  final String body;
  final Widget child;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _SetupStep({
    super.key,
    required this.step,
    required this.of,
    required this.title,
    required this.body,
    required this.child,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
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
              const Spacer(),
              Text('$step / $of', style: AppText.mono(size: 10.5, letterSpacing: 0.6, color: AppColors.mutedSoft)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.sans(size: 28, weight: FontWeight.w300, color: AppColors.ink, letterSpacing: -0.4)),
                const SizedBox(height: 10),
                Text(body, style: AppText.sans(size: 14, color: AppColors.mutedTag, height: 1.45)),
                const SizedBox(height: 28),
                child,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: _PrimaryButton(label: nextLabel, onTap: onNext),
        ),
      ],
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

/// The kinds of clothing to keep, as chips, plus one to add a kind. A kind
/// that already has clothes in it stays.
class _KindPicker extends StatelessWidget {
  final Set<String> selected;
  final VoidCallback onChanged;
  const _KindPicker({required this.selected, required this.onChanged});

  Future<void> _add(BuildContext context, WardrobeStore store) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptTextDialog(
      context,
      title: l10n.newKind,
      initialValue: '',
      hintText: l10n.newKindHint,
      confirmLabel: l10n.create,
      isTaken: store.kindNameTaken,
    );
    if (name == null) return;
    final kind = store.addKind(name);
    if (kind != null) {
      Haptics.done();
      selected.add(kind.id);
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in store.kinds)
          SelectChip(
            label: k.name,
            active: selected.contains(k.id),
            mono: false,
            height: 40,
            onTap: () {
              if (selected.contains(k.id)) {
                // A kind with clothes stays, and so does the last one: with
                // none, there'd be nothing to add clothes to.
                if (store.kindItemCount(k.id) > 0 || selected.length == 1) return;
                selected.remove(k.id);
              } else {
                selected.add(k.id);
              }
              onChanged();
            },
          ),
        SelectChip(label: '+ ${l10n.newKind}', active: false, mono: false, height: 40, choice: false, onTap: () => _add(context, store)),
      ],
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
