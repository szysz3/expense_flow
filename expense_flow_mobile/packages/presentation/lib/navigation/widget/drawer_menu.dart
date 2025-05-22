import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';
import 'package:presentation/screen/chat/chat_screen.dart';
import 'package:presentation/screen/settings/settings_screen.dart';
import 'package:presentation/screen/unprocessed_receipts/unprocessed_receipts_screen.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          _buildDrawerHeader(context),
          _buildDrawerItems(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.2),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'packages/presentation/assets/icon_summary.svg',
            width: 48,
            height: 48,
          ),
          const SizedBox(width: 16),
          Text(
            AppLocalizations.of(context).appTitle,
            style: const TextStyle(
              fontSize: 20,
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
        _buildDrawerItem(
          context: context,
          icon: SvgPicture.asset(
            'packages/presentation/assets/icon_chat.svg',
            width: 24,
            height: 24,
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
      onTap: onTap,
    );
  }
}
