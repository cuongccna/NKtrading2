// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get registerNow => 'Register now';

  @override
  String get tradingJournal => 'Trading Journal';

  @override
  String get logout => 'Logout';

  @override
  String get addTrade => 'Add Trade';

  @override
  String get symbol => 'Symbol (e.g., BTC/USDT)';

  @override
  String get direction => 'Direction';

  @override
  String get long => 'Long';

  @override
  String get short => 'Short';

  @override
  String get entryPrice => 'Entry Price';

  @override
  String get exitPrice => 'Exit Price (Optional)';

  @override
  String get quantity => 'Quantity';

  @override
  String get strategy => 'Strategy (e.g., Breakout)';

  @override
  String get notes => 'Notes / Reflections';

  @override
  String get psychology => 'Psychology';

  @override
  String get mindsetRating => 'Mindset (1-5)';

  @override
  String get emotionTags => 'Emotion Tags (e.g., FOMO, Patient)';

  @override
  String get saveTrade => 'Save Trade';

  @override
  String get viewImage => 'View Full Image';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get journal => 'Journal';

  @override
  String get details => 'Details';

  @override
  String get symbolLabel => 'Symbol';

  @override
  String get directionLabel => 'Direction';

  @override
  String get entryPriceLabel => 'Entry Price';

  @override
  String get exitPriceLabel => 'Exit Price';

  @override
  String get notClosed => 'Not Closed';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get strategyLabel => 'Strategy';

  @override
  String get notesLabel => 'Notes';

  @override
  String get psychologyLabel => 'Psychology';

  @override
  String get mindsetRatingLabel => 'Mindset (1-5)';

  @override
  String get emotionTagsLabel => 'Emotion Tags';

  @override
  String get noValue => 'None';

  @override
  String get chart => 'Chart';

  @override
  String get chartScreenshot => 'Chart Screenshot';

  @override
  String get filterTrades => 'Filter Trades';

  @override
  String get dateRange => 'Date Range';

  @override
  String get selectDate => 'Select Date';

  @override
  String get all => 'All';

  @override
  String get apply => 'Apply';

  @override
  String get reset => 'Reset';

  @override
  String get connections => 'Connections';

  @override
  String get manageApiKeys => 'Manage API Keys';

  @override
  String get addConnection => 'Add Connection';

  @override
  String get noConnections => 'You have not added any API connections yet.';

  @override
  String get addApiKey => 'Add API Key';

  @override
  String get exchange => 'Exchange';

  @override
  String get label => 'Label (e.g., Main Account)';

  @override
  String get apiKey => 'API Key';

  @override
  String get apiSecret => 'API Secret';

  @override
  String get importantNotice => 'Important Notice';

  @override
  String get readOnlyWarning =>
      'For your security, please ensure the API key is set to \'Read-only\' and does not have trading or withdrawal permissions.';

  @override
  String get iUnderstand => 'I have read and understand';

  @override
  String get save => 'Save';

  @override
  String get sync => 'Sync';

  @override
  String get syncing => 'Syncing...';

  @override
  String get apiKeys => 'API Keys';

  @override
  String get wallets => 'Wallets';

  @override
  String get addWallet => 'Add Wallet';

  @override
  String get walletAddress => 'Wallet Address';

  @override
  String get blockchain => 'Blockchain';

  @override
  String get noWallets => 'You have not added any wallets yet.';

  @override
  String get syncWallet => 'Sync Wallet';

  @override
  String get searchBySymbol => 'Search by symbol...';

  @override
  String get top10WinningTrades => 'Top 10 Winning Trades';

  @override
  String get top10LosingTrades => 'Top 10 Losing Trades';

  @override
  String get aiInsights => 'AI Insights';

  @override
  String get bestPerformingStrategy => 'Best Performing Strategy';

  @override
  String get bestPerformingDay => 'Best Performing Day';

  @override
  String get bestPerformingSession => 'Best Trading Session';

  @override
  String get pnl => 'PnL';

  @override
  String get winrate => 'Winrate';

  @override
  String get tradeCount => 'Trade Count';

  @override
  String get psychologicalAnalysis => 'Psychological Analysis';

  @override
  String get performanceByMindset => 'Performance by Mindset';

  @override
  String get performanceByEmotion => 'Performance by Emotion';

  @override
  String get rating => 'Rating';

  @override
  String get tag => 'Tag';

  @override
  String get averagePnl => 'Average PnL';

  @override
  String get editTrade => 'Edit Trade';

  @override
  String get deleteTrade => 'Delete Trade';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String get deleteConfirmation =>
      'Are you sure you want to permanently delete this trade?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get settings => 'Settings';

  @override
  String get general => 'General';

  @override
  String get currency => 'Currency';

  @override
  String get usDollar => 'US Dollar';

  @override
  String get vietnameseDong => 'Vietnamese Dong';

  @override
  String get marketContext => 'Market Context';

  @override
  String get smartMoneyChecklist => 'Smart Money Checklist';

  @override
  String get socialVolume => 'Social Volume';

  @override
  String get sentiment => 'Sentiment';

  @override
  String get exchangeFlow => 'Exchange Flow';

  @override
  String get whaleActivity => 'Whale Activity';

  @override
  String atTimeOfTrade(Object asset, Object value) {
    return 'At the time of the trade, the social volume for $asset was $value.';
  }

  @override
  String get noMarketData => 'No market data available for this time.';

  @override
  String get positive => 'Positive';

  @override
  String get negative => 'Negative';

  @override
  String get neutral => 'Neutral';

  @override
  String get inflow => 'Inflow';

  @override
  String get outflow => 'Outflow';

  @override
  String get topHolders => 'Top Holders Supply';

  @override
  String get activeAddresses => 'Active Addresses (24h)';
}
