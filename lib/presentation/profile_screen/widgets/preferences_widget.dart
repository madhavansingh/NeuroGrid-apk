import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PreferencesWidget extends StatefulWidget {
  const PreferencesWidget({super.key});

  @override
  State<PreferencesWidget> createState() => _PreferencesWidgetState();
}

class _PreferencesWidgetState extends State<PreferencesWidget> {
  String _selectedTheme = 'Light';
  String _selectedLanguage = 'English';
  String _selectedUnit = 'Metric';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _PreferenceRow(
            icon: Icons.palette_outlined,
            label: 'App Theme',
            options: const ['Light', 'Dark', 'System'],
            selected: _selectedTheme,
            onChanged: (v) => setState(() => _selectedTheme = v),
          ),
          Divider(color: AppTheme.outlineVariant, height: 20, thickness: 1),
          _PreferenceRow(
            icon: Icons.language_rounded,
            label: 'Language',
            options: const ['English', 'Hindi', 'Marathi'],
            selected: _selectedLanguage,
            onChanged: (v) => setState(() => _selectedLanguage = v),
          ),
          Divider(color: AppTheme.outlineVariant, height: 20, thickness: 1),
          _PreferenceRow(
            icon: Icons.straighten_rounded,
            label: 'Distance Unit',
            options: const ['Metric', 'Imperial'],
            selected: _selectedUnit,
            onChanged: (v) => setState(() => _selectedUnit = v),
          ),
          Divider(color: AppTheme.outlineVariant, height: 20, thickness: 1),
          _ActionRow(
            icon: Icons.share_location_rounded,
            label: 'Location Sharing',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'On',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.success,
                ),
              ),
            ),
          ),
          Divider(color: AppTheme.outlineVariant, height: 20, thickness: 1),
          _ActionRow(
            icon: Icons.data_usage_rounded,
            label: 'Data Saver',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Off',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _PreferenceRow({
    required this.icon,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: AppTheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => _OptionsSheet(
                label: label,
                options: options,
                selected: selected,
                onChanged: onChanged,
              ),
            );
          },
          child: Row(
            children: [
              Text(
                selected,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        trailing,
      ],
    );
  }
}

class _OptionsSheet extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _OptionsSheet({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map(
            (opt) => GestureDetector(
              onTap: () {
                onChanged(opt);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: opt == selected
                      ? AppTheme.primaryLight
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: opt == selected
                        ? AppTheme.primary.withAlpha(60)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      opt,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: opt == selected
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (opt == selected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
