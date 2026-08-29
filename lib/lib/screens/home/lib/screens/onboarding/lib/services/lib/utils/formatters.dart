import 'package:intl/intl.dart';

/// Mirrors fmt()/money() from the web apps: LKR ("Rs.") for a local
/// (mobile-verified) account, USD ("$") for an international
/// (email-verified, no mobile) account. Takes the flag explicitly
/// rather than reaching into storage itself, so it stays a pure,
/// easily-testable function - callers already have the user loaded
/// wherever this gets used.
String formatMoney(double amount, {required bool isInternational}) {
  final formatter = NumberFormat.currency(
    locale: isInternational ? 'en_US' : 'en_LK',
    symbol: isInternational ? r'$' : 'Rs. ',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

/// Short relative-ish date for list rows (order cards, ledger
/// history, notifications) - e.g. "12 Aug".
String formatShortDate(DateTime date) {
  return DateFormat('d MMM').format(date);
}
