// Màn hình chính chứa Bottom Navigation Bar

import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../main.dart';

import '../../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../../features/journal/presentation/screens/journal_screen.dart';
import '../../../features/journal/presentation/screens/add_trade_screen.dart'; // Import

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Key _journalScreenKey = UniqueKey();

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      JournalScreen(key: _journalScreenKey),
      const DashboardScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToAddTradeScreen() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AddTradeScreen()))
        .then((result) {
          if (result == true && mounted) {
            setState(() {
              _journalScreenKey = UniqueKey();
              _widgetOptions[0] = JournalScreen(key: _journalScreenKey);
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = [l10n.journal, l10n.dashboard];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          PopupMenuButton<Locale>(
            onSelected: (Locale locale) =>
                NKTradingApp.setLocale(context, locale),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              const PopupMenuItem<Locale>(
                value: Locale('en'),
                child: Text('English'),
              ),
              const PopupMenuItem<Locale>(
                value: Locale('vi'),
                child: Text('Tiếng Việt'),
              ),
            ],
            icon: const Icon(Icons.language),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Chỉ cần gọi signOut, StreamBuilder sẽ tự động điều hướng.
              await supabase.auth.signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddTradeScreen,
              icon: const Icon(Icons.add),
              label: Text(l10n.addTrade),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined),
            activeIcon: const Icon(Icons.book),
            label: l10n.journal,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
