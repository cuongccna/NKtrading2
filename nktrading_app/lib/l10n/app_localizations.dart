import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get registerNow;

  /// No description provided for @tradingJournal.
  ///
  /// In en, this message translates to:
  /// **'Trading Journal'**
  String get tradingJournal;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @addTrade.
  ///
  /// In en, this message translates to:
  /// **'Add Trade'**
  String get addTrade;

  /// No description provided for @symbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol (e.g., BTC/USDT)'**
  String get symbol;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get direction;

  /// No description provided for @long.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get long;

  /// No description provided for @short.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get short;

  /// No description provided for @entryPrice.
  ///
  /// In en, this message translates to:
  /// **'Entry Price'**
  String get entryPrice;

  /// No description provided for @exitPrice.
  ///
  /// In en, this message translates to:
  /// **'Exit Price (Optional)'**
  String get exitPrice;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @strategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy (e.g., Breakout)'**
  String get strategy;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes / Reflections'**
  String get notes;

  /// No description provided for @psychology.
  ///
  /// In en, this message translates to:
  /// **'Psychology'**
  String get psychology;

  /// No description provided for @mindsetRating.
  ///
  /// In en, this message translates to:
  /// **'Mindset (1-5)'**
  String get mindsetRating;

  /// No description provided for @emotionTags.
  ///
  /// In en, this message translates to:
  /// **'Emotion Tags (e.g., FOMO, Patient)'**
  String get emotionTags;

  /// No description provided for @saveTrade.
  ///
  /// In en, this message translates to:
  /// **'Save Trade'**
  String get saveTrade;

  /// No description provided for @viewImage.
  ///
  /// In en, this message translates to:
  /// **'View Full Image'**
  String get viewImage;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @symbolLabel.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get symbolLabel;

  /// No description provided for @directionLabel.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get directionLabel;

  /// No description provided for @entryPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry Price'**
  String get entryPriceLabel;

  /// No description provided for @exitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Exit Price'**
  String get exitPriceLabel;

  /// No description provided for @notClosed.
  ///
  /// In en, this message translates to:
  /// **'Not Closed'**
  String get notClosed;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @strategyLabel.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get strategyLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @psychologyLabel.
  ///
  /// In en, this message translates to:
  /// **'Psychology'**
  String get psychologyLabel;

  /// No description provided for @mindsetRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Mindset (1-5)'**
  String get mindsetRatingLabel;

  /// No description provided for @emotionTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Emotion Tags'**
  String get emotionTagsLabel;

  /// No description provided for @noValue.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noValue;

  /// No description provided for @chart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get chart;

  /// No description provided for @chartScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Chart Screenshot'**
  String get chartScreenshot;

  /// No description provided for @filterTrades.
  ///
  /// In en, this message translates to:
  /// **'Filter Trades'**
  String get filterTrades;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @manageApiKeys.
  ///
  /// In en, this message translates to:
  /// **'Manage API Keys'**
  String get manageApiKeys;

  /// No description provided for @addConnection.
  ///
  /// In en, this message translates to:
  /// **'Add Connection'**
  String get addConnection;

  /// No description provided for @noConnections.
  ///
  /// In en, this message translates to:
  /// **'You have not added any API connections yet.'**
  String get noConnections;

  /// No description provided for @addApiKey.
  ///
  /// In en, this message translates to:
  /// **'Add API Key'**
  String get addApiKey;

  /// No description provided for @exchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get exchange;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label (e.g., Main Account)'**
  String get label;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @apiSecret.
  ///
  /// In en, this message translates to:
  /// **'API Secret'**
  String get apiSecret;

  /// No description provided for @importantNotice.
  ///
  /// In en, this message translates to:
  /// **'Important Notice'**
  String get importantNotice;

  /// No description provided for @readOnlyWarning.
  ///
  /// In en, this message translates to:
  /// **'For your security, please ensure the API key is set to \'Read-only\' and does not have trading or withdrawal permissions.'**
  String get readOnlyWarning;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I have read and understand'**
  String get iUnderstand;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @apiKeys.
  ///
  /// In en, this message translates to:
  /// **'API Keys'**
  String get apiKeys;

  /// No description provided for @wallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get wallets;

  /// No description provided for @addWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Wallet'**
  String get addWallet;

  /// No description provided for @walletAddress.
  ///
  /// In en, this message translates to:
  /// **'Wallet Address'**
  String get walletAddress;

  /// No description provided for @blockchain.
  ///
  /// In en, this message translates to:
  /// **'Blockchain'**
  String get blockchain;

  /// No description provided for @noWallets.
  ///
  /// In en, this message translates to:
  /// **'You have not added any wallets yet.'**
  String get noWallets;

  /// No description provided for @syncWallet.
  ///
  /// In en, this message translates to:
  /// **'Sync Wallet'**
  String get syncWallet;

  /// No description provided for @searchBySymbol.
  ///
  /// In en, this message translates to:
  /// **'Search by symbol...'**
  String get searchBySymbol;

  /// No description provided for @top10WinningTrades.
  ///
  /// In en, this message translates to:
  /// **'Top 10 Winning Trades'**
  String get top10WinningTrades;

  /// No description provided for @top10LosingTrades.
  ///
  /// In en, this message translates to:
  /// **'Top 10 Losing Trades'**
  String get top10LosingTrades;

  /// No description provided for @aiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get aiInsights;

  /// No description provided for @bestPerformingStrategy.
  ///
  /// In en, this message translates to:
  /// **'Best Performing Strategy'**
  String get bestPerformingStrategy;

  /// No description provided for @bestPerformingDay.
  ///
  /// In en, this message translates to:
  /// **'Best Performing Day'**
  String get bestPerformingDay;

  /// No description provided for @bestPerformingSession.
  ///
  /// In en, this message translates to:
  /// **'Best Trading Session'**
  String get bestPerformingSession;

  /// No description provided for @pnl.
  ///
  /// In en, this message translates to:
  /// **'PnL'**
  String get pnl;

  /// No description provided for @winrate.
  ///
  /// In en, this message translates to:
  /// **'Winrate'**
  String get winrate;

  /// No description provided for @tradeCount.
  ///
  /// In en, this message translates to:
  /// **'Trade Count'**
  String get tradeCount;

  /// No description provided for @psychologicalAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Psychological Analysis'**
  String get psychologicalAnalysis;

  /// No description provided for @performanceByMindset.
  ///
  /// In en, this message translates to:
  /// **'Performance by Mindset'**
  String get performanceByMindset;

  /// No description provided for @performanceByEmotion.
  ///
  /// In en, this message translates to:
  /// **'Performance by Emotion'**
  String get performanceByEmotion;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @tag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get tag;

  /// No description provided for @averagePnl.
  ///
  /// In en, this message translates to:
  /// **'Average PnL'**
  String get averagePnl;

  /// No description provided for @editTrade.
  ///
  /// In en, this message translates to:
  /// **'Edit Trade'**
  String get editTrade;

  /// No description provided for @deleteTrade.
  ///
  /// In en, this message translates to:
  /// **'Delete Trade'**
  String get deleteTrade;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this trade?'**
  String get deleteConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @usDollar.
  ///
  /// In en, this message translates to:
  /// **'US Dollar'**
  String get usDollar;

  /// No description provided for @vietnameseDong.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese Dong'**
  String get vietnameseDong;

  /// No description provided for @marketContext.
  ///
  /// In en, this message translates to:
  /// **'Market Context'**
  String get marketContext;

  /// No description provided for @smartMoneyChecklist.
  ///
  /// In en, this message translates to:
  /// **'Smart Money Checklist'**
  String get smartMoneyChecklist;

  /// No description provided for @socialVolume.
  ///
  /// In en, this message translates to:
  /// **'Social Volume'**
  String get socialVolume;

  /// No description provided for @sentiment.
  ///
  /// In en, this message translates to:
  /// **'Sentiment'**
  String get sentiment;

  /// No description provided for @exchangeFlow.
  ///
  /// In en, this message translates to:
  /// **'Exchange Flow'**
  String get exchangeFlow;

  /// No description provided for @whaleActivity.
  ///
  /// In en, this message translates to:
  /// **'Whale Activity'**
  String get whaleActivity;

  /// No description provided for @atTimeOfTrade.
  ///
  /// In en, this message translates to:
  /// **'At the time of the trade, the social volume for {asset} was {value}.'**
  String atTimeOfTrade(Object asset, Object value);

  /// No description provided for @noMarketData.
  ///
  /// In en, this message translates to:
  /// **'No market data available for this time.'**
  String get noMarketData;

  /// No description provided for @positive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get positive;

  /// No description provided for @negative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get negative;

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// No description provided for @inflow.
  ///
  /// In en, this message translates to:
  /// **'Inflow'**
  String get inflow;

  /// No description provided for @outflow.
  ///
  /// In en, this message translates to:
  /// **'Outflow'**
  String get outflow;

  /// No description provided for @topHolders.
  ///
  /// In en, this message translates to:
  /// **'Top Holders Supply'**
  String get topHolders;

  /// No description provided for @activeAddresses.
  ///
  /// In en, this message translates to:
  /// **'Active Addresses (24h)'**
  String get activeAddresses;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
