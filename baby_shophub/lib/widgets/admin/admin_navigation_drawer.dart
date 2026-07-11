import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for HapticFeedback

class AdminNavigationDrawer extends StatefulWidget {
  const AdminNavigationDrawer({super.key});

  @override
  State<AdminNavigationDrawer> createState() => _AdminNavigationDrawerState();
}

class _AdminNavigationDrawerState extends State<AdminNavigationDrawer>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<String?> _expandedItem = ValueNotifier(null);

  // === EDIT HERE ONLY === routes & labels
  final _sections = [
    _Section(title: 'Overview', tiles: [
      _Tile(icon: Icons.dashboard, title: 'Dashboard', route: '/admin-dashboard'),
      _Tile(icon: Icons.analytics, title: 'Analytics', route: '/analytics'),
      _Tile(icon: Icons.insights, title: 'Advanced Analytics', route: '/advanced-analytics'),
    ]),
    _Section(title: 'Management', tiles: [
      _Tile(icon: Icons.people, title: 'User Management', route: '/admin-users'),
      _Tile(icon: Icons.inventory_2, title: 'Product Management', route: '/enhanced-product-management'),
      _Tile(icon: Icons.shopping_bag, title: 'Order Management', route: '/admin-orders'),
    ]),
    _Section(title: 'Tools', tiles: [
      _Tile(icon: Icons.import_export, title: 'Data Export / Import', route: '/data-export-import'),
      _Tile(icon: Icons.description, title: 'Reports', route: '/reports'),
      _Tile(icon: Icons.settings, title: 'Settings', route: '/admin-settings'),
    ]),
  ];

  /* ---------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: 280,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: dark
              ? const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF121212)])
              : const LinearGradient(colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)]),
        ),
        child: Column(
          children: [
            /*  Glass-morphic header  */
            _Header(dark: dark),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _sections.map((s) => _buildSection(s)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ---------------------------------------------------- */
  Widget _buildSection(_Section section) {
    return ValueListenableBuilder<String?>(
      valueListenable: _expandedItem,
      builder: (_, expanded, __) {
        final isOpen = expanded == section.title;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOpen
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            key: ValueKey(section.title),
            initiallyExpanded: isOpen,
            onExpansionChanged: (open) {
              HapticFeedback.selectionClick();
              _expandedItem.value = open ? section.title : null;
            },
            maintainState: true,
            shape: const RoundedRectangleBorder(),
            title: Text(section.title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(.75))),
            children: section.tiles.map(_buildTile).toList(),
          ),
        );
      },
    );
  }

  /* ---------------------------------------------------- */
  Widget _buildTile(_Tile tile) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final selected = currentRoute == tile.route;

    return ListTile(
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(.35),
      leading: Icon(tile.icon,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(.65)),
      title: Text(tile.title,
          style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        if (!selected) Navigator.pushNamed(context, tile.route);
      },
    );
  }
}

/* ============================================================
   3.  HEADER WIDGET (glass-morphic)
   ============================================================ */
class _Header extends StatelessWidget {
  final bool dark;
  const _Header({required this.dark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          /*  background blur  */
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(.55),
                      Theme.of(context).colorScheme.tertiary.withOpacity(.45),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          /*  content  */
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(.9),
                    child: const Icon(Icons.admin_panel_settings, size: 40)),
                const SizedBox(height: 12),
                Text('Admin Menu',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   4.  DATA CLASSES
   ============================================================ */
class _Section {
  final String title;
  final List<_Tile> tiles;
  const _Section({required this.title, required this.tiles});
}

class _Tile {
  final IconData icon;
  final String title;
  final String route;
  const _Tile({required this.icon, required this.title, required this.route});
}