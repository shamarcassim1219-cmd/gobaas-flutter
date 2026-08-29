/// Central translation dictionary - mirrors the web apps' `t(key)`
/// pattern (127-key en/si/ta dictionaries), just as a static Dart
/// map instead of a JS object. Every screen looks text up through
/// [AppLocalizations.of] rather than hardcoding English strings, so
/// the whole app can switch language in one place.
class AppLocalizations {
  AppLocalizations._();

  static const Map<String, Map<String, String>> _strings = {
    // ---- Common ----
    'appName': {'en': 'GOBAAS', 'si': 'ගෝබාස්', 'ta': 'கோபாஸ்'},
    'continueBtn': {'en': 'Continue', 'si': 'ඉදිරියට', 'ta': 'தொடரவும்'},
    'cancel': {'en': 'Cancel', 'si': 'අවලංගු කරන්න', 'ta': 'ரத்து செய்'},
    'confirmBtn': {'en': 'Confirm', 'si': 'තහවුරු කරන්න', 'ta': 'உறுதிசெய்'},
    'retry': {'en': 'Retry', 'si': 'නැවත උත්සාහ කරන්න', 'ta': 'மீண்டும் முயற்சிக்கவும்'},
    'notSet': {'en': '-', 'si': '-', 'ta': '-'},

    // ---- Guest / Login ----
    'guestBrowsing': {
      'en': "You're browsing as a guest",
      'si': 'ඔබ අමුත්තෙකු ලෙස පිරික්සමින් සිටී',
      'ta': 'நீங்கள் விருந்தினராக உலாவுகிறீர்கள்',
    },
    'guestBrowsingDesc': {
      'en': 'Login or register to hire a Baas and save your details.',
      'si': 'Baas කෙනෙකු කුලියට ගැනීමට සහ විස්තර සුරැකීමට ලොග් වන්න හෝ ලියාපදිංචි වන්න.',
      'ta': 'ஒரு பாஸை பணியமர்த்தவும் உங்கள் விவரங்களைச் சேமிக்கவும் உள்நுழையவும் அல்லது பதிவு செய்யவும்.',
    },
    'loginRegister': {'en': 'Login / Register', 'si': 'ලොග් වන්න / ලියාපදිංචි වන්න', 'ta': 'உள்நுழை / பதிவு செய்'},
    'loginRequired': {'en': 'Login Required', 'si': 'ලොග් වීම අවශ්‍යයි', 'ta': 'உள்நுழைவு தேவை'},
    'loginRequiredDesc': {
      'en': 'Please login or register to hire a Baas.',
      'si': 'Baas කෙනෙකු කුලියට ගැනීමට කරුණාකර ලොග් වන්න හෝ ලියාපදිංචි වන්න.',
      'ta': 'ஒரு பாஸை பணியமர்த்த உள்நுழையவும் அல்லது பதிவு செய்யவும்.',
    },
    'loginBtn': {'en': 'Login', 'si': 'ලොග් වන්න', 'ta': 'உள்நுழை'},
    'logout': {'en': 'Logout', 'si': 'ලොග් අවුට් වන්න', 'ta': 'வெளியேறு'},
    'logoutConfirm': {
      'en': 'Are you sure you want to logout?',
      'si': 'ඔබට ලොග් අවුට් වීමට අවශ්‍ය බව විශ්වාසද?',
      'ta': 'நீங்கள் வெளியேற விரும்புகிறீர்களா?',
    },
    'mobileNumber': {'en': 'Mobile Number', 'si': 'ජංගම දුරකථන අංකය', 'ta': 'மொபைல் எண்'},
    'mobileNumberHint': {
      'en': 'Enter your 10-digit Sri Lankan mobile number.',
      'si': 'ඔබේ ලංකා ජංගම දුරකථන අංකය ඇතුළත් කරන්න.',
      'ta': 'உங்கள் இலங்கை மொபைல் எண்ணை உள்ளிடவும்.',
    },
    'emailAddress': {'en': 'Email Address', 'si': 'විද්‍යුත් තැපැල් ලිපිනය', 'ta': 'மின்னஞ்சல் முகவரி'},
    'emailAddressHint': {
      'en': "We'll send you a verification code.",
      'si': 'අපි ඔබට තහවුරු කිරීමේ කේතයක් එවන්නෙමු.',
      'ta': 'நாங்கள் உங்களுக்கு சரிபார்ப்புக் குறியீட்டை அனுப்புவோம்.',
    },
    'country': {'en': 'Country', 'si': 'රට', 'ta': 'நாடு'},
    'selectCountry': {'en': 'Select your country', 'si': 'ඔබේ රට තෝරන්න', 'ta': 'உங்கள் நாட்டைத் தேர்ந்தெடுக்கவும்'},
    'sriLanka': {'en': 'Sri Lanka', 'si': 'ශ්‍රී ලංකාව', 'ta': 'இலங்கை'},
    'international': {'en': 'International', 'si': 'ජාත්‍යන්තර', 'ta': 'சர்வதேச'},
    'verificationCode': {'en': 'Enter verification code', 'si': 'තහවුරු කිරීමේ කේතය ඇතුළත් කරන්න', 'ta': 'சரிபார்ப்புக் குறியீட்டை உள்ளிடவும்'},
    'weSentCodeTo': {'en': 'We sent a code to', 'si': 'අපි කේතයක් එවා ඇත', 'ta': 'நாங்கள் ஒரு குறியீட்டை அனுப்பியுள்ளோம்'},
    'verify': {'en': 'Verify', 'si': 'තහවුරු කරන්න', 'ta': 'சரிபார்க்கவும்'},
    'whatsYourName': {'en': "What's your name?", 'si': 'ඔබේ නම කුමක්ද?', 'ta': 'உங்கள் பெயர் என்ன?'},
    'nameSubtitle': {
      'en': 'This is how Baas and customers will see you.',
      'si': 'Baas ලා සහ පාරිභෝගිකයින් ඔබව දකින්නේ මෙසේය.',
      'ta': 'பாஸ்கள் மற்றும் வாடிக்கையாளர்கள் உங்களை இப்படித்தான் பார்ப்பார்கள்.',
    },
    'firstName': {'en': 'First name', 'si': 'මුල් නම', 'ta': 'முதல் பெயர்'},
    'lastName': {'en': 'Last name', 'si': 'අග නම', 'ta': 'கடைசி பெயர்'},

    // ---- Home ----
    'goodMorning': {'en': 'Good morning', 'si': 'සුභ උදෑසනක්', 'ta': 'காலை வணக்கம்'},
    'goodAfternoon': {'en': 'Good afternoon', 'si': 'සුභ දහවලක්', 'ta': 'மதிய வணக்கம்'},
    'goodEvening': {'en': 'Good evening', 'si': 'සුභ සන්ධ්‍යාවක්', 'ta': 'மாலை வணக்கம்'},
    'walletBalance': {'en': 'WALLET BALANCE', 'si': 'මුදල් පසුම්බි ශේෂය', 'ta': 'பணப்பை இருப்பு'},
    'topUp': {'en': 'Top Up', 'si': 'මුදල් එකතු කරන්න', 'ta': 'நிதி சேர்'},
    'wallet': {'en': 'Wallet', 'si': 'මුදල් පසුම්බිය', 'ta': 'பணப்பை'},
    'myOrders': {'en': 'My Orders', 'si': 'මගේ ඇණවුම්', 'ta': 'எனது ஆர்டர்கள்'},
    'reviews': {'en': 'Reviews', 'si': 'සමාලෝචන', 'ta': 'விமர்சனங்கள்'},
    'support': {'en': 'Support', 'si': 'සහාය', 'ta': 'ஆதரவு'},
    'profile': {'en': 'Profile', 'si': 'පැතිකඩ', 'ta': 'சுயவிவரம்'},
    'needABaas': {'en': 'Need a Baas?', 'si': 'Baas කෙනෙක් අවශ්‍යද?', 'ta': 'ஒரு பாஸ் தேவையா?'},
    'needABaasDesc': {
      'en': 'Search verified professionals near you.',
      'si': 'ඔබ අසල තහවුරු කළ වෘත්තිකයන් සොයන්න.',
      'ta': 'உங்களுக்கு அருகில் சரிபார்க்கப்பட்ட நிபுணர்களைத் தேடுங்கள்.',
    },
    'searchNearMe': {'en': 'Search Baas Near Me', 'si': 'ළඟම Baas සොයන්න', 'ta': 'அருகிலுள்ள பாஸைத் தேடு'},
    'searching': {'en': 'Searching...', 'si': 'සොයමින්...', 'ta': 'தேடுகிறது...'},
    'noBaasFound': {'en': 'No Baas found nearby right now.', 'si': 'දැනට ළඟ Baas කෙනෙක් හමු නොවීය.', 'ta': 'அருகில் பாஸ் இல்லை.'},
    'nearbyOfflineNote': {
      'en': 'Nearby Baas (currently offline - may respond later)',
      'si': 'ළඟම Baas (දැනට offline - පසුව පිළිතුරු දිය හැක)',
      'ta': 'அருகிலுள்ள பாஸ் (தற்போது ஆஃப்லைனில் - பின்னர் பதிலளிக்கலாம்)',
    },

    // ---- Profile ----
    'mobile': {'en': 'Mobile', 'si': 'ජංගම දුරකථනය', 'ta': 'மொபைல்'},
    'email': {'en': 'Email', 'si': 'විද්‍යුත් තැපෑල', 'ta': 'மின்னஞ்சல்'},
    'myReviews': {'en': 'My Reviews', 'si': 'මගේ සමාලෝචන', 'ta': 'எனது விமர்சனங்கள்'},
    'aboutGobaas': {'en': 'About GOBAAS', 'si': 'GOBAAS ගැන', 'ta': 'GOBAAS பற்றி'},
    'language': {'en': 'Language', 'si': 'භාෂාව', 'ta': 'மொழி'},

    // ---- Hire ----
    'hire': {'en': 'Hire', 'si': 'කුලියට ගන්න', 'ta': 'பணியமர்த்து'},
    'location': {'en': 'Location', 'si': 'ස්ථානය', 'ta': 'இடம்'},
    'locationHint': {'en': 'Where should the Baas come?', 'si': 'Baas කෙනා එන්නේ කොහෙන්ද?', 'ta': 'பாஸ் எங்கு வர வேண்டும்?'},
    'numberOfDays': {'en': 'Number of Days', 'si': 'දින ගණන', 'ta': 'நாட்களின் எண்ணிக்கை'},
    'preferredDate': {'en': 'Preferred Date', 'si': 'කැමති දිනය', 'ta': 'விருப்பமான தேதி'},
    'selectDate': {'en': 'Select a date', 'si': 'දිනයක් තෝරන්න', 'ta': 'தேதியைத் தேர்ந்தெடுக்கவும்'},
    'paymentMethod': {'en': 'Payment Method', 'si': 'ගෙවීම් ක්‍රමය', 'ta': 'கட்டண முறை'},
    'payNow': {'en': 'Pay Now', 'si': 'දැන් ගෙවන්න', 'ta': 'இப்போது செலுத்து'},
    'payNowDesc': {
      'en': 'Pay online, held securely until the job is done',
      'si': 'මාර්ගගතව ගෙවන්න, කාර්යය අවසන් වන තෙක් ආරක්ෂිතව තබා ගනී',
      'ta': 'ஆன்லைனில் செலுத்துங்கள், வேலை முடியும் வரை பாதுகாப்பாக வைக்கப்படும்',
    },
    'payDirect': {'en': 'Pay Direct', 'si': 'කෙලින්ම ගෙවන්න', 'ta': 'நேரடியாக செலுத்து'},
    'payDirectDesc': {
      'en': 'Pay the Baas directly, in person',
      'si': 'Baas කෙනාට කෙලින්ම, පෞද්ගලිකව ගෙවන්න',
      'ta': 'பாஸிடம் நேரடியாக, நேரில் செலுத்துங்கள்',
    },
    'total': {'en': 'Total', 'si': 'මුළු එකතුව', 'ta': 'மொத்தம்'},
    'confirmOrder': {'en': 'Confirm Order', 'si': 'ඇණවුම තහවුරු කරන්න', 'ta': 'ஆர்டரை உறுதிசெய்'},
    'orderCreated': {'en': 'Order Created', 'si': 'ඇණවුම සාදන ලදී', 'ta': 'ஆர்டர் உருவாக்கப்பட்டது'},
    'viewMyOrders': {'en': 'View My Orders', 'si': 'මගේ ඇණවුම් බලන්න', 'ta': 'எனது ஆர்டர்களைப் பார்க்கவும்'},

    // ---- Orders ----
    'myOrdersTitle': {'en': 'My Orders', 'si': 'මගේ ඇණවුම්', 'ta': 'எனது ஆர்டர்கள்'},
    'noOrdersYet': {'en': 'No orders yet.', 'si': 'තවම ඇණවුම් නැත.', 'ta': 'இன்னும் ஆர்டர்கள் இல்லை.'},

    // ---- Notifications ----
    'notificationsTitle': {'en': 'Notifications', 'si': 'දැනුම්දීම්', 'ta': 'அறிவிப்புகள்'},
    'markAllRead': {'en': 'Mark all read', 'si': 'සියල්ල කියවූ ලෙස සලකුණු කරන්න', 'ta': 'அனைத்தையும் படித்ததாகக் குறி'},
    'noNotificationsYet': {'en': 'No notifications yet.', 'si': 'තවම දැනුම්දීම් නැත.', 'ta': 'இன்னும் அறிவிப்புகள் இல்லை.'},

    // ---- Wallet ----
    'walletTitle': {'en': 'Wallet', 'si': 'මුදල් පසුම්බිය', 'ta': 'பணப்பை'},
    'availableBalance': {'en': 'AVAILABLE BALANCE', 'si': 'ලබා ගත හැකි ශේෂය', 'ta': 'கிடைக்கும் இருப்பு'},
    'transactionHistory': {'en': 'Transaction History', 'si': 'ගනුදෙනු ඉතිහාසය', 'ta': 'பரிவர்த்தனை வரலாறு'},
    'noTransactionsYet': {'en': 'No transactions yet.', 'si': 'තවම ගනුදෙනු නැත.', 'ta': 'இன்னும் பரிவர்த்தனைகள் இல்லை.'},
    'pending': {'en': 'PENDING', 'si': 'පොරොත්තුවෙන්', 'ta': 'நிலுவையில்'},
  };

  /// Looks up [key] for [langCode] ('en' | 'si' | 'ta'), falling
  /// back to English, then to the key itself, so a missing
  /// translation never crashes the screen - it just shows in
  /// English (or the raw key, worst case) instead.
  static String t(String key, String langCode) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[langCode] ?? entry['en'] ?? key;
  }
}
