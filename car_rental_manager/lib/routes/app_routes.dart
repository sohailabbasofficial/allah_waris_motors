import 'package:flutter/material.dart';

import '../features/auth/presentation/change_pin_screen.dart';
import '../features/auth/presentation/create_pin_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../modules/backup/screens/backup_screen.dart';
import '../modules/backup/screens/google_sign_in_screen.dart';
import '../modules/backup/screens/restore_screen.dart';
import '../modules/customer/screens/add_customer_screen.dart';
import '../modules/customer/screens/customer_detail_screen.dart';
import '../modules/customer/screens/customer_list_screen.dart';
import '../modules/customer/screens/edit_customer_screen.dart';
import '../modules/payment/screens/add_payment_screen.dart';
import '../modules/payment/screens/edit_payment_screen.dart';
import '../modules/payment/screens/payment_history_screen.dart';
import '../modules/payment/screens/payment_list_screen.dart';
import '../modules/reports/screens/customer_ledger_screen.dart';
import '../modules/reports/screens/daily_report_screen.dart';
import '../modules/reports/screens/monthly_report_screen.dart';
import '../modules/reports/screens/outstanding_customers_screen.dart';
import '../modules/reports/screens/reports_home_screen.dart';
import '../modules/transaction/screens/add_transaction_screen.dart';
import '../modules/transaction/screens/edit_transaction_screen.dart';
import '../modules/transaction/screens/transaction_detail_screen.dart';
import '../modules/transaction/screens/transaction_list_screen.dart';

/// Centralized named routes for Allah Waris Motors navigation.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String createPin = '/create-pin';
  static const String login = '/login';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String changePin = '/change-pin';
  static const String customers = '/customers';
  static const String addCustomer = '/add-customer';
  static const String customerDetail = '/customer-detail';
  static const String editCustomer = '/edit-customer';
  static const String transactions = '/transactions';
  static const String addTransaction = '/add-transaction';
  static const String transactionDetail = '/transaction-detail';
  static const String editTransaction = '/edit-transaction';
  static const String payments = '/payments';
  static const String addPayment = '/add-payment';
  static const String editPayment = '/edit-payment';
  static const String paymentHistory = '/payment-history';
  static const String reports = '/reports';
  static const String dailyReport = '/daily-report';
  static const String monthlyReport = '/monthly-report';
  static const String customerLedger = '/customer-ledger';
  static const String outstandingCustomers = '/outstanding-customers';
  static const String backup = '/backup';
  static const String restoreBackup = '/restore-backup';
  static const String googleSignIn = '/google-sign-in';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        createPin: (_) => const CreatePinScreen(),
        login: (_) => const LoginScreen(),
        home: (_) => const HomeScreen(),
        settings: (_) => const SettingsScreen(),
        changePin: (_) => const ChangePinScreen(),
        customers: (_) => const CustomerListScreen(),
        addCustomer: (_) => const AddCustomerScreen(),
        transactions: (_) => const TransactionListScreen(),
        addTransaction: (_) => const AddTransactionScreen(),
        payments: (_) => const PaymentListScreen(),
        reports: (_) => const ReportsHomeScreen(),
        dailyReport: (_) => const DailyReportScreen(),
        monthlyReport: (_) => const MonthlyReportScreen(),
        outstandingCustomers: (_) => const OutstandingCustomersScreen(),
        backup: (_) => const BackupScreen(),
        restoreBackup: (_) => const RestoreScreen(),
        googleSignIn: (_) => const GoogleSignInScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case customerDetail:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              CustomerDetailScreen(customerId: settings.arguments as int),
        );
      case editCustomer:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              EditCustomerScreen(customerId: settings.arguments as int),
        );
      case transactionDetail:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => TransactionDetailScreen(
            transactionId: settings.arguments as int,
          ),
        );
      case editTransaction:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => EditTransactionScreen(
            transactionId: settings.arguments as int,
          ),
        );
      case addPayment:
        final customerId = settings.arguments as int?;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              AddPaymentScreen(preselectedCustomerId: customerId),
        );
      case editPayment:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              EditPaymentScreen(paymentId: settings.arguments as int),
        );
      case paymentHistory:
        final args = settings.arguments;
        if (args is Map) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => PaymentHistoryScreen(
              customerId: args['customerId'] as int,
              customerName: args['customerName'] as String?,
            ),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              PaymentHistoryScreen(customerId: settings.arguments as int),
        );
      case customerLedger:
        final customerId = settings.arguments as int?;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              CustomerLedgerScreen(preselectedCustomerId: customerId),
        );
      default:
        return null;
    }
  }
}
