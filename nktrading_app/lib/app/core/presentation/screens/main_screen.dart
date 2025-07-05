// Màn hình chính chứa Bottom Navigation Bar

import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../main.dart';

import '../../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../../features/journal/presentation/screens/journal_screen.dart';
import '../../../features/journal/presentation/screens/add_trade_screen.dart'; // Import
import '../../../features/journal/presentation/widgets/filter_dialog.dart';
import '../../../features/journal/data/models/trade_filter_model.dart';
import '../../../features/connections/presentation/screens/api_connections_screen.dart'; // Import

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // State để lưu các bộ lọc đang được áp dụng
  TradeFilterModel _currentFilter = const TradeFilterModel();

  // Key để có thể "ra lệnh" cho JournalScreen rebuild lại từ đầu
  // Đây là cách làm mạnh mẽ và đáng tin cậy nhất để làm mới.
  Key _journalScreenKey = UniqueKey();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Hàm điều hướng đến màn hình Thêm Giao Dịch
  void _navigateToAddTradeScreen() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AddTradeScreen()))
        .then((result) {
          // Sau khi thêm mới thành công, làm mới lại danh sách
          if (result == true && mounted) {
            setState(() {
              // Reset bộ lọc về mặc định
              _currentFilter = const TradeFilterModel();
              // Tạo một key mới để buộc Flutter rebuild lại JournalScreen
              _journalScreenKey = UniqueKey();
            });
          }
        });
  }

  // Hàm hiển thị hộp thoại lọc
  void _showFilterDialog() async {
    final result = await showDialog<TradeFilterModel>(
      context: context,
      builder: (context) => FilterDialog(initialFilter: _currentFilter),
    );

    // Nếu người dùng áp dụng bộ lọc mới, cập nhật lại state
    if (result != null && mounted) {
      setState(() {
        _currentFilter = result;
        // Đồng thời cũng tạo key mới để rebuild với bộ lọc mới
        _journalScreenKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = [l10n.journal, l10n.dashboard];

    // Tạo danh sách widget trong build method để đảm bảo nó luôn được cập nhật
    final List<Widget> widgetOptions = <Widget>[
      // Truyền key và filter vào JournalScreen
      // Khi key thay đổi, một instance mới của JournalScreen sẽ được tạo
      JournalScreen(key: _journalScreenKey, filter: _currentFilter),
      const DashboardScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          // Chỉ hiển thị nút Lọc ở màn hình Nhật ký
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
          // *** NEW: Thêm nút Cài đặt/Kết nối ***
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ApiConnectionsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await supabase.auth.signOut(),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: widgetOptions),
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
