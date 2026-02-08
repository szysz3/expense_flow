import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';
import 'package:presentation/core/widget/glass_container.dart';
import 'package:presentation/screen/chat/chat_screen.dart';
import 'package:presentation/screen/settings/settings_screen.dart';
import 'package:presentation/screen/unprocessed_receipts/unprocessed_receipts_screen.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(28),
            blur: 22,
            tintOpacity: 0.62,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildDrawerHeader(context),
                _buildDrawerItems(context),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    theme.platform.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.25),
            colorScheme.tertiary.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'packages/presentation/assets/icon_summary.svg',
            width: 40,
            height: 40,
            colorFilter: ColorFilter.mode(
              colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            AppLocalizations.of(context).appTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItems(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildDrawerItem(
          context: context,
          icon: SvgPicture.asset(
            'packages/presentation/assets/icon_chat.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
          title: 'Chat',
          onTap: () {
            Navigator.pop(context);
            ChatScreen.show(context);
          },
        ),
        _buildDrawerItem(
          context: context,
          icon: SvgPicture.asset(
            'packages/presentation/assets/icon_unprocessed.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
          title: AppLocalizations.of(context).unprocessed,
          onTap: () {
            Navigator.pop(context);
            UnprocessedReceiptsScreen.show(context);
          },
        ),
        _buildDrawerItem(
          context: context,
          icon: SvgPicture.asset(
            'packages/presentation/assets/icon_settings.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
          title: AppLocalizations.of(context).settings,
          onTap: () {
            Navigator.pop(context);
            SettingsScreen.show(context);
          },
        ),
      ],
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: icon,
      title: Text(title),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      hoverColor: Theme.of(context)
          .colorScheme
          .primary
          .withValues(alpha: 0.12),
      onTap: onTap,
    );
  }
}
