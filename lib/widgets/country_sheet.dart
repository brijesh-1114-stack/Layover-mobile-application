import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import 'flow_scaffold.dart';

/// The country picker from the Figma sheet.
///
/// The list itself comes from `country_picker`'s data, but the chrome is ours:
/// the packaged `showCountryPicker` ships its own Material sheet, which is a
/// different shape, a different type ramp and a different search field from
/// every other sheet in this app.
Future<Country?> showCountrySheet({
  required BuildContext context,
  required Country selected,
}) {
  final s = FlowScaffold.scaleOf(context);
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24 * s)),
    ),
    builder: (context) => _CountrySheet(selected: selected),
  );
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.selected});

  final Country selected;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  /// Loaded once. `getAll` parses the whole country table, and re-running it on
  /// every keystroke makes the search feel heavy on a mid-range phone.
  final List<Country> _all = CountryService().getAll();
  final _query = TextEditingController();

  List<Country> get _results {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.countryCode.toLowerCase().contains(q) ||
              '+${c.phoneCode}'.contains(q),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    final media = MediaQuery.of(context);
    final results = _results;

    return Padding(
      // The sheet rides above the keyboard rather than hiding behind it - the
      // search field is the whole point of the screen.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.78,
        child: Column(
          children: [
            SizedBox(height: 10 * s),
            Container(
              width: 40 * s,
              height: 4 * s,
              decoration: BoxDecoration(
                color: AppColors.stepInactive.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            SizedBox(height: 14 * s),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * s),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select country',
                  style: interTight(
                    size: 20 * s,
                    weight: 600,
                    height: 1.25,
                    letterSpacing: -0.4 * s,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16 * s),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * s),
              child: Container(
                height: 58 * s,
                padding: EdgeInsets.symmetric(horizontal: 16 * s),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14 * s),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    SvgPicture.string(
                      FlowIcons.search,
                      width: 18 * s,
                      height: 18 * s,
                    ),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: TextField(
                        controller: _query,
                        autofocus: false,
                        cursorColor: AppColors.accent,
                        style: interTight(
                          size: 17 * s,
                          weight: 600,
                          height: 1.3,
                          letterSpacing: -0.2 * s,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Search country',
                          hintStyle: interTight(
                            size: 17 * s,
                            weight: 600,
                            height: 1.3,
                            letterSpacing: -0.2 * s,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6 * s),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'No country matches that.',
                        style: interTight(
                          size: 14 * s,
                          weight: 400,
                          height: 1.4,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        12 * s,
                        6 * s,
                        12 * s,
                        media.padding.bottom + 12 * s,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final country = results[i];
                        return _CountryRow(
                          country: country,
                          selected:
                              country.countryCode ==
                              widget.selected.countryCode,
                          onTap: () => Navigator.of(context).pop(country),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final Country country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14 * s),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.inPlace,
          height: 52 * s,
          padding: EdgeInsets.symmetric(horizontal: 12 * s),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSelectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(14 * s),
          ),
          child: Row(
            children: [
              Text(country.flagEmoji, style: TextStyle(fontSize: 20 * s)),
              SizedBox(width: 12 * s),
              Expanded(
                child: Text(
                  country.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: interTight(
                    size: 16 * s,
                    weight: selected ? 600 : 400,
                    height: 1.3,
                    letterSpacing: -0.2 * s,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 10 * s),
              Text(
                '+${country.phoneCode}',
                style: interTight(
                  size: 16 * s,
                  weight: 500,
                  height: 1.3,
                  letterSpacing: -0.2 * s,
                  color: AppColors.textSecondary,
                ),
              ),
              if (selected) ...[
                SizedBox(width: 10 * s),
                SvgPicture.string(
                  '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" '
                  'xmlns="http://www.w3.org/2000/svg">'
                  '<path d="M5 12.5l4.5 4.5L19 7.5" stroke="#0B79F0" '
                  'stroke-width="2.6" stroke-linecap="round" '
                  'stroke-linejoin="round"/></svg>',
                  width: 18 * s,
                  height: 18 * s,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
