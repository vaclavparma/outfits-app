import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'color_names.dart';
import 'l10n/app_localizations.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'wardrobe_store.dart';
import 'widgets.dart';

/// The outfit diary: a calendar of what was worn when (tap a day to log or
/// see its outfits), and stats drawn from it.
class DiaryTab extends StatefulWidget {
  const DiaryTab({super.key});

  @override
  State<DiaryTab> createState() => _DiaryTabState();
}

class _DiaryTabState extends State<DiaryTab> {
  bool _stats = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          // With large text the toggle goes below the title rather than
          // squeezing it.
          child: SizedBox(
            width: double.infinity,
            child: Flex(
              direction: stacked ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: stacked ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 8,
              children: [
                Text(
                  l10n.tabDiary,
                  style: AppText.sans(size: 26, weight: FontWeight.w300, color: AppColors.ink, letterSpacing: -0.4),
                ),
                _Segmented(
                  labels: [l10n.diaryCalendar, l10n.diaryStats],
                  selected: _stats ? 1 : 0,
                  onSelect: (i) => setState(() => _stats = i == 1),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: _stats ? const _Stats() : const _Calendar()),
              Positioned(
                right: 20,
                bottom: 16,
                child: Semantics(
                  button: true,
                  label: l10n.diaryLogOutfit,
                  child: GestureDetector(
                    onTap: () => openLogOutfitSheet(context),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: const Icon(Icons.add, size: 28, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Two-way pill toggle ("KALENDÁŘ | STATISTIKY").
class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  const _Segmented({required this.labels, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, label) in labels.indexed)
            Semantics(
              button: true,
              selected: i == selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.ink : null,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: AppText.mono(
                      size: 9.5,
                      letterSpacing: 1,
                      color: i == selected ? AppColors.background : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Weekday initials (Monday first) above a list of months, newest first.
class _Calendar extends StatelessWidget {
  const _Calendar();

  /// At least this many months are shown, even with an empty diary.
  static const _minMonths = 6;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final first = store.diary.isEmpty ? now : store.diary.first.day;
    final span = (now.year - first.year) * 12 + now.month - first.month + 1;
    final months = span < _minMonths ? _minMonths : span;
    // 2024-01-01 was a Monday.
    final weekdays = [for (var i = 0; i < 7; i++) DateFormat.E(locale).format(DateTime(2024, 1, 1 + i))];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Text(
                    w.replaceAll('.', '').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppText.mono(size: 9.5, letterSpacing: 1, color: AppColors.mutedSoft),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 1, color: AppColors.hairline),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 88),
            itemCount: months,
            itemBuilder: (context, i) => _Month(month: DateTime(now.year, now.month - i)),
          ),
        ),
      ],
    );
  }
}

class _Month extends StatelessWidget {
  final DateTime month;
  const _Month({required this.month});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final title = DateFormat.yMMMM(locale).format(month);
    final today = _dayOf(DateTime.now());
    final lead = month.weekday - 1; // Monday-first offset of the 1st
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final logged = store.daysLoggedIn(month);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    title[0].toUpperCase() + title.substring(1),
                    style: AppText.sans(size: 17, weight: FontWeight.w500, color: AppColors.ink),
                  ),
                ),
                if (logged > 0)
                  Text(
                    l10n.diaryDaysCount(logged),
                    style: AppText.mono(size: 9.5, letterSpacing: 0.6, color: AppColors.mutedSoft),
                  ),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            childAspectRatio: 0.82,
            children: [
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (var d = 1; d <= days; d++)
                _DayCell(
                  day: DateTime(month.year, month.month, d),
                  isToday: DateTime(month.year, month.month, d) == today,
                  isFuture: DateTime(month.year, month.month, d).isAfter(today),
                  colors: store.dayColors(DateTime(month.year, month.month, d)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isFuture;
  /// Up to three colors worn most that day — a dot each, in the family's
  /// swatch (photographed colors are too muted to read as tiny dots).
  final List<ColorFamily> colors;

  const _DayCell({required this.day, required this.isToday, required this.isFuture, required this.colors});

  @override
  Widget build(BuildContext context) {
    // Seven to a row: with large text a number shrinks to fit its cell
    // rather than being cut off.
    final label = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '${day.day}',
        style: AppText.sans(
          size: 17,
          weight: isToday ? FontWeight.w500 : FontWeight.w400,
          color: isFuture ? AppColors.mutedSoft : AppColors.ink,
        ),
      ),
    );
    return Semantics(
      button: !isFuture,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isFuture ? null : () => openDiaryDaySheet(context, day),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: isToday
                  ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.accentText, width: 2))
                  : null,
              child: label,
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 7,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final c in colors)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: c.swatch,
                        shape: BoxShape.circle,
                        // Keeps black (or white) visible on a background
                        // of the same color.
                        border: Border.all(color: AppColors.mutedSoft.withValues(alpha: 0.6), width: 0.8),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the diary adds up to: this month's numbers, how often each piece
/// has been worn, and what hasn't been worn for a while.
class _Stats extends StatefulWidget {
  const _Stats();

  @override
  State<_Stats> createState() => _StatsState();
}

class _StatsState extends State<_Stats> {
  static const _topCount = 5;

  /// Not worn for at least this many days counts as "long unworn".
  static const _unwornDays = 30;

  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    if (store.diary.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insights_outlined, size: 32, color: AppColors.mutedSoft),
              const SizedBox(height: 10),
              Text(
                l10n.statsEmpty,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 13, color: AppColors.mutedTag, height: 1.45),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final today = _dayOf(now);
    final stats = store.wearStats;
    final worn = [
      for (final it in store.items)
        if (stats[it.id] case final s?) (item: it, count: s.count),
    ]..sort((a, b) => b.count.compareTo(a.count));
    final maxCount = worn.isEmpty ? 1 : worn.first.count;
    final shownWorn = _showAll ? worn : worn.take(_topCount).toList();

    final cutoff = addDays(today, -_unwornDays);
    final unworn = [
      for (final it in store.items)
        if (stats[it.id]?.last case final last when last == null || !last.isAfter(cutoff))
          (item: it, last: last),
    ]..sort((a, b) {
        if (a.last == null || b.last == null) return a.last == null ? (b.last == null ? 0 : -1) : 1;
        return a.last!.compareTo(b.last!);
      });

    final wornThisMonth = store.itemsWornIn(now).where((id) => store.itemById(id) != null).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 92),
      children: [
        Row(
          children: [
            Expanded(child: _StatTile(value: '${store.daysLoggedIn(now)}', label: l10n.statsDaysLogged(store.daysLoggedIn(now)))),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(value: '$wornThisMonth', suffix: ' / ${store.items.length}', label: l10n.statsItemsWorn),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const _ColorStats(),
        _SectionTitle(title: l10n.statsTimesWorn, trailing: l10n.statsAllTime),
        for (final w in shownWorn)
          _ItemRow(
            item: w.item,
            browseIds: [for (final x in worn) x.item.id],
            trailing: Text(l10n.timesWorn(w.count), style: AppText.sans(size: 15, color: AppColors.ink)),
            bar: w.count / maxCount,
          ),
        if (worn.length > _topCount)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _showAll = !_showAll),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _showAll ? l10n.statsShowLess : l10n.statsShowAll(worn.length),
                style: AppText.mono(size: 10.5, letterSpacing: 0.4, color: AppColors.accentText),
              ),
            ),
          ),
        const SizedBox(height: 22),
        _SectionTitle(title: l10n.statsNotWorn, trailing: l10n.statsNotWornSince, inline: true),
        if (unworn.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              l10n.statsNothingUnworn(_unwornDays),
              style: AppText.sans(size: 12.5, color: AppColors.mutedTag, height: 1.4),
            ),
          ),
        for (final u in unworn)
          _ItemRow(
            item: u.item,
            browseIds: [for (final x in unworn) x.item.id],
            subtitle: [store.kindName(u.item.cat), ?store.typeName(u.item)].join(' · '),
            trailing: Text(
              u.last == null ? l10n.statsNever : l10n.statsDaysAgo(daysBetween(u.last!, today)),
              style: AppText.mono(size: 10, letterSpacing: 0.3, color: u.last == null ? AppColors.warn : AppColors.mutedTag),
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String? suffix;
  final String label;

  const _StatTile({required this.value, this.suffix, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.rowBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: value,
              style: AppText.sans(size: 34, weight: FontWeight.w300, color: AppColors.ink),
              children: [
                if (suffix != null)
                  TextSpan(text: suffix, style: AppText.sans(size: 17, weight: FontWeight.w300, color: AppColors.mutedTag)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.mono(size: 9.5, letterSpacing: 0.3, color: AppColors.mutedTag, height: 1.3)),
        ],
      ),
    );
  }
}

/// A stats section's heading, with a small note at the far right — or,
/// with [inline], right after the title.
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final bool inline;
  const _SectionTitle({required this.title, this.trailing, this.inline = false});

