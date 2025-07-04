// Màn hình chính chứa Bottom Navigation Bar

import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../main.dart';

import '../../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../../features/journal/presentation/screens/journal_screen.dart';
import '../../../features/journal/presentation/screens/add_trade_screen.dart'; // Import
import '../../../features/journal/presentation/widgets/filter_dialog.dart'; // Import
import '../../../features/journal/data/models/trade_filter_model.dart'; // Import

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // *** NEW: State để lưu các bộ lọc đang được áp dụng ***
  TradeFilterModel _currentFilter = const TradeFilterModel();

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _updateWidgetOptions();
  }

  // *** NEW: Hàm để cập nhật danh sách widget với bộ lọc mới ***
  void _updateWidgetOptions() {
    _widgetOptions = <Widget>[
      JournalScreen(key: ValueKey(_currentFilter), filter: _currentFilter),
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
            // Khi thêm mới thành công, reset bộ lọc và làm mới
            setState(() {
              _currentFilter = const TradeFilterModel();
              _updateWidgetOptions();
            });
          }
        });
  }

  // *** NEW: Hàm hiển thị hộp thoại lọc ***
  void _showFilterDialog() async {
    final result = await showDialog<TradeFilterModel>(
      context: context,
      builder: (context) => FilterDialog(initialFilter: _currentFilter),
    );

    if (result != null && mounted) {
      setState(() {
        _currentFilter = result;
        _updateWidgetOptions();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = [l10n.journal, l10n.dashboard];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          // *** NEW: Chỉ hiển thị nút Lọc ở màn hình Nhật ký ***
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
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
            onPressed: () async => await supabase.auth.signOut(),
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
