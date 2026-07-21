import 'package:flutter/material.dart';

/// Lightweight, code-based localization for the app. Strings are looked up by
/// key from per-locale maps; missing keys fall back to English, then to the key
/// itself, so the UI never renders blank.
class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('en'));

  /// Human-readable name for a supported [languageCode], in its own script.
  static String languageName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
      default:
        return 'English';
    }
  }

  String t(String key) {
    final byLocale = _localized[locale.languageCode] ?? _localized['en']!;
    return byLocale[key] ?? _localized['en']![key] ?? key;
  }

  // Navigation
  String get navCatalog => t('navCatalog');
  String get navTeaching => t('navTeaching');
  String get navMyLearning => t('navMyLearning');
  String get navNotifications => t('navNotifications');
  String get navProfile => t('navProfile');

  // App / login
  String get appTitle => t('appTitle');
  String get appTagline => t('appTagline');
  String get signIn => t('signIn');
  String get signUp => t('signUp');
  String get email => t('email');
  String get password => t('password');
  String get name => t('name');
  String get role => t('role');
  String get student => t('student');
  String get instructor => t('instructor');
  String get demoAccounts => t('demoAccounts');

  // Profile / settings
  String get profile => t('profile');
  String get coursesTaught => t('coursesTaught');
  String get coursesEnrolled => t('coursesEnrolled');
  String get unreadNotifications => t('unreadNotifications');
  String get achievements => t('achievements');
  String get changePassword => t('changePassword');
  String get signOut => t('signOut');
  String get language => t('language');
  String get systemDefault => t('systemDefault');

  // Catalog / notifications
  String get catalog => t('catalog');
  String get searchCourses => t('searchCourses');
  String get allCategories => t('allCategories');
  String get notifications => t('notifications');
  String get noNotifications => t('noNotifications');

  // Common
  String get cancel => t('cancel');
  String get save => t('save');

  static const Map<String, Map<String, String>> _localized = {
    'en': {
      'navCatalog': 'Catalog',
      'navTeaching': 'Teaching',
      'navMyLearning': 'My Learning',
      'navNotifications': 'Notifications',
      'navProfile': 'Profile',
      'appTitle': 'LMS Learning Platform',
      'appTagline': 'Courses, progress tracking and notifications',
      'signIn': 'Sign in',
      'signUp': 'Sign up',
      'email': 'Email',
      'password': 'Password',
      'name': 'Name',
      'role': 'Role',
      'student': 'Student',
      'instructor': 'Instructor',
      'fullName': 'Full name',
      'confirmPassword': 'Confirm password',
      'createAccount': 'Create account',
      'demoAccounts': 'Demo accounts',
      'oneTapHint': 'One-tap sign in, or use password',
      'profile': 'Profile',
      'coursesTaught': 'Courses taught',
      'coursesEnrolled': 'Courses enrolled',
      'unreadNotifications': 'Unread notifications',
      'achievements': 'Achievements',
      'changePassword': 'Change password',
      'signOut': 'Sign out',
      'language': 'Language',
      'systemDefault': 'System default',
      'catalog': 'Course Catalog',
      'searchCourses': 'Search courses...',
      'allCategories': 'All',
      'noCoursesMatch': 'No courses match your search.',
      'notifications': 'Notifications',
      'noNotifications': 'No notifications yet',
      'markAllRead': 'Mark all read',
      'cancel': 'Cancel',
      'save': 'Save',
    },
    'ar': {
      'navCatalog': 'الدورات',
      'navTeaching': 'التدريس',
      'navMyLearning': 'تعلّمي',
      'navNotifications': 'الإشعارات',
      'navProfile': 'الملف الشخصي',
      'appTitle': 'منصة التعلّم LMS',
      'appTagline': 'الدورات وتتبّع التقدّم والإشعارات',
      'signIn': 'تسجيل الدخول',
      'signUp': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'name': 'الاسم',
      'role': 'الدور',
      'student': 'طالب',
      'instructor': 'مدرّس',
      'fullName': 'الاسم الكامل',
      'confirmPassword': 'تأكيد كلمة المرور',
      'createAccount': 'إنشاء حساب',
      'demoAccounts': 'حسابات تجريبية',
      'oneTapHint': 'تسجيل دخول بنقرة واحدة، أو استخدم كلمة المرور',
      'profile': 'الملف الشخصي',
      'coursesTaught': 'الدورات التي تُدرّسها',
      'coursesEnrolled': 'الدورات المسجّلة',
      'unreadNotifications': 'إشعارات غير مقروءة',
      'achievements': 'الإنجازات',
      'changePassword': 'تغيير كلمة المرور',
      'signOut': 'تسجيل الخروج',
      'language': 'اللغة',
      'systemDefault': 'لغة النظام',
      'catalog': 'دليل الدورات',
      'searchCourses': 'ابحث عن الدورات...',
      'allCategories': 'الكل',
      'noCoursesMatch': 'لا توجد دورات مطابقة لبحثك.',
      'notifications': 'الإشعارات',
      'noNotifications': 'لا توجد إشعارات بعد',
      'markAllRead': 'تعليم الكل كمقروء',
      'cancel': 'إلغاء',
      'save': 'حفظ',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