  @override
  Widget build(BuildContext context) {
    final note = trailing == null
        ? null
        : Text(trailing!, style: AppText.mono(size: 9.5, letterSpacing: 0.6, color: AppColors.mutedSoft));
    final heading = Text(title, style: AppText.sans(size: 17, weight: FontWeight.w500, color: AppColors.ink));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: inline
            ? [heading, if (note != null) ...[const SizedBox(width: 8), note]]
            : [Expanded(child: heading), ?note],
      ),
    );
  }
}

/// A piece of clothing in a stats list: thumbnail, name, then either a
/// subtitle or a bar ([bar] as a fraction of the longest), and a trailing
/// figure. Tap for its detail.
class _ItemRow extends StatelessWidget {
  final ClothingItem item;
  final List<String> browseIds;
  final String? subtitle;
  final Widget trailing;
  final double? bar;

  const _ItemRow({required this.item, required this.browseIds, this.subtitle, required this.trailing, this.bar});

  @override
  Widget build(BuildContext context) {
    final store = context.read<WardrobeStore>();
    final name = store.displayName(item);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openItemDetail(context, item, browseIds: browseIds),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.rowBorder))),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.cardFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.imagePath == null ? const DiagonalStripes() : GarmentImage(item.imagePath!),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 15, color: AppColors.ink),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppText.mono(size: 9.5, letterSpacing: 0.3, color: AppColors.mutedTag)),
                  ],
                  if (bar != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 4,
                        child: LinearProgressIndicator(
                          value: bar,
                          backgroundColor: AppColors.cardBorder,
                          valueColor: AlwaysStoppedAnimation(AppColors.accentText),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// The wardrobe's colors next to the colors worn this month: two share bars
/// in the same order, and a table of the percentages.
class _ColorStats extends StatelessWidget {
  const _ColorStats();

  static Map<ColorFamily, int> _percent(Map<ColorFamily, int> counts) {
    final total = counts.values.fold(0, (a, b) => a + b);
    return {for (final MapEntry(:key, :value) in counts.entries) key: total == 0 ? 0 : (value * 100 / total).round()};
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final ownedCounts = store.wardrobeColors;
    if (ownedCounts.isEmpty) return const SizedBox.shrink();
    final wornCounts = store.wornColorsIn(now);
    final owned = _percent(ownedCounts), worn = _percent(wornCounts);
    // Biggest share of the wardrobe first; colors only worn go last.
    final families = {...ownedCounts.keys, ...wornCounts.keys}.toList()
      ..sort((a, b) {
        final byOwned = (ownedCounts[b] ?? 0).compareTo(ownedCounts[a] ?? 0);
        return byOwned != 0 ? byOwned : (wornCounts[b] ?? 0).compareTo(wornCounts[a] ?? 0);
      });
    final month = DateFormat.LLLL(Localizations.localeOf(context).toString()).format(now);

    final mono = AppText.mono(size: 9.5, letterSpacing: 0.6, color: AppColors.mutedSoft);
    // Number columns grow with the text size — only so far, leaving the
    // color names room; the figures shrink to fit past that.
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4);
    final col1 = scaler.scale(70), col2 = scaler.scale(80);
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: l10n.statsColors, trailing: month),
          const SizedBox(height: 4),
          _ShareBar(label: l10n.statsInWardrobe, families: families, counts: ownedCounts),
          const SizedBox(height: 8),
          _ShareBar(label: l10n.statsWornLabel, families: families, counts: wornCounts),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Spacer(),
                SizedBox(width: col1, child: _FitRight(Text(l10n.statsColWardrobe.toUpperCase(), style: mono))),
                SizedBox(width: col2, child: _FitRight(Text(l10n.statsWornLabel.toUpperCase(), style: mono))),
              ],
            ),
          ),
          for (final f in families)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.rowBorder))),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: f.swatch,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.colorFamily(f.name), style: AppText.sans(size: 15, color: AppColors.ink))),
                  SizedBox(
                    width: col1,
                    child: _FitRight(Text('${owned[f] ?? 0} %', style: AppText.mono(size: 12, color: AppColors.mutedTag))),
                  ),
                  SizedBox(
                    width: col2,
                    child: _FitRight(
                      Text(
                        wornCounts.isEmpty ? '–' : '${worn[f] ?? 0} %',
                        style: AppText.mono(size: 12, color: wornCounts.isEmpty ? AppColors.mutedTag : AppColors.ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One stacked bar of color shares, segments in the order of [families].
class _ShareBar extends StatelessWidget {
  final String label;
  final List<ColorFamily> families;
  final Map<ColorFamily, int> counts;

  const _ShareBar({required this.label, required this.families, required this.counts});

  @override
  Widget build(BuildContext context) {
    final shown = [for (final f in families) if ((counts[f] ?? 0) > 0) f];
    return Row(
      children: [
        SizedBox(
          width: MediaQuery.textScalerOf(context).scale(76),
          child: Text(label, style: AppText.mono(size: 9.5, letterSpacing: 0.4, color: AppColors.mutedTag)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 16,
              child: shown.isEmpty
                  ? ColoredBox(color: AppColors.cardFill)
                  : Row(
                      children: [
                        for (final (i, f) in shown.indexed)
                          Expanded(
                            flex: counts[f]!,
                            child: Container(
                              margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                              color: f.swatch,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// [child] right-aligned on one line, shrunk if the column is too narrow
/// for it (large text).
class _FitRight extends StatelessWidget {
  final Widget child;
  const _FitRight(this.child);

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: child);
}
