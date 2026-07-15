import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ur'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Allah Waris Motors'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Customer Records & Financial Management'**
  String get tagline;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get search;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @businessOverview.
  ///
  /// In en, this message translates to:
  /// **'Business Overview'**
  String get businessOverview;

  /// No description provided for @recentCustomers.
  ///
  /// In en, this message translates to:
  /// **'Recent Customers'**
  String get recentCustomers;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customer records & financial overview'**
  String get dashboardSubtitle;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get totalCustomers;

  /// No description provided for @totalUdhaar.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalUdhaar;

  /// No description provided for @totalReceived.
  ///
  /// In en, this message translates to:
  /// **'Total Received'**
  String get totalReceived;

  /// No description provided for @remainingBalance.
  ///
  /// In en, this message translates to:
  /// **'Remaining Balance'**
  String get remainingBalance;

  /// No description provided for @todaysCollection.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Collection'**
  String get todaysCollection;

  /// No description provided for @registeredCustomers.
  ///
  /// In en, this message translates to:
  /// **'Registered customer records'**
  String get registeredCustomers;

  /// No description provided for @outstandingCredit.
  ///
  /// In en, this message translates to:
  /// **'Outstanding credit issued'**
  String get outstandingCredit;

  /// No description provided for @paymentsCollected.
  ///
  /// In en, this message translates to:
  /// **'Payments collected overall'**
  String get paymentsCollected;

  /// No description provided for @stillPending.
  ///
  /// In en, this message translates to:
  /// **'Still pending collection'**
  String get stillPending;

  /// No description provided for @paymentsToday.
  ///
  /// In en, this message translates to:
  /// **'Payments received today'**
  String get paymentsToday;

  /// No description provided for @activeBook.
  ///
  /// In en, this message translates to:
  /// **'Active book'**
  String get activeBook;

  /// No description provided for @needsFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Needs follow-up'**
  String get needsFollowUp;

  /// No description provided for @healthyInflow.
  ///
  /// In en, this message translates to:
  /// **'Healthy inflow'**
  String get healthyInflow;

  /// No description provided for @actionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Action needed'**
  String get actionNeeded;

  /// No description provided for @cleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get cleared;

  /// No description provided for @liveTotal.
  ///
  /// In en, this message translates to:
  /// **'Live total'**
  String get liveTotal;

  /// No description provided for @customersActionDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse and manage customer records'**
  String get customersActionDesc;

  /// No description provided for @transactionsActionDesc.
  ///
  /// In en, this message translates to:
  /// **'Record and track rental ledgers'**
  String get transactionsActionDesc;

  /// No description provided for @paymentsActionDesc.
  ///
  /// In en, this message translates to:
  /// **'Collect and review payment history'**
  String get paymentsActionDesc;

  /// No description provided for @reportsActionDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily, monthly and outstanding insights'**
  String get reportsActionDesc;

  /// No description provided for @backupActionDesc.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync & restore'**
  String get backupActionDesc;

  /// No description provided for @settingsActionDesc.
  ///
  /// In en, this message translates to:
  /// **'Security & preferences'**
  String get settingsActionDesc;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomersYet;

  /// No description provided for @noCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first customer to see them here.'**
  String get noCustomersHint;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @noTransactionsHint.
  ///
  /// In en, this message translates to:
  /// **'Payments will show up here once recorded.'**
  String get noTransactionsHint;

  /// No description provided for @couldNotLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Could not load dashboard'**
  String get couldNotLoadDashboard;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @fingerprintLogin.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint Login'**
  String get fingerprintLogin;

  /// No description provided for @fingerprintSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get fingerprintSubtitle;

  /// No description provided for @resetPin.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN'**
  String get resetPin;

  /// No description provided for @resetPinConfirm.
  ///
  /// In en, this message translates to:
  /// **'This removes your current PIN. You will need to create a new one. Continue?'**
  String get resetPinConfirm;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @urdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get urdu;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Allah Waris Motors helps you manage vehicles and rentals securely on this device.'**
  String get aboutBody;

  /// No description provided for @enterYourPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get enterYourPin;

  /// No description provided for @createPin.
  ///
  /// In en, this message translates to:
  /// **'Create PIN'**
  String get createPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @choosePin.
  ///
  /// In en, this message translates to:
  /// **'Choose a 4-digit PIN to secure the app'**
  String get choosePin;

  /// No description provided for @reenterPin.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your 4-digit PIN'**
  String get reenterPin;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone'**
  String get noPhone;

  /// No description provided for @dailyReport.
  ///
  /// In en, this message translates to:
  /// **'Daily Report'**
  String get dailyReport;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReport;

  /// No description provided for @customerLedger.
  ///
  /// In en, this message translates to:
  /// **'Customer Ledger'**
  String get customerLedger;

  /// No description provided for @outstandingCustomers.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Customers'**
  String get outstandingCustomers;

  /// No description provided for @dailyReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Transactions and collections for a day'**
  String get dailyReportDesc;

  /// No description provided for @monthlyReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Revenue and activity for a month'**
  String get monthlyReportDesc;

  /// No description provided for @customerLedgerDesc.
  ///
  /// In en, this message translates to:
  /// **'Full transaction and payment history'**
  String get customerLedgerDesc;

  /// No description provided for @outstandingCustomersDesc.
  ///
  /// In en, this message translates to:
  /// **'Customers with remaining balance'**
  String get outstandingCustomersDesc;

  /// No description provided for @languageEnglishNative.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishNative;

  /// No description provided for @languageUrduNative.
  ///
  /// In en, this message translates to:
  /// **'اردو'**
  String get languageUrduNative;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App display language'**
  String get languageSubtitle;
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
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
