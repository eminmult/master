import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_az.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('az'),
    Locale('en'),
    Locale('ru'),
    Locale('tr')
  ];

  /// No description provided for @cookie_title.
  ///
  /// In en, this message translates to:
  /// **'We use cookies'**
  String get cookie_title;

  /// No description provided for @cookie_body.
  ///
  /// In en, this message translates to:
  /// **'This site uses cookies to improve your experience.'**
  String get cookie_body;

  /// No description provided for @cookie_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get cookie_policy;

  /// No description provided for @cookie_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get cookie_accept;

  /// No description provided for @cookie_reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get cookie_reject;

  /// No description provided for @lang_choose.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get lang_choose;

  /// No description provided for @lang_current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get lang_current;

  /// No description provided for @cal_months_0.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get cal_months_0;

  /// No description provided for @cal_months_1.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get cal_months_1;

  /// No description provided for @cal_months_2.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get cal_months_2;

  /// No description provided for @cal_months_3.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get cal_months_3;

  /// No description provided for @cal_months_4.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get cal_months_4;

  /// No description provided for @cal_months_5.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get cal_months_5;

  /// No description provided for @cal_months_6.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get cal_months_6;

  /// No description provided for @cal_months_7.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get cal_months_7;

  /// No description provided for @cal_months_8.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get cal_months_8;

  /// No description provided for @cal_months_9.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get cal_months_9;

  /// No description provided for @cal_months_10.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get cal_months_10;

  /// No description provided for @cal_months_11.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get cal_months_11;

  /// No description provided for @cal_months_short_0.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get cal_months_short_0;

  /// No description provided for @cal_months_short_1.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get cal_months_short_1;

  /// No description provided for @cal_months_short_2.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get cal_months_short_2;

  /// No description provided for @cal_months_short_3.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get cal_months_short_3;

  /// No description provided for @cal_months_short_4.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get cal_months_short_4;

  /// No description provided for @cal_months_short_5.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get cal_months_short_5;

  /// No description provided for @cal_months_short_6.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get cal_months_short_6;

  /// No description provided for @cal_months_short_7.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get cal_months_short_7;

  /// No description provided for @cal_months_short_8.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get cal_months_short_8;

  /// No description provided for @cal_months_short_9.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get cal_months_short_9;

  /// No description provided for @cal_months_short_10.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get cal_months_short_10;

  /// No description provided for @cal_months_short_11.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get cal_months_short_11;

  /// No description provided for @cal_weekdays_short_0.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get cal_weekdays_short_0;

  /// No description provided for @cal_weekdays_short_1.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get cal_weekdays_short_1;

  /// No description provided for @cal_weekdays_short_2.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get cal_weekdays_short_2;

  /// No description provided for @cal_weekdays_short_3.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get cal_weekdays_short_3;

  /// No description provided for @cal_weekdays_short_4.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get cal_weekdays_short_4;

  /// No description provided for @cal_weekdays_short_5.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get cal_weekdays_short_5;

  /// No description provided for @cal_weekdays_short_6.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get cal_weekdays_short_6;

  /// No description provided for @cal_weekdays_long_0.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get cal_weekdays_long_0;

  /// No description provided for @cal_weekdays_long_1.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get cal_weekdays_long_1;

  /// No description provided for @cal_weekdays_long_2.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get cal_weekdays_long_2;

  /// No description provided for @cal_weekdays_long_3.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get cal_weekdays_long_3;

  /// No description provided for @cal_weekdays_long_4.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get cal_weekdays_long_4;

  /// No description provided for @cal_weekdays_long_5.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get cal_weekdays_long_5;

  /// No description provided for @cal_weekdays_long_6.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get cal_weekdays_long_6;

  /// No description provided for @nav_services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get nav_services;

  /// No description provided for @nav_categories.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get nav_categories;

  /// No description provided for @nav_masters.
  ///
  /// In en, this message translates to:
  /// **'Masters'**
  String get nav_masters;

  /// No description provided for @nav_how_it_works.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get nav_how_it_works;

  /// No description provided for @nav_contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get nav_contact;

  /// No description provided for @nav_login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get nav_login;

  /// No description provided for @nav_register.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get nav_register;

  /// No description provided for @nav_logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get nav_logout;

  /// No description provided for @nav_panel.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get nav_panel;

  /// No description provided for @nav_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get nav_dashboard;

  /// No description provided for @nav_my_orders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get nav_my_orders;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @nav_public_profile.
  ///
  /// In en, this message translates to:
  /// **'My public profile'**
  String get nav_public_profile;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get nav_notifications;

  /// No description provided for @nav_admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get nav_admin;

  /// No description provided for @hero_chip.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE 24/7 FOR EMERGENCIES'**
  String get hero_chip;

  /// No description provided for @hero_home_line1.
  ///
  /// In en, this message translates to:
  /// **'Professional Home'**
  String get hero_home_line1;

  /// No description provided for @hero_home_line2_before.
  ///
  /// In en, this message translates to:
  /// **'Services, Just a'**
  String get hero_home_line2_before;

  /// No description provided for @hero_home_highlight.
  ///
  /// In en, this message translates to:
  /// **'Click'**
  String get hero_home_highlight;

  /// No description provided for @hero_home_line2_after.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get hero_home_line2_after;

  /// No description provided for @hero_home_subtitle.
  ///
  /// In en, this message translates to:
  /// **'From emergency repairs to renovation projects, our vetted experts deliver premium service to your doorstep.'**
  String get hero_home_subtitle;

  /// No description provided for @hero_search_q_placeholder.
  ///
  /// In en, this message translates to:
  /// **'What do you need help with today?'**
  String get hero_search_q_placeholder;

  /// No description provided for @hero_default_location.
  ///
  /// In en, this message translates to:
  /// **'Baku, Azerbaijan'**
  String get hero_default_location;

  /// No description provided for @hero_find_experts.
  ///
  /// In en, this message translates to:
  /// **'Find Experts'**
  String get hero_find_experts;

  /// No description provided for @hero_trust_reviews.
  ///
  /// In en, this message translates to:
  /// **'from 50k+ reviews'**
  String get hero_trust_reviews;

  /// No description provided for @hero_trust_licensed.
  ///
  /// In en, this message translates to:
  /// **'Licensed & Insured Pros'**
  String get hero_trust_licensed;

  /// No description provided for @hero_trust_response.
  ///
  /// In en, this message translates to:
  /// **'Avg response < 30 min'**
  String get hero_trust_response;

  /// No description provided for @hero_book_cta.
  ///
  /// In en, this message translates to:
  /// **'Book a Service'**
  String get hero_book_cta;

  /// No description provided for @hero_highlight.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get hero_highlight;

  /// No description provided for @hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Plumber, electrician, welder and other professionals at one click. Real-time tracking, transparent rating system.'**
  String get hero_subtitle;

  /// No description provided for @hero_cta_order.
  ///
  /// In en, this message translates to:
  /// **'Call a master'**
  String get hero_cta_order;

  /// No description provided for @hero_cta_become.
  ///
  /// In en, this message translates to:
  /// **'Become a master'**
  String get hero_cta_become;

  /// No description provided for @hero_stat_masters.
  ///
  /// In en, this message translates to:
  /// **'Verified masters'**
  String get hero_stat_masters;

  /// No description provided for @hero_stat_orders.
  ///
  /// In en, this message translates to:
  /// **'Completed orders'**
  String get hero_stat_orders;

  /// No description provided for @hero_stat_rating.
  ///
  /// In en, this message translates to:
  /// **'Avg. rating'**
  String get hero_stat_rating;

  /// No description provided for @hero_title_before.
  ///
  /// In en, this message translates to:
  /// **'Call a home master in'**
  String get hero_title_before;

  /// No description provided for @hero_title_after.
  ///
  /// In en, this message translates to:
  /// **''**
  String get hero_title_after;

  /// No description provided for @hero_search_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Plumber, electrician, welder...'**
  String get hero_search_placeholder;

  /// No description provided for @hero_search_btn.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get hero_search_btn;

  /// No description provided for @hero_smart_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Describe your problem — e.g., \"burst pipe in the bathroom\"'**
  String get hero_smart_placeholder;

  /// No description provided for @hero_smart_find.
  ///
  /// In en, this message translates to:
  /// **'Find master'**
  String get hero_smart_find;

  /// No description provided for @hero_smart_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get hero_smart_analyzing;

  /// No description provided for @hero_smart_error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t recognize. Try again or open the masters list.'**
  String get hero_smart_error;

  /// No description provided for @hero_attach_photo.
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get hero_attach_photo;

  /// No description provided for @hero_photo_attached.
  ///
  /// In en, this message translates to:
  /// **'Photo attached'**
  String get hero_photo_attached;

  /// No description provided for @hero_remove_photo.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get hero_remove_photo;

  /// No description provided for @hero_photo_too_large.
  ///
  /// In en, this message translates to:
  /// **'Photo too large (max 5 MB)'**
  String get hero_photo_too_large;

  /// No description provided for @hero_use_my_location.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get hero_use_my_location;

  /// No description provided for @hero_detecting_geo.
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get hero_detecting_geo;

  /// No description provided for @hero_geo_ready.
  ///
  /// In en, this message translates to:
  /// **'Location detected'**
  String get hero_geo_ready;

  /// No description provided for @hero_geo_denied.
  ///
  /// In en, this message translates to:
  /// **'Location access denied'**
  String get hero_geo_denied;

  /// No description provided for @hero_geo_unsupported.
  ///
  /// In en, this message translates to:
  /// **'Geolocation not supported by your browser'**
  String get hero_geo_unsupported;

  /// No description provided for @popular_title.
  ///
  /// In en, this message translates to:
  /// **'Popular Services'**
  String get popular_title;

  /// No description provided for @popular_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted by over 50,000 homeowners this month alone.'**
  String get popular_subtitle;

  /// No description provided for @popular_see_all.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get popular_see_all;

  /// No description provided for @popular_popular_tag.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get popular_popular_tag;

  /// No description provided for @popular_book_now.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get popular_book_now;

  /// No description provided for @popular_electrician.
  ///
  /// In en, this message translates to:
  /// **'Electrician'**
  String get popular_electrician;

  /// No description provided for @popular_electrician_desc.
  ///
  /// In en, this message translates to:
  /// **'Panel upgrades, wiring, lighting and smart-home installs.'**
  String get popular_electrician_desc;

  /// No description provided for @popular_plumber.
  ///
  /// In en, this message translates to:
  /// **'Plumber'**
  String get popular_plumber;

  /// No description provided for @popular_plumber_desc.
  ///
  /// In en, this message translates to:
  /// **'Leak detection, pipe repairs and full installations.'**
  String get popular_plumber_desc;

  /// No description provided for @popular_handyman.
  ///
  /// In en, this message translates to:
  /// **'Handyman'**
  String get popular_handyman;

  /// No description provided for @popular_handyman_desc.
  ///
  /// In en, this message translates to:
  /// **'General mounting, furniture assembly and home maintenance.'**
  String get popular_handyman_desc;

  /// No description provided for @popular_hvac.
  ///
  /// In en, this message translates to:
  /// **'HVAC'**
  String get popular_hvac;

  /// No description provided for @popular_hvac_desc.
  ///
  /// In en, this message translates to:
  /// **'AC repair, furnace maintenance and air-quality checks.'**
  String get popular_hvac_desc;

  /// No description provided for @popular_cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get popular_cleaning;

  /// No description provided for @popular_cleaning_desc.
  ///
  /// In en, this message translates to:
  /// **'Deep cleaning, move-out cleans and sanitization.'**
  String get popular_cleaning_desc;

  /// No description provided for @popular_landscaping.
  ///
  /// In en, this message translates to:
  /// **'Landscaping'**
  String get popular_landscaping;

  /// No description provided for @popular_landscaping_desc.
  ///
  /// In en, this message translates to:
  /// **'Lawn care, garden design and tree-trimming services.'**
  String get popular_landscaping_desc;

  /// No description provided for @popular_painting.
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get popular_painting;

  /// No description provided for @popular_painting_desc.
  ///
  /// In en, this message translates to:
  /// **'Interior and exterior painting and wallpapering.'**
  String get popular_painting_desc;

  /// No description provided for @popular_roofing.
  ///
  /// In en, this message translates to:
  /// **'Roofing'**
  String get popular_roofing;

  /// No description provided for @popular_roofing_desc.
  ///
  /// In en, this message translates to:
  /// **'Roof repairs, inspections and gutter cleaning.'**
  String get popular_roofing_desc;

  /// No description provided for @steps_title.
  ///
  /// In en, this message translates to:
  /// **'Simple 4-Step Booking'**
  String get steps_title;

  /// No description provided for @steps_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get your home project started in under 60 seconds. Efficient, transparent and completely stress-free.'**
  String get steps_subtitle;

  /// No description provided for @steps_s1_title.
  ///
  /// In en, this message translates to:
  /// **'Describe Issue'**
  String get steps_s1_title;

  /// No description provided for @steps_s1_desc.
  ///
  /// In en, this message translates to:
  /// **'Tell us your problem\nor browse our services.'**
  String get steps_s1_desc;

  /// No description provided for @steps_s2_title.
  ///
  /// In en, this message translates to:
  /// **'Instantly Book'**
  String get steps_s2_title;

  /// No description provided for @steps_s2_desc.
  ///
  /// In en, this message translates to:
  /// **'Choose a time slot\nthat fits your schedule.'**
  String get steps_s2_desc;

  /// No description provided for @steps_s3_title.
  ///
  /// In en, this message translates to:
  /// **'Expert Arrives'**
  String get steps_s3_title;

  /// No description provided for @steps_s3_desc.
  ///
  /// In en, this message translates to:
  /// **'A verified pro arrives\nat your door on time.'**
  String get steps_s3_desc;

  /// No description provided for @steps_s4_title.
  ///
  /// In en, this message translates to:
  /// **'Secure Pay'**
  String get steps_s4_title;

  /// No description provided for @steps_s4_desc.
  ///
  /// In en, this message translates to:
  /// **'Pay safely via the app\nonce work is completed.'**
  String get steps_s4_desc;

  /// No description provided for @trust_title_before.
  ///
  /// In en, this message translates to:
  /// **'Why Thousands Trust'**
  String get trust_title_before;

  /// No description provided for @trust_title_brand.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get trust_title_brand;

  /// No description provided for @trust_stat_satisfaction.
  ///
  /// In en, this message translates to:
  /// **'Customer Satisfaction'**
  String get trust_stat_satisfaction;

  /// No description provided for @trust_stat_appstore.
  ///
  /// In en, this message translates to:
  /// **'App Store Rating'**
  String get trust_stat_appstore;

  /// No description provided for @trust_t1_title.
  ///
  /// In en, this message translates to:
  /// **'Vetted Professionals'**
  String get trust_t1_title;

  /// No description provided for @trust_t1_desc.
  ///
  /// In en, this message translates to:
  /// **'Every specialist is background-checked, licensed and insured. Only the top 5% of applicants make the cut.'**
  String get trust_t1_desc;

  /// No description provided for @trust_t2_title.
  ///
  /// In en, this message translates to:
  /// **'Transparent Pricing'**
  String get trust_t2_title;

  /// No description provided for @trust_t2_desc.
  ///
  /// In en, this message translates to:
  /// **'No hidden fees or surprise costs. See the fixed rate or estimated quote before you hit book.'**
  String get trust_t2_desc;

  /// No description provided for @trust_t3_title.
  ///
  /// In en, this message translates to:
  /// **'24/7 Premium Support'**
  String get trust_t3_title;

  /// No description provided for @trust_t3_desc.
  ///
  /// In en, this message translates to:
  /// **'Our dedicated concierge team is available around the clock for any request or emergency.'**
  String get trust_t3_desc;

  /// No description provided for @trust_t4_title.
  ///
  /// In en, this message translates to:
  /// **'Safety Guaranteed'**
  String get trust_t4_title;

  /// No description provided for @trust_t4_desc.
  ///
  /// In en, this message translates to:
  /// **'Your home is protected by our Service Guarantee on every single booking.'**
  String get trust_t4_desc;

  /// No description provided for @categories_label.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get categories_label;

  /// No description provided for @categories_title.
  ///
  /// In en, this message translates to:
  /// **'Service categories'**
  String get categories_title;

  /// No description provided for @categories_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the specialist you need'**
  String get categories_subtitle;

  /// No description provided for @categories_see_all.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get categories_see_all;

  /// No description provided for @categories_page_title.
  ///
  /// In en, this message translates to:
  /// **'Service categories'**
  String get categories_page_title;

  /// No description provided for @categories_page_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the service you need'**
  String get categories_page_subtitle;

  /// No description provided for @how_label.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get how_label;

  /// No description provided for @how_title.
  ///
  /// In en, this message translates to:
  /// **'Four steps to a finished job'**
  String get how_title;

  /// No description provided for @how_step1_title.
  ///
  /// In en, this message translates to:
  /// **'Create an order'**
  String get how_step1_title;

  /// No description provided for @how_step1_desc.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem, add photos and specify the address'**
  String get how_step1_desc;

  /// No description provided for @how_step2_title.
  ///
  /// In en, this message translates to:
  /// **'Master accepts'**
  String get how_step2_title;

  /// No description provided for @how_step2_desc.
  ///
  /// In en, this message translates to:
  /// **'The nearest suitable master accepts your order'**
  String get how_step2_desc;

  /// No description provided for @how_step3_title.
  ///
  /// In en, this message translates to:
  /// **'Track movement'**
  String get how_step3_title;

  /// No description provided for @how_step3_desc.
  ///
  /// In en, this message translates to:
  /// **'Track the master\'s location on the map in real time'**
  String get how_step3_desc;

  /// No description provided for @how_step4_title.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get how_step4_title;

  /// No description provided for @how_step4_desc.
  ///
  /// In en, this message translates to:
  /// **'After work is done, rate each other'**
  String get how_step4_desc;

  /// No description provided for @how_step1_long.
  ///
  /// In en, this message translates to:
  /// **'Select a category, describe the problem, specify the address and add photos. Creating an order takes 1-2 minutes.'**
  String get how_step1_long;

  /// No description provided for @how_step2_long.
  ///
  /// In en, this message translates to:
  /// **'The system sends your order to the nearest suitable masters. The first to accept is yours.'**
  String get how_step2_long;

  /// No description provided for @how_step3_long.
  ///
  /// In en, this message translates to:
  /// **'Track the master\'s location on the map. See arrival time, call or message if needed.'**
  String get how_step3_long;

  /// No description provided for @how_step4_long.
  ///
  /// In en, this message translates to:
  /// **'After the work, rate the master. The master will also rate you. A transparent rating system benefits everyone.'**
  String get how_step4_long;

  /// No description provided for @cta_ready.
  ///
  /// In en, this message translates to:
  /// **'Ready?'**
  String get cta_ready;

  /// No description provided for @cta_first_order.
  ///
  /// In en, this message translates to:
  /// **'Create your first order now'**
  String get cta_first_order;

  /// No description provided for @cta_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get cta_start;

  /// No description provided for @cta_start_now.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get cta_start_now;

  /// No description provided for @auth_login_title.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get auth_login_title;

  /// No description provided for @auth_login_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get auth_login_subtitle;

  /// No description provided for @auth_phone_or_email.
  ///
  /// In en, this message translates to:
  /// **'Phone or email'**
  String get auth_phone_or_email;

  /// No description provided for @auth_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_password;

  /// No description provided for @auth_password_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get auth_password_confirm;

  /// No description provided for @auth_logging_in.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get auth_logging_in;

  /// No description provided for @auth_no_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get auth_no_account;

  /// No description provided for @auth_client_register.
  ///
  /// In en, this message translates to:
  /// **'Client registration'**
  String get auth_client_register;

  /// No description provided for @auth_master_register.
  ///
  /// In en, this message translates to:
  /// **'Master registration'**
  String get auth_master_register;

  /// No description provided for @auth_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get auth_have_account;

  /// No description provided for @auth_register_client_title.
  ///
  /// In en, this message translates to:
  /// **'Client registration'**
  String get auth_register_client_title;

  /// No description provided for @auth_register_client_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Register to call a master'**
  String get auth_register_client_subtitle;

  /// No description provided for @auth_register_master_title.
  ///
  /// In en, this message translates to:
  /// **'Master registration'**
  String get auth_register_master_title;

  /// No description provided for @auth_register_master_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Register as a master and accept orders'**
  String get auth_register_master_subtitle;

  /// No description provided for @auth_first_name.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get auth_first_name;

  /// No description provided for @auth_last_name.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get auth_last_name;

  /// No description provided for @auth_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get auth_phone;

  /// No description provided for @auth_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get auth_email;

  /// No description provided for @auth_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get auth_city;

  /// No description provided for @auth_district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get auth_district;

  /// No description provided for @auth_experience.
  ///
  /// In en, this message translates to:
  /// **'Experience (years)'**
  String get auth_experience;

  /// No description provided for @auth_about_you.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get auth_about_you;

  /// No description provided for @auth_about_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Tell about your experience and specialization...'**
  String get auth_about_placeholder;

  /// No description provided for @auth_select_categories.
  ///
  /// In en, this message translates to:
  /// **'Service categories'**
  String get auth_select_categories;

  /// No description provided for @auth_select_min_one.
  ///
  /// In en, this message translates to:
  /// **'at least 1'**
  String get auth_select_min_one;

  /// No description provided for @auth_registering.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get auth_registering;

  /// No description provided for @auth_as_master.
  ///
  /// In en, this message translates to:
  /// **'Want to become a master?'**
  String get auth_as_master;

  /// No description provided for @auth_as_client.
  ///
  /// In en, this message translates to:
  /// **'As a client?'**
  String get auth_as_client;

  /// No description provided for @auth_no_account_short.
  ///
  /// In en, this message translates to:
  /// **'No account — choose your role'**
  String get auth_no_account_short;

  /// No description provided for @auth_register_pick_title.
  ///
  /// In en, this message translates to:
  /// **'Choose role'**
  String get auth_register_pick_title;

  /// No description provided for @auth_register_pick_q.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get auth_register_pick_q;

  /// No description provided for @auth_role_client_title.
  ///
  /// In en, this message translates to:
  /// **'I\'m a client'**
  String get auth_role_client_title;

  /// No description provided for @auth_role_client_desc.
  ///
  /// In en, this message translates to:
  /// **'Find a master and book a service'**
  String get auth_role_client_desc;

  /// No description provided for @auth_role_master_title.
  ///
  /// In en, this message translates to:
  /// **'I\'m a master'**
  String get auth_role_master_title;

  /// No description provided for @auth_role_master_desc.
  ///
  /// In en, this message translates to:
  /// **'Accept orders and earn'**
  String get auth_role_master_desc;

  /// No description provided for @auth_role_switch_master_q.
  ///
  /// In en, this message translates to:
  /// **'Are you a master?'**
  String get auth_role_switch_master_q;

  /// No description provided for @auth_role_switch_client_q.
  ///
  /// In en, this message translates to:
  /// **'Need a master?'**
  String get auth_role_switch_client_q;

  /// No description provided for @auth_wrong_credentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid login credentials.'**
  String get auth_wrong_credentials;

  /// No description provided for @auth_account_disabled.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deactivated.'**
  String get auth_account_disabled;

  /// No description provided for @auth_select_at_least_one.
  ///
  /// In en, this message translates to:
  /// **'Select at least one category'**
  String get auth_select_at_least_one;

  /// No description provided for @auth_error_occurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get auth_error_occurred;

  /// No description provided for @auth_forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get auth_forgot_password;

  /// No description provided for @auth_forgot_title.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get auth_forgot_title;

  /// No description provided for @auth_forgot_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone or email and we\'ll send reset instructions'**
  String get auth_forgot_subtitle;

  /// No description provided for @auth_forgot_submit.
  ///
  /// In en, this message translates to:
  /// **'Send instructions'**
  String get auth_forgot_submit;

  /// No description provided for @auth_forgot_sent.
  ///
  /// In en, this message translates to:
  /// **'If the account exists, a reset link has been sent.'**
  String get auth_forgot_sent;

  /// No description provided for @auth_back_to_login.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get auth_back_to_login;

  /// No description provided for @auth_reset_title.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get auth_reset_title;

  /// No description provided for @auth_reset_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the token from the email and your new password'**
  String get auth_reset_subtitle;

  /// No description provided for @auth_reset_token.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get auth_reset_token;

  /// No description provided for @auth_new_password.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get auth_new_password;

  /// No description provided for @auth_new_password_confirm.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get auth_new_password_confirm;

  /// No description provided for @auth_reset_submit.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get auth_reset_submit;

  /// No description provided for @auth_reset_success.
  ///
  /// In en, this message translates to:
  /// **'Password changed. You can sign in now.'**
  String get auth_reset_success;

  /// No description provided for @auth_passwords_do_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get auth_passwords_do_not_match;

  /// No description provided for @common_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get common_required;

  /// No description provided for @common_optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get common_optional;

  /// No description provided for @auth_invalid_phone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get auth_invalid_phone;

  /// No description provided for @auth_password_min.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get auth_password_min;

  /// No description provided for @auth_phone_format_hint.
  ///
  /// In en, this message translates to:
  /// **'+994501234567'**
  String get auth_phone_format_hint;

  /// No description provided for @auth_last_name_optional.
  ///
  /// In en, this message translates to:
  /// **'Last name (optional)'**
  String get auth_last_name_optional;

  /// No description provided for @auth_email_optional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get auth_email_optional;

  /// No description provided for @auth_already_have_account_signin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get auth_already_have_account_signin;

  /// No description provided for @common_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue;

  /// No description provided for @auth_master_step_1.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 3 — your details'**
  String get auth_master_step_1;

  /// No description provided for @auth_master_step_2.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 3 — where and what'**
  String get auth_master_step_2;

  /// No description provided for @auth_master_step_3.
  ///
  /// In en, this message translates to:
  /// **'Step 3 of 3 — pick at least one'**
  String get auth_master_step_3;

  /// No description provided for @auth_password_with_min.
  ///
  /// In en, this message translates to:
  /// **'Password (min 6)'**
  String get auth_password_with_min;

  /// No description provided for @auth_city_hint.
  ///
  /// In en, this message translates to:
  /// **'City (e.g. Bakı)'**
  String get auth_city_hint;

  /// No description provided for @auth_district_optional.
  ///
  /// In en, this message translates to:
  /// **'District (optional)'**
  String get auth_district_optional;

  /// No description provided for @auth_description_label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get auth_description_label;

  /// No description provided for @auth_description_min_20.
  ///
  /// In en, this message translates to:
  /// **'At least 20 characters'**
  String get auth_description_min_20;

  /// No description provided for @auth_master_pick_categories.
  ///
  /// In en, this message translates to:
  /// **'Choose categories'**
  String get auth_master_pick_categories;

  /// No description provided for @auth_failed_to_load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get auth_failed_to_load;

  /// No description provided for @auth_pick_at_least_one_category.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one category'**
  String get auth_pick_at_least_one_category;

  /// No description provided for @auth_phone_or_email_hint.
  ///
  /// In en, this message translates to:
  /// **'+994… or email'**
  String get auth_phone_or_email_hint;

  /// No description provided for @auth_resend_in_seconds.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String auth_resend_in_seconds(int seconds);

  /// No description provided for @auth_resend_code.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get auth_resend_code;

  /// No description provided for @auth_otp_dots_placeholder.
  ///
  /// In en, this message translates to:
  /// **'••••••'**
  String get auth_otp_dots_placeholder;

  /// No description provided for @auth_verify_email_title.
  ///
  /// In en, this message translates to:
  /// **'Email verification'**
  String get auth_verify_email_title;

  /// No description provided for @auth_verify_email_checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get auth_verify_email_checking;

  /// No description provided for @auth_verify_email_success.
  ///
  /// In en, this message translates to:
  /// **'Email successfully verified!'**
  String get auth_verify_email_success;

  /// No description provided for @auth_verify_email_error.
  ///
  /// In en, this message translates to:
  /// **'Token is invalid or expired.'**
  String get auth_verify_email_error;

  /// No description provided for @auth_verify_email_missing_params.
  ///
  /// In en, this message translates to:
  /// **'Missing required parameters in the link.'**
  String get auth_verify_email_missing_params;

  /// No description provided for @auth_verify_phone_title.
  ///
  /// In en, this message translates to:
  /// **'Phone verification'**
  String get auth_verify_phone_title;

  /// No description provided for @auth_verify_phone_sub.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String auth_verify_phone_sub(Object phone);

  /// No description provided for @auth_verify_phone_success.
  ///
  /// In en, this message translates to:
  /// **'Phone verified!'**
  String get auth_verify_phone_success;

  /// No description provided for @auth_otp_code.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get auth_otp_code;

  /// No description provided for @auth_verify_submit.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get auth_verify_submit;

  /// No description provided for @auth_resend_in.
  ///
  /// In en, this message translates to:
  /// **'Resend in {s}s'**
  String auth_resend_in(Object s);

  /// No description provided for @auth_invalid_code.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code'**
  String get auth_invalid_code;

  /// No description provided for @auth_master_registered_title.
  ///
  /// In en, this message translates to:
  /// **'Registration complete!'**
  String get auth_master_registered_title;

  /// No description provided for @auth_master_registered_desc.
  ///
  /// In en, this message translates to:
  /// **'Your application has been submitted. After moderation you can start accepting orders.'**
  String get auth_master_registered_desc;

  /// No description provided for @auth_go_to_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to dashboard'**
  String get auth_go_to_dashboard;

  /// No description provided for @client_hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String client_hello(Object name);

  /// No description provided for @client_what_to_do.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get client_what_to_do;

  /// No description provided for @client_create_order.
  ///
  /// In en, this message translates to:
  /// **'Create order'**
  String get client_create_order;

  /// No description provided for @client_new_order_desc.
  ///
  /// In en, this message translates to:
  /// **'Call a new master'**
  String get client_new_order_desc;

  /// No description provided for @client_my_orders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get client_my_orders;

  /// No description provided for @client_orders_desc.
  ///
  /// In en, this message translates to:
  /// **'Active and past orders'**
  String get client_orders_desc;

  /// No description provided for @client_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get client_profile;

  /// No description provided for @client_profile_desc.
  ///
  /// In en, this message translates to:
  /// **'Edit your info'**
  String get client_profile_desc;

  /// No description provided for @client_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get client_dashboard;

  /// No description provided for @client_total_orders.
  ///
  /// In en, this message translates to:
  /// **'Total orders'**
  String get client_total_orders;

  /// No description provided for @client_active_orders.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get client_active_orders;

  /// No description provided for @subscription_free_title.
  ///
  /// In en, this message translates to:
  /// **'Free launch period'**
  String get subscription_free_title;

  /// No description provided for @subscription_free_body.
  ///
  /// In en, this message translates to:
  /// **'All services free until {until}. Subscription required after that.'**
  String subscription_free_body(Object until);

  /// No description provided for @subscription_expiring_title.
  ///
  /// In en, this message translates to:
  /// **'Subscription expiring soon'**
  String get subscription_expiring_title;

  /// No description provided for @subscription_expiring_body.
  ///
  /// In en, this message translates to:
  /// **'{days} days left. Renew to keep accepting orders.'**
  String subscription_expiring_body(Object days);

  /// No description provided for @subscription_inactive_title.
  ///
  /// In en, this message translates to:
  /// **'Subscription inactive'**
  String get subscription_inactive_title;

  /// No description provided for @subscription_inactive_body.
  ///
  /// In en, this message translates to:
  /// **'Renew your subscription to accept orders.'**
  String get subscription_inactive_body;

  /// No description provided for @master_hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String master_hello(Object name);

  /// No description provided for @master_panel.
  ///
  /// In en, this message translates to:
  /// **'Master panel'**
  String get master_panel;

  /// No description provided for @master_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get master_online;

  /// No description provided for @master_offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get master_offline;

  /// No description provided for @master_rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get master_rating;

  /// No description provided for @master_orders_count.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get master_orders_count;

  /// No description provided for @master_reviews_count.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get master_reviews_count;

  /// No description provided for @master_available_orders.
  ///
  /// In en, this message translates to:
  /// **'Available orders'**
  String get master_available_orders;

  /// No description provided for @master_available_desc.
  ///
  /// In en, this message translates to:
  /// **'New orders matching your categories.'**
  String get master_available_desc;

  /// No description provided for @master_my_orders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get master_my_orders;

  /// No description provided for @master_orders_desc.
  ///
  /// In en, this message translates to:
  /// **'Active and past orders'**
  String get master_orders_desc;

  /// No description provided for @master_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get master_profile;

  /// No description provided for @master_profile_desc.
  ///
  /// In en, this message translates to:
  /// **'Profile and portfolio'**
  String get master_profile_desc;

  /// No description provided for @master_pending_requests.
  ///
  /// In en, this message translates to:
  /// **'New requests'**
  String get master_pending_requests;

  /// No description provided for @master_earnings_title.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get master_earnings_title;

  /// No description provided for @master_this_week.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get master_this_week;

  /// No description provided for @master_this_month.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get master_this_month;

  /// No description provided for @master_last_month.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get master_last_month;

  /// No description provided for @master_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get master_total;

  /// No description provided for @master_daily_chart.
  ///
  /// In en, this message translates to:
  /// **'Daily orders (30 days)'**
  String get master_daily_chart;

  /// No description provided for @master_schedule_title.
  ///
  /// In en, this message translates to:
  /// **'Work schedule'**
  String get master_schedule_title;

  /// No description provided for @master_schedule_desc.
  ///
  /// In en, this message translates to:
  /// **'Set your working days and hours'**
  String get master_schedule_desc;

  /// No description provided for @master_day_off.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get master_day_off;

  /// No description provided for @master_planner_title.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get master_planner_title;

  /// No description provided for @master_planner_desc.
  ///
  /// In en, this message translates to:
  /// **'Your accepted orders on the calendar and work schedule'**
  String get master_planner_desc;

  /// No description provided for @master_plan_active.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get master_plan_active;

  /// No description provided for @master_plan_upcoming.
  ///
  /// In en, this message translates to:
  /// **'upcoming'**
  String get master_plan_upcoming;

  /// No description provided for @master_plan_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get master_plan_today;

  /// No description provided for @master_plan_upcoming_title.
  ///
  /// In en, this message translates to:
  /// **'Upcoming visits'**
  String get master_plan_upcoming_title;

  /// No description provided for @master_plan_day_empty.
  ///
  /// In en, this message translates to:
  /// **'No orders for this day'**
  String get master_plan_day_empty;

  /// No description provided for @master_plan_status_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get master_plan_status_upcoming;

  /// No description provided for @master_plan_status_active.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get master_plan_status_active;

  /// No description provided for @master_plan_status_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get master_plan_status_done;

  /// No description provided for @master_plan_status_cancel.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get master_plan_status_cancel;

  /// No description provided for @master_accepting.
  ///
  /// In en, this message translates to:
  /// **'Accepting orders'**
  String get master_accepting;

  /// No description provided for @master_not_accepting.
  ///
  /// In en, this message translates to:
  /// **'Not accepting'**
  String get master_not_accepting;

  /// No description provided for @master_accepting_tooltip.
  ///
  /// In en, this message translates to:
  /// **'You\'re online — getting new orders. Click to go offline.'**
  String get master_accepting_tooltip;

  /// No description provided for @master_not_accepting_tooltip.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — no orders coming in. Click to start accepting.'**
  String get master_not_accepting_tooltip;

  /// No description provided for @master_not_accepting_now.
  ///
  /// In en, this message translates to:
  /// **'Master is not accepting orders now'**
  String get master_not_accepting_now;

  /// No description provided for @master_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get master_dashboard;

  /// No description provided for @master_schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get master_schedule;

  /// No description provided for @master_earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get master_earnings;

  /// No description provided for @master_my_applications.
  ///
  /// In en, this message translates to:
  /// **'My applications'**
  String get master_my_applications;

  /// No description provided for @master_find_orders.
  ///
  /// In en, this message translates to:
  /// **'Find orders'**
  String get master_find_orders;

  /// No description provided for @orders_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get orders_active;

  /// No description provided for @orders_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get orders_history;

  /// No description provided for @orders_book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get orders_book;

  /// No description provided for @orders_no_orders.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get orders_no_orders;

  /// No description provided for @orders_new_order.
  ///
  /// In en, this message translates to:
  /// **'Create new order'**
  String get orders_new_order;

  /// No description provided for @orders_master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get orders_master;

  /// No description provided for @orders_client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get orders_client;

  /// No description provided for @orders_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get orders_accept;

  /// No description provided for @orders_departed.
  ///
  /// In en, this message translates to:
  /// **'Departed'**
  String get orders_departed;

  /// No description provided for @orders_arrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get orders_arrived;

  /// No description provided for @orders_started.
  ///
  /// In en, this message translates to:
  /// **'Started work'**
  String get orders_started;

  /// No description provided for @orders_finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get orders_finished;

  /// No description provided for @orders_no_available.
  ///
  /// In en, this message translates to:
  /// **'No available orders'**
  String get orders_no_available;

  /// No description provided for @orders_will_appear.
  ///
  /// In en, this message translates to:
  /// **'New orders will appear here'**
  String get orders_will_appear;

  /// No description provided for @orders_urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get orders_urgent;

  /// No description provided for @orders_decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get orders_decline;

  /// No description provided for @orders_confirm_work.
  ///
  /// In en, this message translates to:
  /// **'Confirm work'**
  String get orders_confirm_work;

  /// No description provided for @orders_agreed_date.
  ///
  /// In en, this message translates to:
  /// **'Agreed time'**
  String get orders_agreed_date;

  /// No description provided for @orders_agreed_price.
  ///
  /// In en, this message translates to:
  /// **'Agreed price'**
  String get orders_agreed_price;

  /// No description provided for @orders_discuss.
  ///
  /// In en, this message translates to:
  /// **'Discuss'**
  String get orders_discuss;

  /// No description provided for @orders_cancel_order.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get orders_cancel_order;

  /// No description provided for @orders_cancel_reason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason?'**
  String get orders_cancel_reason;

  /// No description provided for @orders_agreed_details.
  ///
  /// In en, this message translates to:
  /// **'Agreement'**
  String get orders_agreed_details;

  /// No description provided for @orders_cancel_confirm_text.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order? This action cannot be undone.'**
  String get orders_cancel_confirm_text;

  /// No description provided for @orders_cancel_reason_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation (optional)'**
  String get orders_cancel_reason_placeholder;

  /// No description provided for @orders_cancel_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get orders_cancel_back;

  /// No description provided for @orders_cancel_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get orders_cancel_confirm;

  /// No description provided for @orders_waiting_master_title.
  ///
  /// In en, this message translates to:
  /// **'Waiting for master response'**
  String get orders_waiting_master_title;

  /// No description provided for @orders_waiting_master_desc.
  ///
  /// In en, this message translates to:
  /// **'Your request was sent to the master. They can accept or decline.'**
  String get orders_waiting_master_desc;

  /// No description provided for @orders_discussion_title.
  ///
  /// In en, this message translates to:
  /// **'Discussion in progress'**
  String get orders_discussion_title;

  /// No description provided for @orders_discussion_desc.
  ///
  /// In en, this message translates to:
  /// **'Master accepted your request. Discuss details in chat.'**
  String get orders_discussion_desc;

  /// No description provided for @orders_confirmed_title.
  ///
  /// In en, this message translates to:
  /// **'Work confirmed'**
  String get orders_confirmed_title;

  /// No description provided for @orders_confirmed_desc.
  ///
  /// In en, this message translates to:
  /// **'Time and price agreed. Master will arrive at the scheduled time.'**
  String get orders_confirmed_desc;

  /// No description provided for @orders_on_the_way_title.
  ///
  /// In en, this message translates to:
  /// **'Master is on the way'**
  String get orders_on_the_way_title;

  /// No description provided for @orders_on_the_way_desc.
  ///
  /// In en, this message translates to:
  /// **'Master is heading to your location.'**
  String get orders_on_the_way_desc;

  /// No description provided for @orders_arrived_title.
  ///
  /// In en, this message translates to:
  /// **'Master arrived'**
  String get orders_arrived_title;

  /// No description provided for @orders_arrived_desc.
  ///
  /// In en, this message translates to:
  /// **'Master is at the location.'**
  String get orders_arrived_desc;

  /// No description provided for @orders_in_progress_title.
  ///
  /// In en, this message translates to:
  /// **'Work in progress'**
  String get orders_in_progress_title;

  /// No description provided for @orders_in_progress_desc.
  ///
  /// In en, this message translates to:
  /// **'Master is currently working.'**
  String get orders_in_progress_desc;

  /// No description provided for @orders_proposal_title.
  ///
  /// In en, this message translates to:
  /// **'Master sent a proposal'**
  String get orders_proposal_title;

  /// No description provided for @orders_client_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get orders_client_accept;

  /// No description provided for @orders_client_discuss_more.
  ///
  /// In en, this message translates to:
  /// **'Discuss more'**
  String get orders_client_discuss_more;

  /// No description provided for @orders_waiting_client_title.
  ///
  /// In en, this message translates to:
  /// **'Waiting for client'**
  String get orders_waiting_client_title;

  /// No description provided for @orders_waiting_client_desc.
  ///
  /// In en, this message translates to:
  /// **'Your proposal was sent to the client. Awaiting confirmation.'**
  String get orders_waiting_client_desc;

  /// No description provided for @orders_agreed_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get orders_agreed_time;

  /// No description provided for @orders_work_duration.
  ///
  /// In en, this message translates to:
  /// **'Work duration'**
  String get orders_work_duration;

  /// No description provided for @orders_duration_desc.
  ///
  /// In en, this message translates to:
  /// **'Select estimated work duration'**
  String get orders_duration_desc;

  /// No description provided for @orders_estimated_end.
  ///
  /// In en, this message translates to:
  /// **'Estimated end'**
  String get orders_estimated_end;

  /// No description provided for @orders_work_started_msg.
  ///
  /// In en, this message translates to:
  /// **'Work started'**
  String get orders_work_started_msg;

  /// No description provided for @orders_min_short.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get orders_min_short;

  /// No description provided for @orders_hour_short.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get orders_hour_short;

  /// No description provided for @orders_confirm_completion.
  ///
  /// In en, this message translates to:
  /// **'Confirm completion'**
  String get orders_confirm_completion;

  /// No description provided for @orders_master_finished.
  ///
  /// In en, this message translates to:
  /// **'Master finished work'**
  String get orders_master_finished;

  /// No description provided for @orders_confirm_completion_desc.
  ///
  /// In en, this message translates to:
  /// **'Is the work done? Please confirm.'**
  String get orders_confirm_completion_desc;

  /// No description provided for @orders_timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get orders_timeline;

  /// No description provided for @orders_report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get orders_report;

  /// No description provided for @orders_report_reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get orders_report_reason;

  /// No description provided for @orders_report_no_show.
  ///
  /// In en, this message translates to:
  /// **'No show'**
  String get orders_report_no_show;

  /// No description provided for @orders_report_bad_quality.
  ///
  /// In en, this message translates to:
  /// **'Bad quality'**
  String get orders_report_bad_quality;

  /// No description provided for @orders_report_rude.
  ///
  /// In en, this message translates to:
  /// **'Rude behavior'**
  String get orders_report_rude;

  /// No description provided for @orders_report_price.
  ///
  /// In en, this message translates to:
  /// **'Price issue'**
  String get orders_report_price;

  /// No description provided for @orders_report_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get orders_report_other;

  /// No description provided for @orders_report_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get orders_report_details;

  /// No description provided for @orders_report_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get orders_report_submit;

  /// No description provided for @orders_report_sent.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get orders_report_sent;

  /// No description provided for @orders_repeat_order.
  ///
  /// In en, this message translates to:
  /// **'Repeat order'**
  String get orders_repeat_order;

  /// No description provided for @orders_copy_address.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get orders_copy_address;

  /// No description provided for @orders_open_maps.
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get orders_open_maps;

  /// No description provided for @orders_problem_photos.
  ///
  /// In en, this message translates to:
  /// **'Problem photos'**
  String get orders_problem_photos;

  /// No description provided for @orders_phone_hidden.
  ///
  /// In en, this message translates to:
  /// **'Phone will appear after the order is confirmed'**
  String get orders_phone_hidden;

  /// No description provided for @orders_applications_title.
  ///
  /// In en, this message translates to:
  /// **'Master applications ({n})'**
  String orders_applications_title(Object n);

  /// No description provided for @orders_applications_desc.
  ///
  /// In en, this message translates to:
  /// **'Masters have applied to your order. Pick the one you like — they\'ll connect with you via chat to discuss details.'**
  String get orders_applications_desc;

  /// No description provided for @orders_applications_desc_v2.
  ///
  /// In en, this message translates to:
  /// **'Several masters have applied. Chat with each of them — the announcement stays open until you confirm a proposal from one of them.'**
  String get orders_applications_desc_v2;

  /// No description provided for @orders_applications_empty.
  ///
  /// In en, this message translates to:
  /// **'No one has applied yet. As soon as a master applies, they\'ll appear here.'**
  String get orders_applications_empty;

  /// No description provided for @orders_apps_completed.
  ///
  /// In en, this message translates to:
  /// **'{n} completed orders'**
  String orders_apps_completed(Object n);

  /// No description provided for @orders_apps_accept.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get orders_apps_accept;

  /// No description provided for @orders_apps_accept_proposal.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get orders_apps_accept_proposal;

  /// No description provided for @orders_apps_accept_proposal_confirm.
  ///
  /// In en, this message translates to:
  /// **'Accept this proposal? Date and price will be locked, the order goes to this master, other applications will be rejected.'**
  String get orders_apps_accept_proposal_confirm;

  /// No description provided for @orders_apps_proposal_accepted_toast.
  ///
  /// In en, this message translates to:
  /// **'Proposal accepted — master selected!'**
  String get orders_apps_proposal_accepted_toast;

  /// No description provided for @orders_apps_reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get orders_apps_reject;

  /// No description provided for @orders_apps_reject_confirm.
  ///
  /// In en, this message translates to:
  /// **'Reject this application?'**
  String get orders_apps_reject_confirm;

  /// No description provided for @orders_apps_accept_confirm.
  ///
  /// In en, this message translates to:
  /// **'Pick this master? All other applications will be auto-rejected.'**
  String get orders_apps_accept_confirm;

  /// No description provided for @orders_apps_accepted_toast.
  ///
  /// In en, this message translates to:
  /// **'Master selected — you can discuss details in the chat'**
  String get orders_apps_accepted_toast;

  /// No description provided for @orders_apps_chat_locked.
  ///
  /// In en, this message translates to:
  /// **'Chat is closed at this stage.'**
  String get orders_apps_chat_locked;

  /// No description provided for @orders_apps_chat_hint.
  ///
  /// In en, this message translates to:
  /// **'Message the master, clarify details. Then they\'ll send a proposal with date and price.'**
  String get orders_apps_chat_hint;

  /// No description provided for @orders_apps_chat_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Message to master…'**
  String get orders_apps_chat_placeholder;

  /// No description provided for @orders_apps_inactive.
  ///
  /// In en, this message translates to:
  /// **'Other applications ({n})'**
  String orders_apps_inactive(Object n);

  /// No description provided for @orders_chat_proposal_label.
  ///
  /// In en, this message translates to:
  /// **'Proposal'**
  String get orders_chat_proposal_label;

  /// No description provided for @orders_chat_confirmed_label.
  ///
  /// In en, this message translates to:
  /// **'Proposal accepted'**
  String get orders_chat_confirmed_label;

  /// No description provided for @orders_chat_rejected_label.
  ///
  /// In en, this message translates to:
  /// **'Client wants to discuss again'**
  String get orders_chat_rejected_label;

  /// No description provided for @orders_app_status_pending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get orders_app_status_pending;

  /// No description provided for @orders_app_status_discussing.
  ///
  /// In en, this message translates to:
  /// **'in discussion'**
  String get orders_app_status_discussing;

  /// No description provided for @orders_app_status_proposed.
  ///
  /// In en, this message translates to:
  /// **'proposed'**
  String get orders_app_status_proposed;

  /// No description provided for @orders_app_status_accepted.
  ///
  /// In en, this message translates to:
  /// **'accepted'**
  String get orders_app_status_accepted;

  /// No description provided for @orders_app_status_rejected.
  ///
  /// In en, this message translates to:
  /// **'rejected'**
  String get orders_app_status_rejected;

  /// No description provided for @orders_app_status_withdrawn.
  ///
  /// In en, this message translates to:
  /// **'withdrawn'**
  String get orders_app_status_withdrawn;

  /// No description provided for @orders_app_status_expired.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get orders_app_status_expired;

  /// No description provided for @order_form_title.
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get order_form_title;

  /// No description provided for @order_form_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem and call a master'**
  String get order_form_subtitle;

  /// No description provided for @order_form_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get order_form_category;

  /// No description provided for @order_form_subcategory.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get order_form_subcategory;

  /// No description provided for @order_form_select.
  ///
  /// In en, this message translates to:
  /// **'Select...'**
  String get order_form_select;

  /// No description provided for @order_form_description.
  ///
  /// In en, this message translates to:
  /// **'Problem description'**
  String get order_form_description;

  /// No description provided for @order_form_description_placeholder.
  ///
  /// In en, this message translates to:
  /// **'What happened? What needs to be done?'**
  String get order_form_description_placeholder;

  /// No description provided for @order_form_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get order_form_address;

  /// No description provided for @order_form_address_placeholder.
  ///
  /// In en, this message translates to:
  /// **'City, street, building, apartment...'**
  String get order_form_address_placeholder;

  /// No description provided for @order_form_entrance.
  ///
  /// In en, this message translates to:
  /// **'Entrance/Block'**
  String get order_form_entrance;

  /// No description provided for @order_form_floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get order_form_floor;

  /// No description provided for @order_form_intercom.
  ///
  /// In en, this message translates to:
  /// **'Intercom'**
  String get order_form_intercom;

  /// No description provided for @order_form_contact_phone.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get order_form_contact_phone;

  /// No description provided for @order_form_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get order_form_time;

  /// No description provided for @order_form_asap.
  ///
  /// In en, this message translates to:
  /// **'As soon as possible'**
  String get order_form_asap;

  /// No description provided for @order_form_scheduled.
  ///
  /// In en, this message translates to:
  /// **'At a specific time'**
  String get order_form_scheduled;

  /// No description provided for @order_form_urgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get order_form_urgency;

  /// No description provided for @order_form_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get order_form_normal;

  /// No description provided for @order_form_urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get order_form_urgent;

  /// No description provided for @order_form_date_time.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get order_form_date_time;

  /// No description provided for @order_form_budget.
  ///
  /// In en, this message translates to:
  /// **'Estimated budget (AZN)'**
  String get order_form_budget;

  /// No description provided for @order_form_budget_optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get order_form_budget_optional;

  /// No description provided for @order_form_comment.
  ///
  /// In en, this message translates to:
  /// **'Additional note'**
  String get order_form_comment;

  /// No description provided for @order_form_comment_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Additional information...'**
  String get order_form_comment_placeholder;

  /// No description provided for @order_form_submit.
  ///
  /// In en, this message translates to:
  /// **'Create order'**
  String get order_form_submit;

  /// No description provided for @order_form_submitting.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get order_form_submitting;

  /// No description provided for @order_form_success.
  ///
  /// In en, this message translates to:
  /// **'Order created! Looking for a master...'**
  String get order_form_success;

  /// No description provided for @order_form_go_to_orders.
  ///
  /// In en, this message translates to:
  /// **'Go to my orders'**
  String get order_form_go_to_orders;

  /// No description provided for @order_form_photos.
  ///
  /// In en, this message translates to:
  /// **'Problem photos (max 5)'**
  String get order_form_photos;

  /// No description provided for @order_form_summary_title.
  ///
  /// In en, this message translates to:
  /// **'Booking Summary'**
  String get order_form_summary_title;

  /// No description provided for @order_form_budget_note.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get order_form_budget_note;

  /// No description provided for @order_form_agreement.
  ///
  /// In en, this message translates to:
  /// **'By booking you agree to the terms of service'**
  String get order_form_agreement;

  /// No description provided for @order_form_success_sub.
  ///
  /// In en, this message translates to:
  /// **'We are looking for a specialist. You will be notified.'**
  String get order_form_success_sub;

  /// No description provided for @order_form_category_hint.
  ///
  /// In en, this message translates to:
  /// **'Pick a service direction — this helps us match the right master.'**
  String get order_form_category_hint;

  /// No description provided for @order_form_date_time_hint.
  ///
  /// In en, this message translates to:
  /// **'When do we start? Now or pick a time.'**
  String get order_form_date_time_hint;

  /// No description provided for @order_form_address_hint.
  ///
  /// In en, this message translates to:
  /// **'Where should the master arrive?'**
  String get order_form_address_hint;

  /// No description provided for @order_form_description_hint.
  ///
  /// In en, this message translates to:
  /// **'Describe the task in detail — more details means a more accurate quote.'**
  String get order_form_description_hint;

  /// No description provided for @order_form_clear_master.
  ///
  /// In en, this message translates to:
  /// **'Remove selected master'**
  String get order_form_clear_master;

  /// No description provided for @order_form_asap_hint.
  ///
  /// In en, this message translates to:
  /// **'Within 2 hours'**
  String get order_form_asap_hint;

  /// No description provided for @order_form_scheduled_hint.
  ///
  /// In en, this message translates to:
  /// **'Pick a date and time'**
  String get order_form_scheduled_hint;

  /// No description provided for @order_form_add_photo.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get order_form_add_photo;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// No description provided for @profile_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit your personal information'**
  String get profile_subtitle;

  /// No description provided for @profile_master_title.
  ///
  /// In en, this message translates to:
  /// **'Master profile'**
  String get profile_master_title;

  /// No description provided for @profile_master_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit your profile'**
  String get profile_master_subtitle;

  /// No description provided for @profile_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get profile_saved;

  /// No description provided for @profile_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profile_save;

  /// No description provided for @profile_saving.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get profile_saving;

  /// No description provided for @profile_my_addresses.
  ///
  /// In en, this message translates to:
  /// **'My addresses'**
  String get profile_my_addresses;

  /// No description provided for @profile_no_addresses.
  ///
  /// In en, this message translates to:
  /// **'No addresses added yet'**
  String get profile_no_addresses;

  /// No description provided for @profile_stats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profile_stats;

  /// No description provided for @profile_member_since.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get profile_member_since;

  /// No description provided for @profile_change_photo.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profile_change_photo;

  /// No description provided for @profile_view_public.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get profile_view_public;

  /// No description provided for @profile_phone_locked.
  ///
  /// In en, this message translates to:
  /// **'Phone cannot be changed — used for login'**
  String get profile_phone_locked;

  /// No description provided for @profile_avatar_too_big.
  ///
  /// In en, this message translates to:
  /// **'Photo too large — max 5 MB'**
  String get profile_avatar_too_big;

  /// No description provided for @profile_avatar_updated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get profile_avatar_updated;

  /// No description provided for @profile_section_personal.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get profile_section_personal;

  /// No description provided for @profile_section_location.
  ///
  /// In en, this message translates to:
  /// **'City and district'**
  String get profile_section_location;

  /// No description provided for @profile_section_expertise.
  ///
  /// In en, this message translates to:
  /// **'About and categories'**
  String get profile_section_expertise;

  /// No description provided for @status_new.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get status_new;

  /// No description provided for @status_searching_master.
  ///
  /// In en, this message translates to:
  /// **'Searching master'**
  String get status_searching_master;

  /// No description provided for @status_accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get status_accepted;

  /// No description provided for @status_on_the_way.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get status_on_the_way;

  /// No description provided for @status_arrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get status_arrived;

  /// No description provided for @status_in_progress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get status_in_progress;

  /// No description provided for @status_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get status_completed;

  /// No description provided for @status_awaiting_review.
  ///
  /// In en, this message translates to:
  /// **'Awaiting review'**
  String get status_awaiting_review;

  /// No description provided for @status_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get status_closed;

  /// No description provided for @status_canceled_by_client.
  ///
  /// In en, this message translates to:
  /// **'Canceled by client'**
  String get status_canceled_by_client;

  /// No description provided for @status_canceled_by_master.
  ///
  /// In en, this message translates to:
  /// **'Canceled by master'**
  String get status_canceled_by_master;

  /// No description provided for @status_canceled_by_system.
  ///
  /// In en, this message translates to:
  /// **'Canceled by system'**
  String get status_canceled_by_system;

  /// No description provided for @status_pending_master.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get status_pending_master;

  /// No description provided for @status_discussion.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get status_discussion;

  /// No description provided for @status_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get status_confirmed;

  /// No description provided for @status_pending_client.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get status_pending_client;

  /// No description provided for @status_awaiting_completion.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get status_awaiting_completion;

  /// No description provided for @footer_slogan.
  ///
  /// In en, this message translates to:
  /// **'Premium on-demand home services. Verified specialists, transparent pricing.'**
  String get footer_slogan;

  /// No description provided for @footer_services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get footer_services;

  /// No description provided for @footer_company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get footer_company;

  /// No description provided for @footer_support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get footer_support;

  /// No description provided for @footer_about.
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get footer_about;

  /// No description provided for @footer_faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get footer_faq;

  /// No description provided for @footer_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get footer_privacy;

  /// No description provided for @footer_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get footer_terms;

  /// No description provided for @footer_rights.
  ///
  /// In en, this message translates to:
  /// **'All rights reserved.'**
  String get footer_rights;

  /// No description provided for @about_title.
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get about_title;

  /// No description provided for @about_p1.
  ///
  /// In en, this message translates to:
  /// **'Master is the first on-demand home services platform in Azerbaijan.'**
  String get about_p1;

  /// No description provided for @about_p2.
  ///
  /// In en, this message translates to:
  /// **'We believe that calling a master should be as easy as calling a taxi.'**
  String get about_p2;

  /// No description provided for @about_mission.
  ///
  /// In en, this message translates to:
  /// **'Our mission'**
  String get about_mission;

  /// No description provided for @about_mission_text.
  ///
  /// In en, this message translates to:
  /// **'Connecting homeowners with professional masters, creating a transparent, reliable and fast service for both sides.'**
  String get about_mission_text;

  /// No description provided for @about_values.
  ///
  /// In en, this message translates to:
  /// **'Our values'**
  String get about_values;

  /// No description provided for @contact_title.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact_title;

  /// No description provided for @contact_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get in touch with us'**
  String get contact_subtitle;

  /// No description provided for @contact_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get contact_address;

  /// No description provided for @contact_city.
  ///
  /// In en, this message translates to:
  /// **'Baku, Azerbaijan'**
  String get contact_city;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_select.
  ///
  /// In en, this message translates to:
  /// **'Select...'**
  String get common_select;

  /// No description provided for @common_address_label.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get common_address_label;

  /// No description provided for @common_from.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get common_from;

  /// No description provided for @common_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get common_skip;

  /// No description provided for @faq_title.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get faq_title;

  /// No description provided for @faq_q1.
  ///
  /// In en, this message translates to:
  /// **'Is the service paid?'**
  String get faq_q1;

  /// No description provided for @faq_a1.
  ///
  /// In en, this message translates to:
  /// **'Using the platform is free for clients. Service price is agreed with the master.'**
  String get faq_a1;

  /// No description provided for @faq_q2.
  ///
  /// In en, this message translates to:
  /// **'How is the master selected?'**
  String get faq_q2;

  /// No description provided for @faq_a2.
  ///
  /// In en, this message translates to:
  /// **'Your order is sent to the nearest suitable masters. The first to accept is yours.'**
  String get faq_a2;

  /// No description provided for @faq_q3.
  ///
  /// In en, this message translates to:
  /// **'Can I track the master?'**
  String get faq_q3;

  /// No description provided for @faq_a3.
  ///
  /// In en, this message translates to:
  /// **'Yes, after the master accepts the order you can track their real-time location on the map.'**
  String get faq_a3;

  /// No description provided for @faq_q4.
  ///
  /// In en, this message translates to:
  /// **'Can I cancel an order?'**
  String get faq_q4;

  /// No description provided for @faq_a4.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can freely cancel the order before the master arrives.'**
  String get faq_a4;

  /// No description provided for @faq_q5.
  ///
  /// In en, this message translates to:
  /// **'What do I need to become a master?'**
  String get faq_q5;

  /// No description provided for @faq_a5.
  ///
  /// In en, this message translates to:
  /// **'Register, select your specialization, provide your experience. After moderation you can accept orders.'**
  String get faq_a5;

  /// No description provided for @faq_q6.
  ///
  /// In en, this message translates to:
  /// **'How does payment work?'**
  String get faq_q6;

  /// No description provided for @faq_a6.
  ///
  /// In en, this message translates to:
  /// **'Currently payment is made directly to the master. Online payment will be added soon.'**
  String get faq_a6;

  /// No description provided for @privacy_title.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacy_title;

  /// No description provided for @privacy_updated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get privacy_updated;

  /// No description provided for @privacy_s1_title.
  ///
  /// In en, this message translates to:
  /// **'1. Data collected'**
  String get privacy_s1_title;

  /// No description provided for @privacy_s1_text.
  ///
  /// In en, this message translates to:
  /// **'During registration we collect name, phone number, email and address. For masters we additionally collect specialization, experience and certificates.'**
  String get privacy_s1_text;

  /// No description provided for @privacy_s2_title.
  ///
  /// In en, this message translates to:
  /// **'2. Use of data'**
  String get privacy_s2_title;

  /// No description provided for @privacy_s2_text.
  ///
  /// In en, this message translates to:
  /// **'Your data is used only for providing service, managing orders and improving the platform.'**
  String get privacy_s2_text;

  /// No description provided for @privacy_s3_title.
  ///
  /// In en, this message translates to:
  /// **'3. Geolocation'**
  String get privacy_s3_title;

  /// No description provided for @privacy_s3_text.
  ///
  /// In en, this message translates to:
  /// **'After a master accepts an order, location data is shared for client convenience. This only happens during an active order.'**
  String get privacy_s3_text;

  /// No description provided for @privacy_s4_title.
  ///
  /// In en, this message translates to:
  /// **'4. Data protection'**
  String get privacy_s4_title;

  /// No description provided for @privacy_s4_text.
  ///
  /// In en, this message translates to:
  /// **'All data is stored encrypted. No personal data is shared with third parties.'**
  String get privacy_s4_text;

  /// No description provided for @privacy_s5_title.
  ///
  /// In en, this message translates to:
  /// **'5. Contact'**
  String get privacy_s5_title;

  /// No description provided for @privacy_s5_text.
  ///
  /// In en, this message translates to:
  /// **'For questions: info@itez.app'**
  String get privacy_s5_text;

  /// No description provided for @terms_title.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get terms_title;

  /// No description provided for @terms_updated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get terms_updated;

  /// No description provided for @terms_s1_title.
  ///
  /// In en, this message translates to:
  /// **'1. General provisions'**
  String get terms_s1_title;

  /// No description provided for @terms_s1_text.
  ///
  /// In en, this message translates to:
  /// **'The Master platform acts as an intermediary for home master services. The platform facilitates direct relationship between master and client.'**
  String get terms_s1_text;

  /// No description provided for @terms_s2_title.
  ///
  /// In en, this message translates to:
  /// **'2. Registration'**
  String get terms_s2_title;

  /// No description provided for @terms_s2_text.
  ///
  /// In en, this message translates to:
  /// **'Users must register with correct information. Accounts with fake information will be blocked.'**
  String get terms_s2_text;

  /// No description provided for @terms_s3_title.
  ///
  /// In en, this message translates to:
  /// **'3. Orders'**
  String get terms_s3_title;

  /// No description provided for @terms_s3_text.
  ///
  /// In en, this message translates to:
  /// **'Client can cancel the order before the master arrives. After arrival, the platform may investigate the situation.'**
  String get terms_s3_text;

  /// No description provided for @terms_s4_title.
  ///
  /// In en, this message translates to:
  /// **'4. Reviews'**
  String get terms_s4_title;

  /// No description provided for @terms_s4_text.
  ///
  /// In en, this message translates to:
  /// **'Both parties must leave a review after each order. Reviews must be objective.'**
  String get terms_s4_text;

  /// No description provided for @terms_s5_title.
  ///
  /// In en, this message translates to:
  /// **'5. Liability'**
  String get terms_s5_title;

  /// No description provided for @terms_s5_text.
  ///
  /// In en, this message translates to:
  /// **'The platform is not directly responsible for service quality. In disputed cases the moderation team investigates.'**
  String get terms_s5_text;

  /// No description provided for @terms_s6_title.
  ///
  /// In en, this message translates to:
  /// **'6. Contact'**
  String get terms_s6_title;

  /// No description provided for @terms_s6_text.
  ///
  /// In en, this message translates to:
  /// **'For questions: info@itez.app'**
  String get terms_s6_text;

  /// No description provided for @masters_label.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get masters_label;

  /// No description provided for @masters_featured.
  ///
  /// In en, this message translates to:
  /// **'Top-rated masters'**
  String get masters_featured;

  /// No description provided for @masters_featured_sub.
  ///
  /// In en, this message translates to:
  /// **'Hand-picked by customer reviews and ratings'**
  String get masters_featured_sub;

  /// No description provided for @masters_see_all.
  ///
  /// In en, this message translates to:
  /// **'All masters'**
  String get masters_see_all;

  /// No description provided for @masters_reviews.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get masters_reviews;

  /// No description provided for @masters_page_title.
  ///
  /// In en, this message translates to:
  /// **'Masters'**
  String get masters_page_title;

  /// No description provided for @masters_page_subtitle.
  ///
  /// In en, this message translates to:
  /// **'All verified masters'**
  String get masters_page_subtitle;

  /// No description provided for @masters_search_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Search master...'**
  String get masters_search_placeholder;

  /// No description provided for @masters_search_label.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get masters_search_label;

  /// No description provided for @masters_filters_title.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get masters_filters_title;

  /// No description provided for @masters_clear_all.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get masters_clear_all;

  /// No description provided for @masters_service_type.
  ///
  /// In en, this message translates to:
  /// **'Service type'**
  String get masters_service_type;

  /// No description provided for @masters_availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get masters_availability;

  /// No description provided for @masters_all_specialists.
  ///
  /// In en, this message translates to:
  /// **'All specialists'**
  String get masters_all_specialists;

  /// No description provided for @masters_found_n.
  ///
  /// In en, this message translates to:
  /// **'Found {n} specialists'**
  String masters_found_n(Object n);

  /// No description provided for @masters_view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get masters_view;

  /// No description provided for @masters_all_categories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get masters_all_categories;

  /// No description provided for @masters_online_only.
  ///
  /// In en, this message translates to:
  /// **'Online only'**
  String get masters_online_only;

  /// No description provided for @masters_sort_by.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get masters_sort_by;

  /// No description provided for @masters_sort_orders.
  ///
  /// In en, this message translates to:
  /// **'By orders'**
  String get masters_sort_orders;

  /// No description provided for @masters_sort_rating.
  ///
  /// In en, this message translates to:
  /// **'By rating'**
  String get masters_sort_rating;

  /// No description provided for @masters_sort_experience.
  ///
  /// In en, this message translates to:
  /// **'By experience'**
  String get masters_sort_experience;

  /// No description provided for @masters_sort_newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get masters_sort_newest;

  /// No description provided for @masters_no_results.
  ///
  /// In en, this message translates to:
  /// **'No masters found'**
  String get masters_no_results;

  /// No description provided for @masters_experience_years.
  ///
  /// In en, this message translates to:
  /// **'years exp.'**
  String get masters_experience_years;

  /// No description provided for @masters_completed.
  ///
  /// In en, this message translates to:
  /// **'orders'**
  String get masters_completed;

  /// No description provided for @masters_verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get masters_verified;

  /// No description provided for @masters_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get masters_online;

  /// No description provided for @masters_view_profile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get masters_view_profile;

  /// No description provided for @masters_reviews_title.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get masters_reviews_title;

  /// No description provided for @masters_no_reviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get masters_no_reviews;

  /// No description provided for @masters_portfolio_title.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get masters_portfolio_title;

  /// No description provided for @masters_languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get masters_languages;

  /// No description provided for @masters_work_radius.
  ///
  /// In en, this message translates to:
  /// **'Work radius'**
  String get masters_work_radius;

  /// No description provided for @masters_urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent call'**
  String get masters_urgent;

  /// No description provided for @masters_available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get masters_available;

  /// No description provided for @masters_skills_title.
  ///
  /// In en, this message translates to:
  /// **'My skills'**
  String get masters_skills_title;

  /// No description provided for @masters_load_more.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get masters_load_more;

  /// No description provided for @masters_call_this_master.
  ///
  /// In en, this message translates to:
  /// **'Call this master'**
  String get masters_call_this_master;

  /// No description provided for @masters_currently_offline.
  ///
  /// In en, this message translates to:
  /// **'Master is currently offline'**
  String get masters_currently_offline;

  /// No description provided for @masters_reviews_short.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get masters_reviews_short;

  /// No description provided for @masters_years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get masters_years;

  /// No description provided for @masters_yr.
  ///
  /// In en, this message translates to:
  /// **'yr'**
  String get masters_yr;

  /// No description provided for @masters_rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get masters_rating;

  /// No description provided for @masters_experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get masters_experience;

  /// No description provided for @masters_radius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get masters_radius;

  /// No description provided for @masters_km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get masters_km;

  /// No description provided for @masters_sort_distance.
  ///
  /// In en, this message translates to:
  /// **'By distance'**
  String get masters_sort_distance;

  /// No description provided for @chat_title.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chat_title;

  /// No description provided for @chat_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chat_placeholder;

  /// No description provided for @chat_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chat_send;

  /// No description provided for @chat_no_messages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chat_no_messages;

  /// No description provided for @chat_load_earlier.
  ///
  /// In en, this message translates to:
  /// **'Load earlier'**
  String get chat_load_earlier;

  /// No description provided for @chat_chat_with.
  ///
  /// In en, this message translates to:
  /// **'chat with'**
  String get chat_chat_with;

  /// No description provided for @chat_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chat_you;

  /// No description provided for @chat_closed.
  ///
  /// In en, this message translates to:
  /// **'Chat closed'**
  String get chat_closed;

  /// No description provided for @chat_proposal_msg.
  ///
  /// In en, this message translates to:
  /// **'Proposal'**
  String get chat_proposal_msg;

  /// No description provided for @chat_proposal_date.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get chat_proposal_date;

  /// No description provided for @chat_proposal_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get chat_proposal_price;

  /// No description provided for @chat_confirmed_msg.
  ///
  /// In en, this message translates to:
  /// **'Confirmed!'**
  String get chat_confirmed_msg;

  /// No description provided for @chat_rejected_msg.
  ///
  /// In en, this message translates to:
  /// **'Proposal rejected. Continuing discussion.'**
  String get chat_rejected_msg;

  /// No description provided for @chat_work_started_msg.
  ///
  /// In en, this message translates to:
  /// **'Work started'**
  String get chat_work_started_msg;

  /// No description provided for @address_add.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get address_add;

  /// No description provided for @address_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get address_edit;

  /// No description provided for @address_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get address_delete;

  /// No description provided for @address_label.
  ///
  /// In en, this message translates to:
  /// **'Label (Home, Work...)'**
  String get address_label;

  /// No description provided for @address_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address_address;

  /// No description provided for @address_entrance.
  ///
  /// In en, this message translates to:
  /// **'Entrance'**
  String get address_entrance;

  /// No description provided for @address_floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get address_floor;

  /// No description provided for @address_intercom.
  ///
  /// In en, this message translates to:
  /// **'Intercom'**
  String get address_intercom;

  /// No description provided for @address_set_default.
  ///
  /// In en, this message translates to:
  /// **'Make this my default address'**
  String get address_set_default;

  /// No description provided for @address_confirm_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete this address?'**
  String get address_confirm_delete;

  /// No description provided for @address_saved.
  ///
  /// In en, this message translates to:
  /// **'Address saved'**
  String get address_saved;

  /// No description provided for @address_select_address.
  ///
  /// In en, this message translates to:
  /// **'Select address'**
  String get address_select_address;

  /// No description provided for @address_or_new.
  ///
  /// In en, this message translates to:
  /// **'or enter a new address'**
  String get address_or_new;

  /// No description provided for @address_search_map.
  ///
  /// In en, this message translates to:
  /// **'Search the map…'**
  String get address_search_map;

  /// No description provided for @address_address_manual.
  ///
  /// In en, this message translates to:
  /// **'Or enter manually'**
  String get address_address_manual;

  /// No description provided for @address_save_to_profile.
  ///
  /// In en, this message translates to:
  /// **'Save this address to my profile'**
  String get address_save_to_profile;

  /// No description provided for @address_label_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home'**
  String get address_label_hint;

  /// No description provided for @address_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get address_default;

  /// No description provided for @notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_title;

  /// No description provided for @notifications_empty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notifications_empty;

  /// No description provided for @notifications_mark_all_read.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifications_mark_all_read;

  /// No description provided for @notifications_view_all.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get notifications_view_all;

  /// No description provided for @notifications_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notifications_today;

  /// No description provided for @notifications_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notifications_yesterday;

  /// No description provided for @admin_title.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get admin_title;

  /// No description provided for @admin_subtitle.
  ///
  /// In en, this message translates to:
  /// **'System management'**
  String get admin_subtitle;

  /// No description provided for @admin_users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get admin_users;

  /// No description provided for @admin_users_desc.
  ///
  /// In en, this message translates to:
  /// **'Clients and masters'**
  String get admin_users_desc;

  /// No description provided for @admin_orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get admin_orders;

  /// No description provided for @admin_orders_desc.
  ///
  /// In en, this message translates to:
  /// **'All orders'**
  String get admin_orders_desc;

  /// No description provided for @admin_orders_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage all orders'**
  String get admin_orders_manage;

  /// No description provided for @admin_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get admin_categories;

  /// No description provided for @admin_categories_desc.
  ///
  /// In en, this message translates to:
  /// **'Service categories'**
  String get admin_categories_desc;

  /// No description provided for @admin_categories_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage service categories'**
  String get admin_categories_manage;

  /// No description provided for @admin_cat_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Category suggestions'**
  String get admin_cat_suggestions;

  /// No description provided for @admin_cat_suggestions_desc.
  ///
  /// In en, this message translates to:
  /// **'Pending requests from users to add new categories'**
  String get admin_cat_suggestions_desc;

  /// No description provided for @admin_reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get admin_reviews;

  /// No description provided for @admin_reviews_desc.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get admin_reviews_desc;

  /// No description provided for @admin_reviews_manage.
  ///
  /// In en, this message translates to:
  /// **'Review moderation'**
  String get admin_reviews_manage;

  /// No description provided for @admin_disputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get admin_disputes;

  /// No description provided for @admin_disputes_desc.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get admin_disputes_desc;

  /// No description provided for @admin_disputes_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage disputes'**
  String get admin_disputes_manage;

  /// No description provided for @admin_analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get admin_analytics;

  /// No description provided for @admin_analytics_desc.
  ///
  /// In en, this message translates to:
  /// **'Statistics and reports'**
  String get admin_analytics_desc;

  /// No description provided for @admin_all_roles.
  ///
  /// In en, this message translates to:
  /// **'All roles'**
  String get admin_all_roles;

  /// No description provided for @admin_search_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Name, phone, email...'**
  String get admin_search_placeholder;

  /// No description provided for @admin_search_btn.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get admin_search_btn;

  /// No description provided for @admin_no_users.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get admin_no_users;

  /// No description provided for @admin_no_orders.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get admin_no_orders;

  /// No description provided for @admin_no_reviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews found'**
  String get admin_no_reviews;

  /// No description provided for @admin_no_disputes.
  ///
  /// In en, this message translates to:
  /// **'No disputes found'**
  String get admin_no_disputes;

  /// No description provided for @admin_all_statuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get admin_all_statuses;

  /// No description provided for @admin_search_orders.
  ///
  /// In en, this message translates to:
  /// **'ID, name, phone...'**
  String get admin_search_orders;

  /// No description provided for @admin_th_id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get admin_th_id;

  /// No description provided for @admin_th_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get admin_th_name;

  /// No description provided for @admin_th_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get admin_th_phone;

  /// No description provided for @admin_th_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get admin_th_email;

  /// No description provided for @admin_th_role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get admin_th_role;

  /// No description provided for @admin_th_rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get admin_th_rating;

  /// No description provided for @admin_th_registered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get admin_th_registered;

  /// No description provided for @admin_th_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get admin_th_status;

  /// No description provided for @admin_th_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get admin_th_date;

  /// No description provided for @admin_th_client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get admin_th_client;

  /// No description provided for @admin_th_master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get admin_th_master;

  /// No description provided for @admin_th_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get admin_th_category;

  /// No description provided for @admin_th_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get admin_th_address;

  /// No description provided for @admin_th_order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get admin_th_order;

  /// No description provided for @admin_th_author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get admin_th_author;

  /// No description provided for @admin_th_target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get admin_th_target;

  /// No description provided for @admin_th_score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get admin_th_score;

  /// No description provided for @admin_th_text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get admin_th_text;

  /// No description provided for @admin_th_reporter.
  ///
  /// In en, this message translates to:
  /// **'Reporter'**
  String get admin_th_reporter;

  /// No description provided for @admin_th_reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get admin_th_reason;

  /// No description provided for @admin_resolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get admin_resolve;

  /// No description provided for @admin_resolve_dispute_title.
  ///
  /// In en, this message translates to:
  /// **'Resolve dispute'**
  String get admin_resolve_dispute_title;

  /// No description provided for @admin_resolve_sent.
  ///
  /// In en, this message translates to:
  /// **'Dispute resolved'**
  String get admin_resolve_sent;

  /// No description provided for @admin_resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get admin_resolution;

  /// No description provided for @admin_resolution_client_win.
  ///
  /// In en, this message translates to:
  /// **'Client is right'**
  String get admin_resolution_client_win;

  /// No description provided for @admin_resolution_master_win.
  ///
  /// In en, this message translates to:
  /// **'Master is right'**
  String get admin_resolution_master_win;

  /// No description provided for @admin_resolution_warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get admin_resolution_warning;

  /// No description provided for @admin_resolution_no_action.
  ///
  /// In en, this message translates to:
  /// **'No action'**
  String get admin_resolution_no_action;

  /// No description provided for @admin_admin_note.
  ///
  /// In en, this message translates to:
  /// **'Note (archive)'**
  String get admin_admin_note;

  /// No description provided for @admin_ban_master.
  ///
  /// In en, this message translates to:
  /// **'Ban master'**
  String get admin_ban_master;

  /// No description provided for @admin_ban_client.
  ///
  /// In en, this message translates to:
  /// **'Ban client'**
  String get admin_ban_client;

  /// No description provided for @admin_delete_review_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this review? The rating will be recalculated.'**
  String get admin_delete_review_confirm;

  /// No description provided for @admin_review_deleted.
  ///
  /// In en, this message translates to:
  /// **'Review deleted'**
  String get admin_review_deleted;

  /// No description provided for @admin_role_client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get admin_role_client;

  /// No description provided for @admin_role_master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get admin_role_master;

  /// No description provided for @admin_role_admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin_role_admin;

  /// No description provided for @admin_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get admin_active;

  /// No description provided for @admin_inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get admin_inactive;

  /// No description provided for @admin_stat_clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get admin_stat_clients;

  /// No description provided for @admin_stat_masters.
  ///
  /// In en, this message translates to:
  /// **'Masters'**
  String get admin_stat_masters;

  /// No description provided for @admin_stat_orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get admin_stat_orders;

  /// No description provided for @admin_stat_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get admin_stat_completed;

  /// No description provided for @admin_stat_canceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get admin_stat_canceled;

  /// No description provided for @admin_stat_avg_rating.
  ///
  /// In en, this message translates to:
  /// **'Avg. rating'**
  String get admin_stat_avg_rating;

  /// No description provided for @admin_th_actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get admin_th_actions;

  /// No description provided for @admin_btn_block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get admin_btn_block;

  /// No description provided for @admin_btn_unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get admin_btn_unblock;

  /// No description provided for @admin_btn_verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get admin_btn_verify;

  /// No description provided for @admin_btn_verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get admin_btn_verified;

  /// No description provided for @admin_cat_add.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get admin_cat_add;

  /// No description provided for @admin_cat_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get admin_cat_edit;

  /// No description provided for @admin_cat_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get admin_cat_delete;

  /// No description provided for @admin_cat_add_sub.
  ///
  /// In en, this message translates to:
  /// **'Add subcategory'**
  String get admin_cat_add_sub;

  /// No description provided for @admin_cat_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get admin_cat_name;

  /// No description provided for @admin_cat_slug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get admin_cat_slug;

  /// No description provided for @admin_cat_icon.
  ///
  /// In en, this message translates to:
  /// **'Icon (emoji)'**
  String get admin_cat_icon;

  /// No description provided for @admin_cat_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get admin_cat_description;

  /// No description provided for @admin_cat_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get admin_cat_save;

  /// No description provided for @admin_cat_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get admin_cat_cancel;

  /// No description provided for @admin_cat_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this category?'**
  String get admin_cat_delete_confirm;

  /// No description provided for @admin_daily_chart.
  ///
  /// In en, this message translates to:
  /// **'Orders by day (last 30 days)'**
  String get admin_daily_chart;

  /// No description provided for @admin_no_daily_data.
  ///
  /// In en, this message translates to:
  /// **'No order data for the last 30 days'**
  String get admin_no_daily_data;

  /// No description provided for @admin_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get admin_dashboard;

  /// No description provided for @time_ago_now.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get time_ago_now;

  /// No description provided for @time_ago_min.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get time_ago_min;

  /// No description provided for @time_ago_hour.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get time_ago_hour;

  /// No description provided for @time_ago_day.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get time_ago_day;

  /// No description provided for @days_0.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get days_0;

  /// No description provided for @days_1.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get days_1;

  /// No description provided for @days_2.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get days_2;

  /// No description provided for @days_3.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get days_3;

  /// No description provided for @days_4.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get days_4;

  /// No description provided for @days_5.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get days_5;

  /// No description provided for @days_6.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get days_6;

  /// No description provided for @map_title.
  ///
  /// In en, this message translates to:
  /// **'Live map'**
  String get map_title;

  /// No description provided for @map_min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get map_min;

  /// No description provided for @map_location_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get map_location_unavailable;

  /// No description provided for @map_client_location.
  ///
  /// In en, this message translates to:
  /// **'Client location'**
  String get map_client_location;

  /// No description provided for @map_master_location.
  ///
  /// In en, this message translates to:
  /// **'Master location'**
  String get map_master_location;

  /// No description provided for @review_leave_review.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get review_leave_review;

  /// No description provided for @review_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Write your review...'**
  String get review_placeholder;

  /// No description provided for @review_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get review_submit;

  /// No description provided for @review_thanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your review'**
  String get review_thanks;

  /// No description provided for @review_pending_banner.
  ///
  /// In en, this message translates to:
  /// **'Please leave a review'**
  String get review_pending_banner;

  /// No description provided for @review_add_photos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get review_add_photos;

  /// No description provided for @review_max_photos.
  ///
  /// In en, this message translates to:
  /// **'max 5'**
  String get review_max_photos;

  /// No description provided for @review_sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get review_sending;

  /// No description provided for @months_0.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get months_0;

  /// No description provided for @months_1.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get months_1;

  /// No description provided for @months_2.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get months_2;

  /// No description provided for @months_3.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get months_3;

  /// No description provided for @months_4.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get months_4;

  /// No description provided for @months_5.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get months_5;

  /// No description provided for @months_6.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get months_6;

  /// No description provided for @months_7.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get months_7;

  /// No description provided for @months_8.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get months_8;

  /// No description provided for @months_9.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get months_9;

  /// No description provided for @months_10.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get months_10;

  /// No description provided for @months_11.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get months_11;

  /// No description provided for @days_short_0.
  ///
  /// In en, this message translates to:
  /// **'Su'**
  String get days_short_0;

  /// No description provided for @days_short_1.
  ///
  /// In en, this message translates to:
  /// **'Mo'**
  String get days_short_1;

  /// No description provided for @days_short_2.
  ///
  /// In en, this message translates to:
  /// **'Tu'**
  String get days_short_2;

  /// No description provided for @days_short_3.
  ///
  /// In en, this message translates to:
  /// **'We'**
  String get days_short_3;

  /// No description provided for @days_short_4.
  ///
  /// In en, this message translates to:
  /// **'Th'**
  String get days_short_4;

  /// No description provided for @days_short_5.
  ///
  /// In en, this message translates to:
  /// **'Fr'**
  String get days_short_5;

  /// No description provided for @days_short_6.
  ///
  /// In en, this message translates to:
  /// **'Sa'**
  String get days_short_6;

  /// No description provided for @person_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get person_about;

  /// No description provided for @person_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get person_location;

  /// No description provided for @person_specialties.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get person_specialties;

  /// No description provided for @person_tab_portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get person_tab_portfolio;

  /// No description provided for @person_tab_reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get person_tab_reviews;

  /// No description provided for @person_tab_skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get person_tab_skills;

  /// No description provided for @person_project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get person_project;

  /// No description provided for @person_verified.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get person_verified;

  /// No description provided for @person_per_hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get person_per_hour;

  /// No description provided for @person_price_note.
  ///
  /// In en, this message translates to:
  /// **'Exact price after estimate · 1hr minimum'**
  String get person_price_note;

  /// No description provided for @person_available_today.
  ///
  /// In en, this message translates to:
  /// **'Available today'**
  String get person_available_today;

  /// No description provided for @person_perk_pay_after.
  ///
  /// In en, this message translates to:
  /// **'Pay only after completion'**
  String get person_perk_pay_after;

  /// No description provided for @person_perk_guarantee.
  ///
  /// In en, this message translates to:
  /// **'100% satisfaction guarantee'**
  String get person_perk_guarantee;

  /// No description provided for @person_perk_fast_response.
  ///
  /// In en, this message translates to:
  /// **'Typically responds < 15 min'**
  String get person_perk_fast_response;

  /// No description provided for @public_orders_nav_link.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get public_orders_nav_link;

  /// No description provided for @public_orders_page_title.
  ///
  /// In en, this message translates to:
  /// **'Client announcements'**
  String get public_orders_page_title;

  /// No description provided for @public_orders_page_sub.
  ///
  /// In en, this message translates to:
  /// **'{n} open requests found'**
  String public_orders_page_sub(Object n);

  /// No description provided for @public_orders_filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get public_orders_filters;

  /// No description provided for @public_orders_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get public_orders_category;

  /// No description provided for @public_orders_sort.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get public_orders_sort;

  /// No description provided for @public_orders_sort_recent.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get public_orders_sort_recent;

  /// No description provided for @public_orders_sort_distance.
  ///
  /// In en, this message translates to:
  /// **'Nearest first'**
  String get public_orders_sort_distance;

  /// No description provided for @public_orders_urgent_only.
  ///
  /// In en, this message translates to:
  /// **'Urgent only'**
  String get public_orders_urgent_only;

  /// No description provided for @public_orders_use_my_location.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get public_orders_use_my_location;

  /// No description provided for @public_orders_locating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get public_orders_locating;

  /// No description provided for @public_orders_location_set.
  ///
  /// In en, this message translates to:
  /// **'Location set'**
  String get public_orders_location_set;

  /// No description provided for @public_orders_geo_unsupported.
  ///
  /// In en, this message translates to:
  /// **'Browser does not support geolocation'**
  String get public_orders_geo_unsupported;

  /// No description provided for @public_orders_geo_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location'**
  String get public_orders_geo_failed;

  /// No description provided for @public_orders_urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get public_orders_urgent;

  /// No description provided for @public_orders_asap.
  ///
  /// In en, this message translates to:
  /// **'ASAP'**
  String get public_orders_asap;

  /// No description provided for @public_orders_asap_full.
  ///
  /// In en, this message translates to:
  /// **'As soon as possible'**
  String get public_orders_asap_full;

  /// No description provided for @public_orders_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get public_orders_details;

  /// No description provided for @public_orders_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get public_orders_apply;

  /// No description provided for @public_orders_send_application.
  ///
  /// In en, this message translates to:
  /// **'Send application'**
  String get public_orders_send_application;

  /// No description provided for @public_orders_application_sent.
  ///
  /// In en, this message translates to:
  /// **'Application sent to the client — they\'ll pick a master'**
  String get public_orders_application_sent;

  /// No description provided for @public_orders_application_sent_short.
  ///
  /// In en, this message translates to:
  /// **'Application sent'**
  String get public_orders_application_sent_short;

  /// No description provided for @public_orders_application_message_label.
  ///
  /// In en, this message translates to:
  /// **'Message to client (optional)'**
  String get public_orders_application_message_label;

  /// No description provided for @public_orders_application_message_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Briefly share your experience or ask a question'**
  String get public_orders_application_message_placeholder;

  /// No description provided for @public_orders_application_price_label.
  ///
  /// In en, this message translates to:
  /// **'Your price, AZN (optional)'**
  String get public_orders_application_price_label;

  /// No description provided for @public_orders_application_price_placeholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. 80'**
  String get public_orders_application_price_placeholder;

  /// No description provided for @public_orders_sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get public_orders_sending;

  /// No description provided for @public_orders_applied.
  ///
  /// In en, this message translates to:
  /// **'Application sent — wait for the client\'s response'**
  String get public_orders_applied;

  /// No description provided for @public_orders_only_masters.
  ///
  /// In en, this message translates to:
  /// **'Only registered masters can apply'**
  String get public_orders_only_masters;

  /// No description provided for @public_orders_only_masters_short.
  ///
  /// In en, this message translates to:
  /// **'Masters only'**
  String get public_orders_only_masters_short;

  /// No description provided for @public_orders_register_to_apply.
  ///
  /// In en, this message translates to:
  /// **'Register as master'**
  String get public_orders_register_to_apply;

  /// No description provided for @public_orders_apply_hint_guest.
  ///
  /// In en, this message translates to:
  /// **'To apply, register as a master. You will return to this announcement after registration.'**
  String get public_orders_apply_hint_guest;

  /// No description provided for @public_orders_apply_hint_client.
  ///
  /// In en, this message translates to:
  /// **'Clients cannot apply to announcements.'**
  String get public_orders_apply_hint_client;

  /// No description provided for @public_orders_apply_hint_master.
  ///
  /// In en, this message translates to:
  /// **'Your application will be sent to the client for confirmation.'**
  String get public_orders_apply_hint_master;

  /// No description provided for @public_orders_apply_hint_master_v2.
  ///
  /// In en, this message translates to:
  /// **'The client sees your application alongside others and picks the master they prefer. Once picked, a chat opens to discuss time and price.'**
  String get public_orders_apply_hint_master_v2;

  /// No description provided for @public_orders_apply_hint_applied.
  ///
  /// In en, this message translates to:
  /// **'Your application is already sent. Wait for the client\'s response — you\'ll be notified as soon as they decide. Changed your mind? You can withdraw it below.'**
  String get public_orders_apply_hint_applied;

  /// No description provided for @public_orders_load_more.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get public_orders_load_more;

  /// No description provided for @public_orders_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No open announcements yet'**
  String get public_orders_empty_title;

  /// No description provided for @public_orders_empty_desc.
  ///
  /// In en, this message translates to:
  /// **'Check back later — new requests appear all the time'**
  String get public_orders_empty_desc;

  /// No description provided for @public_orders_not_found_title.
  ///
  /// In en, this message translates to:
  /// **'Announcement not found'**
  String get public_orders_not_found_title;

  /// No description provided for @public_orders_not_found_desc.
  ///
  /// In en, this message translates to:
  /// **'The client may have already chosen a master or deleted the request'**
  String get public_orders_not_found_desc;

  /// No description provided for @public_orders_back_to_list.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get public_orders_back_to_list;

  /// No description provided for @public_orders_details_title.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get public_orders_details_title;

  /// No description provided for @public_orders_area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get public_orders_area;

  /// No description provided for @public_orders_when.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get public_orders_when;

  /// No description provided for @public_orders_budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get public_orders_budget;

  /// No description provided for @public_orders_posted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get public_orders_posted;

  /// No description provided for @public_orders_new_client.
  ///
  /// In en, this message translates to:
  /// **'New client'**
  String get public_orders_new_client;

  /// No description provided for @public_orders_just_now.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get public_orders_just_now;

  /// No description provided for @public_orders_minutes_ago.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String public_orders_minutes_ago(Object n);

  /// No description provided for @public_orders_hours_ago.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String public_orders_hours_ago(Object n);

  /// No description provided for @public_orders_days_ago.
  ///
  /// In en, this message translates to:
  /// **'{n} d ago'**
  String public_orders_days_ago(Object n);

  /// No description provided for @cat_sugg_suggest_btn.
  ///
  /// In en, this message translates to:
  /// **'Suggest category'**
  String get cat_sugg_suggest_btn;

  /// No description provided for @cat_sugg_suggest_title.
  ///
  /// In en, this message translates to:
  /// **'Suggest a new category'**
  String get cat_sugg_suggest_title;

  /// No description provided for @cat_sugg_suggest_desc.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find a fitting category? Describe it — an admin will review and add it if it fits.'**
  String get cat_sugg_suggest_desc;

  /// No description provided for @cat_sugg_field_name.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get cat_sugg_field_name;

  /// No description provided for @cat_sugg_field_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. AC repair'**
  String get cat_sugg_field_name_hint;

  /// No description provided for @cat_sugg_field_desc.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get cat_sugg_field_desc;

  /// No description provided for @cat_sugg_field_desc_hint.
  ///
  /// In en, this message translates to:
  /// **'What this service includes'**
  String get cat_sugg_field_desc_hint;

  /// No description provided for @cat_sugg_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get cat_sugg_submit;

  /// No description provided for @cat_sugg_login_required.
  ///
  /// In en, this message translates to:
  /// **'Log in to suggest a category'**
  String get cat_sugg_login_required;

  /// No description provided for @cat_sugg_submitted_title.
  ///
  /// In en, this message translates to:
  /// **'Suggestion sent'**
  String get cat_sugg_submitted_title;

  /// No description provided for @cat_sugg_submitted_desc.
  ///
  /// In en, this message translates to:
  /// **'An admin will review it. You\'ll be notified when the category is added.'**
  String get cat_sugg_submitted_desc;

  /// No description provided for @cat_sugg_submitted_toast.
  ///
  /// In en, this message translates to:
  /// **'Suggestion sent — waiting for admin approval'**
  String get cat_sugg_submitted_toast;

  /// No description provided for @cat_sugg_missing_hint.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your category?'**
  String get cat_sugg_missing_hint;

  /// No description provided for @cat_sugg_status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get cat_sugg_status_pending;

  /// No description provided for @cat_sugg_status_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get cat_sugg_status_approved;

  /// No description provided for @cat_sugg_status_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get cat_sugg_status_rejected;

  /// No description provided for @cat_sugg_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get cat_sugg_all;

  /// No description provided for @cat_sugg_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No suggestions'**
  String get cat_sugg_empty_title;

  /// No description provided for @cat_sugg_empty_desc.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review in this tab'**
  String get cat_sugg_empty_desc;

  /// No description provided for @cat_sugg_approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get cat_sugg_approve;

  /// No description provided for @cat_sugg_reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get cat_sugg_reject;

  /// No description provided for @cat_sugg_approve_title.
  ///
  /// In en, this message translates to:
  /// **'Approve suggestion'**
  String get cat_sugg_approve_title;

  /// No description provided for @cat_sugg_approve_desc.
  ///
  /// In en, this message translates to:
  /// **'Creates a new category and links it to the request.'**
  String get cat_sugg_approve_desc;

  /// No description provided for @cat_sugg_reject_title.
  ///
  /// In en, this message translates to:
  /// **'Reject suggestion'**
  String get cat_sugg_reject_title;

  /// No description provided for @cat_sugg_reject_desc.
  ///
  /// In en, this message translates to:
  /// **'The submitter will see the reason in their suggestions history.'**
  String get cat_sugg_reject_desc;

  /// No description provided for @cat_sugg_final_name.
  ///
  /// In en, this message translates to:
  /// **'Final name (editable)'**
  String get cat_sugg_final_name;

  /// No description provided for @cat_sugg_icon_name.
  ///
  /// In en, this message translates to:
  /// **'Icon (Material Symbols)'**
  String get cat_sugg_icon_name;

  /// No description provided for @cat_sugg_admin_note_optional.
  ///
  /// In en, this message translates to:
  /// **'Admin note (optional)'**
  String get cat_sugg_admin_note_optional;

  /// No description provided for @cat_sugg_reason_optional.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get cat_sugg_reason_optional;

  /// No description provided for @cat_sugg_reason_placeholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. similar category already exists'**
  String get cat_sugg_reason_placeholder;

  /// No description provided for @cat_sugg_approved_toast.
  ///
  /// In en, this message translates to:
  /// **'Category added'**
  String get cat_sugg_approved_toast;

  /// No description provided for @cat_sugg_rejected_toast.
  ///
  /// In en, this message translates to:
  /// **'Suggestion rejected'**
  String get cat_sugg_rejected_toast;

  /// No description provided for @cat_sugg_reviewed_by.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by {name} · {when}'**
  String cat_sugg_reviewed_by(Object name, Object when);

  /// No description provided for @apps_tab_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get apps_tab_pending;

  /// No description provided for @apps_tab_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get apps_tab_active;

  /// No description provided for @apps_tab_accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get apps_tab_accepted;

  /// No description provided for @apps_tab_rejected.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get apps_tab_rejected;

  /// No description provided for @apps_tab_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get apps_tab_all;

  /// No description provided for @apps_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No applications yet'**
  String get apps_empty_title;

  /// No description provided for @apps_empty_desc.
  ///
  /// In en, this message translates to:
  /// **'Apply to client announcements — your applications will appear here'**
  String get apps_empty_desc;

  /// No description provided for @apps_find_orders.
  ///
  /// In en, this message translates to:
  /// **'Browse announcements'**
  String get apps_find_orders;

  /// No description provided for @apps_open_chat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get apps_open_chat;

  /// No description provided for @apps_open_chat_with_client.
  ///
  /// In en, this message translates to:
  /// **'Chat with client'**
  String get apps_open_chat_with_client;

  /// No description provided for @apps_open_order.
  ///
  /// In en, this message translates to:
  /// **'Open order'**
  String get apps_open_order;

  /// No description provided for @apps_view_order.
  ///
  /// In en, this message translates to:
  /// **'View order'**
  String get apps_view_order;

  /// No description provided for @apps_current_proposal.
  ///
  /// In en, this message translates to:
  /// **'Current proposal'**
  String get apps_current_proposal;

  /// No description provided for @apps_chat_hint_master.
  ///
  /// In en, this message translates to:
  /// **'Discuss details with the client. When ready, click the document icon and send a formal proposal with date and price.'**
  String get apps_chat_hint_master;

  /// No description provided for @apps_chat_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Message to client…'**
  String get apps_chat_placeholder;

  /// No description provided for @apps_propose_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get apps_propose_date;

  /// No description provided for @apps_propose_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get apps_propose_time;

  /// No description provided for @apps_propose_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get apps_propose_price;

  /// No description provided for @apps_send_proposal.
  ///
  /// In en, this message translates to:
  /// **'Send proposal'**
  String get apps_send_proposal;

  /// No description provided for @apps_proposal_sent.
  ///
  /// In en, this message translates to:
  /// **'Proposal sent — the client sees it in the chat'**
  String get apps_proposal_sent;

  /// No description provided for @apps_withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get apps_withdraw;

  /// No description provided for @apps_withdraw_confirm.
  ///
  /// In en, this message translates to:
  /// **'The client will see that you have left this order. This action cannot be undone.'**
  String get apps_withdraw_confirm;

  /// No description provided for @apps_withdrawn_toast.
  ///
  /// In en, this message translates to:
  /// **'Application withdrawn'**
  String get apps_withdrawn_toast;

  /// No description provided for @nav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// No description provided for @common_data.
  ///
  /// In en, this message translates to:
  /// **'data'**
  String get common_data;

  /// No description provided for @common_legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get common_legal;

  /// No description provided for @common_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get common_about;

  /// No description provided for @common_version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get common_version;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get common_send;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// No description provided for @common_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get common_failed;

  /// No description provided for @common_view_all.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get common_view_all;

  /// No description provided for @common_see_all.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get common_see_all;

  /// No description provided for @auth_logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get auth_logout;

  /// No description provided for @auth_welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get auth_welcome_back;

  /// No description provided for @auth_sign_in_to_continue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get auth_sign_in_to_continue;

  /// No description provided for @auth_min6.
  ///
  /// In en, this message translates to:
  /// **'Min 6 chars'**
  String get auth_min6;

  /// No description provided for @auth_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get auth_required;

  /// No description provided for @auth_create_account.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get auth_create_account;

  /// No description provided for @auth_choose_role.
  ///
  /// In en, this message translates to:
  /// **'Choose role'**
  String get auth_choose_role;

  /// No description provided for @auth_who_are_you.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get auth_who_are_you;

  /// No description provided for @auth_im_client.
  ///
  /// In en, this message translates to:
  /// **'I’m a client (need a service)'**
  String get auth_im_client;

  /// No description provided for @auth_im_master.
  ///
  /// In en, this message translates to:
  /// **'I’m a master (provide services)'**
  String get auth_im_master;

  /// No description provided for @auth_back_to_login_btn.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get auth_back_to_login_btn;

  /// No description provided for @auth_sign_up_to_book.
  ///
  /// In en, this message translates to:
  /// **'Sign up to book home services'**
  String get auth_sign_up_to_book;

  /// No description provided for @auth_step_details.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 3 — your details'**
  String get auth_step_details;

  /// No description provided for @auth_step_where.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 3 — where and what'**
  String get auth_step_where;

  /// No description provided for @auth_step_categories.
  ///
  /// In en, this message translates to:
  /// **'Step 3 of 3 — pick at least one'**
  String get auth_step_categories;

  /// No description provided for @auth_first_name_hint.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get auth_first_name_hint;

  /// No description provided for @auth_last_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get auth_last_name_hint;

  /// No description provided for @auth_phone_hint.
  ///
  /// In en, this message translates to:
  /// **'+994...'**
  String get auth_phone_hint;

  /// No description provided for @auth_email_hint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get auth_email_hint;

  /// No description provided for @auth_pick_category.
  ///
  /// In en, this message translates to:
  /// **'Pick a category to start'**
  String get auth_pick_category;

  /// No description provided for @auth_choose_categories.
  ///
  /// In en, this message translates to:
  /// **'Choose categories'**
  String get auth_choose_categories;

  /// No description provided for @auth_about_you_label.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get auth_about_you_label;

  /// No description provided for @auth_about_placeholder_long.
  ///
  /// In en, this message translates to:
  /// **'Tell about your experience and specialization...'**
  String get auth_about_placeholder_long;

  /// No description provided for @auth_already_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get auth_already_have_account;

  /// No description provided for @auth_verify_phone.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone'**
  String get auth_verify_phone;

  /// No description provided for @auth_we_sent_code.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}'**
  String auth_we_sent_code(Object phone);

  /// No description provided for @auth_use_token_from_email.
  ///
  /// In en, this message translates to:
  /// **'Use the token from your email or SMS'**
  String get auth_use_token_from_email;

  /// No description provided for @auth_password_reset_done.
  ///
  /// In en, this message translates to:
  /// **'Password reset. You can sign in now.'**
  String get auth_password_reset_done;

  /// No description provided for @auth_send_reset_link.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get auth_send_reset_link;

  /// No description provided for @auth_skip_for_now.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get auth_skip_for_now;

  /// No description provided for @auth_verify_btn.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get auth_verify_btn;

  /// No description provided for @auth_new_password_short.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get auth_new_password_short;

  /// No description provided for @home_welcome.
  ///
  /// In en, this message translates to:
  /// **'WELCOME'**
  String get home_welcome;

  /// No description provided for @home_welcome_back_label.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get home_welcome_back_label;

  /// No description provided for @home_sign_in_register.
  ///
  /// In en, this message translates to:
  /// **'Sign in / Register'**
  String get home_sign_in_register;

  /// No description provided for @home_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search for services (e.g. Electrician)'**
  String get home_search_hint;

  /// No description provided for @home_service_categories.
  ///
  /// In en, this message translates to:
  /// **'Service Categories'**
  String get home_service_categories;

  /// No description provided for @home_recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get home_recommended;

  /// No description provided for @home_limited_offer.
  ///
  /// In en, this message translates to:
  /// **'LIMITED OFFER'**
  String get home_limited_offer;

  /// No description provided for @home_book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get home_book;

  /// No description provided for @home_hi_name.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String home_hi_name(String name);

  /// No description provided for @home_banner1_title.
  ///
  /// In en, this message translates to:
  /// **'20% Off Your\nFirst Booking'**
  String get home_banner1_title;

  /// No description provided for @home_banner1_sub.
  ///
  /// In en, this message translates to:
  /// **'Valid for Electrician services\ntoday only.'**
  String get home_banner1_sub;

  /// No description provided for @home_banner1_cta.
  ///
  /// In en, this message translates to:
  /// **'Claim Now'**
  String get home_banner1_cta;

  /// No description provided for @home_banner2_title.
  ///
  /// In en, this message translates to:
  /// **'Refer a Friend\nGet \$25 Credit'**
  String get home_banner2_title;

  /// No description provided for @home_banner2_sub.
  ///
  /// In en, this message translates to:
  /// **'Share Master.az with anyone\nand both earn rewards.'**
  String get home_banner2_sub;

  /// No description provided for @home_banner2_cta.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get home_banner2_cta;

  /// No description provided for @home_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get home_loading;

  /// No description provided for @home_load_error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load. Tap to retry.'**
  String get home_load_error;

  /// No description provided for @cat_santexnik.
  ///
  /// In en, this message translates to:
  /// **'Plumber'**
  String get cat_santexnik;

  /// No description provided for @cat_elektrik.
  ///
  /// In en, this message translates to:
  /// **'Electrician'**
  String get cat_elektrik;

  /// No description provided for @cat_qaynaqci.
  ///
  /// In en, this message translates to:
  /// **'Welder'**
  String get cat_qaynaqci;

  /// No description provided for @cat_usta_saati.
  ///
  /// In en, this message translates to:
  /// **'Handyman'**
  String get cat_usta_saati;

  /// No description provided for @cat_mebel_yigimi.
  ///
  /// In en, this message translates to:
  /// **'Furniture assembly'**
  String get cat_mebel_yigimi;

  /// No description provided for @cat_rengleme.
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get cat_rengleme;

  /// No description provided for @cat_kondisioner.
  ///
  /// In en, this message translates to:
  /// **'AC service'**
  String get cat_kondisioner;

  /// No description provided for @cat_cilinger.
  ///
  /// In en, this message translates to:
  /// **'Locksmith'**
  String get cat_cilinger;

  /// No description provided for @cat_all_categories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get cat_all_categories;

  /// No description provided for @cat_n_masters.
  ///
  /// In en, this message translates to:
  /// **'{n} masters'**
  String cat_n_masters(int n);

  /// No description provided for @tab_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tab_home;

  /// No description provided for @tab_bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get tab_bookings;

  /// No description provided for @tab_chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tab_chat;

  /// No description provided for @tab_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tab_search;

  /// No description provided for @tab_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tab_profile;

  /// No description provided for @order_my_orders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get order_my_orders;

  /// No description provided for @order_create_title.
  ///
  /// In en, this message translates to:
  /// **'Create order'**
  String get order_create_title;

  /// No description provided for @order_what_service.
  ///
  /// In en, this message translates to:
  /// **'What service do you need?'**
  String get order_what_service;

  /// No description provided for @order_describe_job.
  ///
  /// In en, this message translates to:
  /// **'Describe the job'**
  String get order_describe_job;

  /// No description provided for @order_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get order_description;

  /// No description provided for @order_min10.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters. The clearer, the more masters apply.'**
  String get order_min10;

  /// No description provided for @order_where.
  ///
  /// In en, this message translates to:
  /// **'Where?'**
  String get order_where;

  /// No description provided for @order_address_visible.
  ///
  /// In en, this message translates to:
  /// **'Address shown to the master only after they accept the order.'**
  String get order_address_visible;

  /// No description provided for @order_waiting_masters.
  ///
  /// In en, this message translates to:
  /// **'Waiting for masters to apply...'**
  String get order_waiting_masters;

  /// No description provided for @order_master_applications.
  ///
  /// In en, this message translates to:
  /// **'Master applications'**
  String get order_master_applications;

  /// No description provided for @order_proposal_accepted.
  ///
  /// In en, this message translates to:
  /// **'Proposal accepted'**
  String get order_proposal_accepted;

  /// No description provided for @order_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get order_cancel;

  /// No description provided for @order_cancel_confirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get order_cancel_confirm;

  /// No description provided for @order_keep_it.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get order_keep_it;

  /// No description provided for @order_leave_review.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get order_leave_review;

  /// No description provided for @chat_filter_warn.
  ///
  /// In en, this message translates to:
  /// **'Phone numbers and emails are masked'**
  String get chat_filter_warn;

  /// No description provided for @chat_send_btn.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chat_send_btn;

  /// No description provided for @chat_message_hint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get chat_message_hint;

  /// No description provided for @chat_master_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get chat_master_online;

  /// No description provided for @notif_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notif_title;

  /// No description provided for @notif_mark_all_read.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notif_mark_all_read;

  /// No description provided for @notif_empty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notif_empty;

  /// No description provided for @profile_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profile_edit;

  /// No description provided for @profile_premium.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM MEMBER'**
  String get profile_premium;

  /// No description provided for @profile_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get profile_privacy;

  /// No description provided for @profile_export.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get profile_export;

  /// No description provided for @profile_export_sub.
  ///
  /// In en, this message translates to:
  /// **'Download all your personal data as JSON'**
  String get profile_export_sub;

  /// No description provided for @profile_export_done.
  ///
  /// In en, this message translates to:
  /// **'Data fetched. Save it from the system menu.'**
  String get profile_export_done;

  /// No description provided for @profile_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profile_delete;

  /// No description provided for @profile_delete_sub.
  ///
  /// In en, this message translates to:
  /// **'Anonymizes your profile permanently'**
  String get profile_delete_sub;

  /// No description provided for @profile_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get profile_delete_confirm_title;

  /// No description provided for @profile_delete_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'Your profile will be anonymized. Active orders block deletion.'**
  String get profile_delete_confirm_body;

  /// No description provided for @profile_master_electrician.
  ///
  /// In en, this message translates to:
  /// **'Master Electrician'**
  String get profile_master_electrician;

  /// No description provided for @master_book_appointment.
  ///
  /// In en, this message translates to:
  /// **'Order this master'**
  String get master_book_appointment;

  /// No description provided for @master_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get master_about;

  /// No description provided for @master_reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get master_reviews;

  /// No description provided for @master_services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get master_services;

  /// No description provided for @master_no_reviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get master_no_reviews;

  /// No description provided for @list_per_hour.
  ///
  /// In en, this message translates to:
  /// **'/hr'**
  String get list_per_hour;

  /// No description provided for @list_years_exp.
  ///
  /// In en, this message translates to:
  /// **'yrs exp.'**
  String get list_years_exp;

  /// No description provided for @list_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or service...'**
  String get list_search_hint;

  /// No description provided for @list_book_appointment.
  ///
  /// In en, this message translates to:
  /// **'Book appointment'**
  String get list_book_appointment;

  /// No description provided for @list_available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get list_available;

  /// No description provided for @list_busy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get list_busy;

  /// No description provided for @list_no_results.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get list_no_results;

  /// No description provided for @list_reviews_n.
  ///
  /// In en, this message translates to:
  /// **'({n} reviews)'**
  String list_reviews_n(int n);

  /// No description provided for @common_user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get common_user;

  /// No description provided for @common_years_short.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get common_years_short;

  /// No description provided for @common_orders_short.
  ///
  /// In en, this message translates to:
  /// **'orders'**
  String get common_orders_short;

  /// No description provided for @common_reviews_short.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get common_reviews_short;

  /// No description provided for @order_create_step1_q.
  ///
  /// In en, this message translates to:
  /// **'What service do you need?'**
  String get order_create_step1_q;

  /// No description provided for @order_create_step1_sub.
  ///
  /// In en, this message translates to:
  /// **'Pick a category to start'**
  String get order_create_step1_sub;

  /// No description provided for @order_create_step2_title.
  ///
  /// In en, this message translates to:
  /// **'Describe the job'**
  String get order_create_step2_title;

  /// No description provided for @order_create_step2_sub.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters. The clearer, the more masters apply.'**
  String get order_create_step2_sub;

  /// No description provided for @order_create_desc_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Living-room light flickers, need a quick fix...'**
  String get order_create_desc_hint;

  /// No description provided for @order_create_budget_hint.
  ///
  /// In en, this message translates to:
  /// **'Estimated budget (AZN, optional)'**
  String get order_create_budget_hint;

  /// No description provided for @order_create_step3_title.
  ///
  /// In en, this message translates to:
  /// **'Where?'**
  String get order_create_step3_title;

  /// No description provided for @order_create_step3_sub.
  ///
  /// In en, this message translates to:
  /// **'Address is shown to the master only after they accept the order'**
  String get order_create_step3_sub;

  /// No description provided for @order_create_address_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Baku, Yasamal, Ataturk ave. 12, apt 45'**
  String get order_create_address_hint;

  /// No description provided for @order_create_submit.
  ///
  /// In en, this message translates to:
  /// **'Create order'**
  String get order_create_submit;

  /// No description provided for @my_orders_title.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get my_orders_title;

  /// No description provided for @my_orders_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get my_orders_filter_all;

  /// No description provided for @my_orders_filter_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get my_orders_filter_active;

  /// No description provided for @my_orders_filter_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get my_orders_filter_completed;

  /// No description provided for @my_orders_filter_canceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get my_orders_filter_canceled;

  /// No description provided for @my_orders_empty_master.
  ///
  /// In en, this message translates to:
  /// **'No active assignments yet'**
  String get my_orders_empty_master;

  /// No description provided for @my_orders_empty_client.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any orders yet'**
  String get my_orders_empty_client;

  /// No description provided for @order_status_searching.
  ///
  /// In en, this message translates to:
  /// **'SEARCHING'**
  String get order_status_searching;

  /// No description provided for @order_status_in_discussion.
  ///
  /// In en, this message translates to:
  /// **'IN DISCUSSION'**
  String get order_status_in_discussion;

  /// No description provided for @order_status_confirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get order_status_confirmed;

  /// No description provided for @order_status_on_the_way.
  ///
  /// In en, this message translates to:
  /// **'ON THE WAY'**
  String get order_status_on_the_way;

  /// No description provided for @order_status_arrived.
  ///
  /// In en, this message translates to:
  /// **'ARRIVED'**
  String get order_status_arrived;

  /// No description provided for @order_status_in_progress.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get order_status_in_progress;

  /// No description provided for @order_status_awaiting.
  ///
  /// In en, this message translates to:
  /// **'AWAITING CONFIRMATION'**
  String get order_status_awaiting;

  /// No description provided for @order_status_awaiting_short.
  ///
  /// In en, this message translates to:
  /// **'AWAITING'**
  String get order_status_awaiting_short;

  /// No description provided for @order_status_completed.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get order_status_completed;

  /// No description provided for @order_status_canceled.
  ///
  /// In en, this message translates to:
  /// **'CANCELED'**
  String get order_status_canceled;

  /// No description provided for @order_status_disputed.
  ///
  /// In en, this message translates to:
  /// **'DISPUTED'**
  String get order_status_disputed;

  /// No description provided for @order_status_draft.
  ///
  /// In en, this message translates to:
  /// **'DRAFT'**
  String get order_status_draft;

  /// No description provided for @app_status_applied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get app_status_applied;

  /// No description provided for @app_status_discussing.
  ///
  /// In en, this message translates to:
  /// **'Discussing'**
  String get app_status_discussing;

  /// No description provided for @app_status_proposed.
  ///
  /// In en, this message translates to:
  /// **'Proposed'**
  String get app_status_proposed;

  /// No description provided for @app_status_accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get app_status_accepted;

  /// No description provided for @app_status_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get app_status_rejected;

  /// No description provided for @app_status_withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get app_status_withdrawn;

  /// No description provided for @order_action_on_the_way.
  ///
  /// In en, this message translates to:
  /// **'I\'m on the way'**
  String get order_action_on_the_way;

  /// No description provided for @order_action_arrived.
  ///
  /// In en, this message translates to:
  /// **'I\'ve arrived'**
  String get order_action_arrived;

  /// No description provided for @order_action_start_work.
  ///
  /// In en, this message translates to:
  /// **'Start work'**
  String get order_action_start_work;

  /// No description provided for @order_action_mark_complete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get order_action_mark_complete;

  /// No description provided for @order_chat_btn.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get order_chat_btn;

  /// No description provided for @order_accept_btn.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get order_accept_btn;

  /// No description provided for @order_kv_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get order_kv_address;

  /// No description provided for @order_kv_budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get order_kv_budget;

  /// No description provided for @order_kv_agreed_price.
  ///
  /// In en, this message translates to:
  /// **'Agreed price'**
  String get order_kv_agreed_price;

  /// No description provided for @order_kv_agreed_date.
  ///
  /// In en, this message translates to:
  /// **'Agreed date'**
  String get order_kv_agreed_date;

  /// No description provided for @order_applications_title.
  ///
  /// In en, this message translates to:
  /// **'Master applications'**
  String get order_applications_title;

  /// No description provided for @order_applications_waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for masters to apply...'**
  String get order_applications_waiting;

  /// No description provided for @order_cancel_btn.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get order_cancel_btn;

  /// No description provided for @order_cancel_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get order_cancel_confirm_title;

  /// No description provided for @order_cancel_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'You can\'t undo this.'**
  String get order_cancel_confirm_body;

  /// No description provided for @order_cancel_keep.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get order_cancel_keep;

  /// No description provided for @order_service_fallback.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get order_service_fallback;

  /// No description provided for @order_request_fallback.
  ///
  /// In en, this message translates to:
  /// **'Service request'**
  String get order_request_fallback;

  /// No description provided for @order_master_fallback.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get order_master_fallback;

  /// No description provided for @chat_day_today.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get chat_day_today;

  /// No description provided for @chat_user_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get chat_user_online;

  /// No description provided for @chat_select_conversation.
  ///
  /// In en, this message translates to:
  /// **'Open a chat from a specific application or order to start messaging'**
  String get chat_select_conversation;

  /// No description provided for @profile_edit_btn.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profile_edit_btn;

  /// No description provided for @profile_section_account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get profile_section_account;

  /// No description provided for @profile_section_preferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get profile_section_preferences;

  /// No description provided for @profile_payment_methods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get profile_payment_methods;

  /// No description provided for @profile_push_notifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get profile_push_notifications;

  /// No description provided for @profile_privacy_security.
  ///
  /// In en, this message translates to:
  /// **'Privacy & security'**
  String get profile_privacy_security;

  /// No description provided for @profile_premium_member.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM MEMBER'**
  String get profile_premium_member;

  /// No description provided for @profile_copyright.
  ///
  /// In en, this message translates to:
  /// **'© Master.az — All rights reserved'**
  String get profile_copyright;

  /// No description provided for @profile_sign_out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profile_sign_out;

  /// No description provided for @tab_announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get tab_announcements;

  /// No description provided for @ann_title.
  ///
  /// In en, this message translates to:
  /// **'Public orders'**
  String get ann_title;

  /// No description provided for @ann_subtitle_n.
  ///
  /// In en, this message translates to:
  /// **'{n} active'**
  String ann_subtitle_n(int n);

  /// No description provided for @ann_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No public orders right now'**
  String get ann_empty_title;

  /// No description provided for @ann_empty_desc.
  ///
  /// In en, this message translates to:
  /// **'Come back later — clients post new requests every day.'**
  String get ann_empty_desc;

  /// No description provided for @ann_urgent.
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get ann_urgent;

  /// No description provided for @ann_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ann_filter_all;

  /// No description provided for @ann_filter_urgent_only.
  ///
  /// In en, this message translates to:
  /// **'Urgent only'**
  String get ann_filter_urgent_only;

  /// No description provided for @ann_details_btn.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get ann_details_btn;

  /// No description provided for @smart_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue or attach a photo — AI will pick the right master'**
  String get smart_placeholder;

  /// No description provided for @smart_attach_photo.
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get smart_attach_photo;

  /// No description provided for @smart_photo_attached.
  ///
  /// In en, this message translates to:
  /// **'Photo attached'**
  String get smart_photo_attached;

  /// No description provided for @smart_remove_photo.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get smart_remove_photo;

  /// No description provided for @smart_use_location.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get smart_use_location;

  /// No description provided for @smart_detecting_geo.
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get smart_detecting_geo;

  /// No description provided for @smart_geo_ready.
  ///
  /// In en, this message translates to:
  /// **'Location set'**
  String get smart_geo_ready;

  /// No description provided for @smart_geo_denied.
  ///
  /// In en, this message translates to:
  /// **'Location access denied'**
  String get smart_geo_denied;

  /// No description provided for @smart_geo_unsupported.
  ///
  /// In en, this message translates to:
  /// **'Geolocation is not supported here'**
  String get smart_geo_unsupported;

  /// No description provided for @smart_find.
  ///
  /// In en, this message translates to:
  /// **'Find a master'**
  String get smart_find;

  /// No description provided for @smart_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analysing...'**
  String get smart_analyzing;

  /// No description provided for @smart_error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t analyse — try again'**
  String get smart_error;

  /// No description provided for @smart_no_match.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t pick a category. Browse all categories?'**
  String get smart_no_match;

  /// No description provided for @address_label_caps.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS'**
  String get address_label_caps;

  /// No description provided for @address_pick_title.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get address_pick_title;

  /// No description provided for @address_add_new.
  ///
  /// In en, this message translates to:
  /// **'+ Add a new address'**
  String get address_add_new;

  /// No description provided for @address_no_addresses.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet.'**
  String get address_no_addresses;

  /// No description provided for @address_label_field.
  ///
  /// In en, this message translates to:
  /// **'Label (Home, Work)'**
  String get address_label_field;

  /// No description provided for @address_full_field.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address_full_field;

  /// No description provided for @address_full_required.
  ///
  /// In en, this message translates to:
  /// **'Enter the address'**
  String get address_full_required;

  /// No description provided for @address_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get address_save;

  /// No description provided for @address_default_badge.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get address_default_badge;

  /// No description provided for @address_tap_to_pick.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to pick an address'**
  String get address_tap_to_pick;

  /// No description provided for @address_note_for_master.
  ///
  /// In en, this message translates to:
  /// **'Note for the master'**
  String get address_note_for_master;

  /// No description provided for @address_note_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. gate code 1234, second door on the left, ring twice'**
  String get address_note_hint;

  /// No description provided for @notif_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'When something happens, it\'ll show up here.'**
  String get notif_empty_subtitle;

  /// No description provided for @notif_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get notif_retry;

  /// No description provided for @notif_group_today.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get notif_group_today;

  /// No description provided for @notif_group_yesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get notif_group_yesterday;

  /// No description provided for @notif_group_this_week.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get notif_group_this_week;

  /// No description provided for @notif_group_older.
  ///
  /// In en, this message translates to:
  /// **'EARLIER'**
  String get notif_group_older;

  /// No description provided for @notif_now.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get notif_now;

  /// No description provided for @notif_min_ago.
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String notif_min_ago(int n);

  /// No description provided for @notif_hour_ago.
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String notif_hour_ago(int n);

  /// No description provided for @notif_day_ago.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String notif_day_ago(int n);

  /// No description provided for @my_orders_empty_history.
  ///
  /// In en, this message translates to:
  /// **'No completed orders yet.'**
  String get my_orders_empty_history;

  /// No description provided for @order_photos_label.
  ///
  /// In en, this message translates to:
  /// **'PROBLEM PHOTOS'**
  String get order_photos_label;

  /// No description provided for @order_address_copied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get order_address_copied;

  /// No description provided for @order_canceled.
  ///
  /// In en, this message translates to:
  /// **'Order canceled'**
  String get order_canceled;

  /// No description provided for @order_cancel_reason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get order_cancel_reason;

  /// No description provided for @order_cancel_reason_hint.
  ///
  /// In en, this message translates to:
  /// **'Why are you canceling?'**
  String get order_cancel_reason_hint;

  /// No description provided for @order_kv_scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for'**
  String get order_kv_scheduled;

  /// No description provided for @order_kv_comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get order_kv_comment;

  /// No description provided for @order_kv_master.
  ///
  /// In en, this message translates to:
  /// **'MASTER'**
  String get order_kv_master;

  /// No description provided for @order_kv_client.
  ///
  /// In en, this message translates to:
  /// **'CLIENT'**
  String get order_kv_client;

  /// No description provided for @order_timeline_title.
  ///
  /// In en, this message translates to:
  /// **'Status history'**
  String get order_timeline_title;

  /// No description provided for @order_banner_searching.
  ///
  /// In en, this message translates to:
  /// **'Looking for a master. First offers will arrive shortly.'**
  String get order_banner_searching;

  /// No description provided for @order_banner_pending_master_client.
  ///
  /// In en, this message translates to:
  /// **'A master is reviewing your order. Awaiting their reply.'**
  String get order_banner_pending_master_client;

  /// No description provided for @order_banner_pending_master_master.
  ///
  /// In en, this message translates to:
  /// **'This order was offered to you — accept or decline.'**
  String get order_banner_pending_master_master;

  /// No description provided for @order_banner_discussion.
  ///
  /// In en, this message translates to:
  /// **'Details under discussion. Sort everything in chat before confirming.'**
  String get order_banner_discussion;

  /// No description provided for @order_banner_pending_client_client.
  ///
  /// In en, this message translates to:
  /// **'The master sent a proposal — accept or decline.'**
  String get order_banner_pending_client_client;

  /// No description provided for @order_banner_pending_client_master.
  ///
  /// In en, this message translates to:
  /// **'Awaiting the client\'s response to the proposal.'**
  String get order_banner_pending_client_master;

  /// No description provided for @order_banner_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Order confirmed. Visit time is approaching.'**
  String get order_banner_confirmed;

  /// No description provided for @order_banner_on_the_way_client.
  ///
  /// In en, this message translates to:
  /// **'The master is on the way to you.'**
  String get order_banner_on_the_way_client;

  /// No description provided for @order_banner_on_the_way_master.
  ///
  /// In en, this message translates to:
  /// **'You\'re heading to the client.'**
  String get order_banner_on_the_way_master;

  /// No description provided for @order_banner_arrived.
  ///
  /// In en, this message translates to:
  /// **'The master has arrived.'**
  String get order_banner_arrived;

  /// No description provided for @order_banner_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Work in progress.'**
  String get order_banner_in_progress;

  /// No description provided for @order_banner_awaiting_completion_client.
  ///
  /// In en, this message translates to:
  /// **'Work is done — please confirm.'**
  String get order_banner_awaiting_completion_client;

  /// No description provided for @order_banner_awaiting_completion_master.
  ///
  /// In en, this message translates to:
  /// **'Awaiting the client\'s confirmation.'**
  String get order_banner_awaiting_completion_master;

  /// No description provided for @order_banner_completed.
  ///
  /// In en, this message translates to:
  /// **'Order completed.'**
  String get order_banner_completed;

  /// No description provided for @order_banner_canceled.
  ///
  /// In en, this message translates to:
  /// **'Order has been canceled.'**
  String get order_banner_canceled;

  /// No description provided for @order_banner_disputed.
  ///
  /// In en, this message translates to:
  /// **'A dispute has been opened. Support is reviewing.'**
  String get order_banner_disputed;

  /// No description provided for @master_available_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No available orders yet'**
  String get master_available_empty_title;

  /// No description provided for @master_available_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'New requests will show up here.'**
  String get master_available_empty_subtitle;

  /// No description provided for @master_order_new_badge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get master_order_new_badge;

  /// No description provided for @master_order_accepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted'**
  String get master_order_accepted;

  /// No description provided for @master_apps_tab_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get master_apps_tab_active;

  /// No description provided for @master_apps_tab_accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get master_apps_tab_accepted;

  /// No description provided for @master_apps_tab_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get master_apps_tab_rejected;

  /// No description provided for @master_apps_tab_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get master_apps_tab_all;

  /// No description provided for @master_apps_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No applications yet'**
  String get master_apps_empty_title;

  /// No description provided for @master_apps_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply to available orders to start.'**
  String get master_apps_empty_subtitle;

  /// No description provided for @master_apps_withdraw_btn.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get master_apps_withdraw_btn;

  /// No description provided for @master_apps_withdraw_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Withdraw application?'**
  String get master_apps_withdraw_confirm_title;

  /// No description provided for @master_apps_withdraw_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'This action can\'t be undone.'**
  String get master_apps_withdraw_confirm_body;

  /// No description provided for @orders_section_attention.
  ///
  /// In en, this message translates to:
  /// **'NEEDS ATTENTION'**
  String get orders_section_attention;

  /// No description provided for @orders_section_active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get orders_section_active;

  /// No description provided for @orders_section_my_applications.
  ///
  /// In en, this message translates to:
  /// **'MY APPLICATIONS'**
  String get orders_section_my_applications;

  /// No description provided for @orders_section_available.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE ORDERS'**
  String get orders_section_available;

  /// No description provided for @orders_section_history.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get orders_section_history;

  /// No description provided for @orders_section_apps_closed.
  ///
  /// In en, this message translates to:
  /// **'CLOSED APPLICATIONS'**
  String get orders_section_apps_closed;

  /// No description provided for @role_master.
  ///
  /// In en, this message translates to:
  /// **'MASTER'**
  String get role_master;

  /// No description provided for @role_client.
  ///
  /// In en, this message translates to:
  /// **'CLIENT'**
  String get role_client;

  /// No description provided for @profile_phone_label.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profile_phone_label;

  /// No description provided for @profile_email_label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profile_email_label;

  /// No description provided for @profile_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profile_city;

  /// No description provided for @profile_experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get profile_experience;

  /// No description provided for @profile_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profile_about;

  /// No description provided for @profile_view_full.
  ///
  /// In en, this message translates to:
  /// **'Open full profile'**
  String get profile_view_full;

  /// No description provided for @order_phone_hidden.
  ///
  /// In en, this message translates to:
  /// **'Phone is hidden until the order is confirmed. Use chat to coordinate.'**
  String get order_phone_hidden;

  /// No description provided for @order_phone_call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get order_phone_call;

  /// No description provided for @order_phone_call_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the call'**
  String get order_phone_call_failed;

  /// No description provided for @order_build_route.
  ///
  /// In en, this message translates to:
  /// **'Build route'**
  String get order_build_route;

  /// No description provided for @order_build_route_sheet_title.
  ///
  /// In en, this message translates to:
  /// **'Where to go'**
  String get order_build_route_sheet_title;

  /// No description provided for @order_copy_address.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get order_copy_address;

  /// No description provided for @master_verified.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get master_verified;

  /// No description provided for @master_urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get master_urgent;

  /// No description provided for @master_reviews_short.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get master_reviews_short;

  /// No description provided for @master_completed.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get master_completed;

  /// No description provided for @master_radius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get master_radius;

  /// No description provided for @master_km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get master_km;

  /// No description provided for @master_experience_short.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get master_experience_short;

  /// No description provided for @order_for_master_label.
  ///
  /// In en, this message translates to:
  /// **'ORDER FOR MASTER'**
  String get order_for_master_label;

  /// No description provided for @order_action_discuss.
  ///
  /// In en, this message translates to:
  /// **'Discuss'**
  String get order_action_discuss;

  /// No description provided for @order_action_decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get order_action_decline;

  /// No description provided for @order_action_confirm_work.
  ///
  /// In en, this message translates to:
  /// **'Send proposal'**
  String get order_action_confirm_work;

  /// No description provided for @order_action_accept_proposal.
  ///
  /// In en, this message translates to:
  /// **'Accept proposal'**
  String get order_action_accept_proposal;

  /// No description provided for @order_action_reject_proposal.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get order_action_reject_proposal;

  /// No description provided for @order_proposal_title.
  ///
  /// In en, this message translates to:
  /// **'Master\'s proposal'**
  String get order_proposal_title;

  /// No description provided for @order_pending_master_24h_warning.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t respond within 24 hours, the order will auto-cancel.'**
  String get order_pending_master_24h_warning;

  /// No description provided for @order_pending_master_24h_warning_client.
  ///
  /// In en, this message translates to:
  /// **'The master has 24 hours to respond. After that the order auto-cancels.'**
  String get order_pending_master_24h_warning_client;

  /// No description provided for @order_confirm_work_hint.
  ///
  /// In en, this message translates to:
  /// **'Pick the date, time and price you agreed with the client.'**
  String get order_confirm_work_hint;

  /// No description provided for @order_confirm_work_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get order_confirm_work_date;

  /// No description provided for @order_confirm_work_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get order_confirm_work_time;

  /// No description provided for @order_confirm_work_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get order_confirm_work_price;

  /// No description provided for @order_confirm_work_send.
  ///
  /// In en, this message translates to:
  /// **'Send proposal'**
  String get order_confirm_work_send;

  /// No description provided for @order_open_chat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get order_open_chat;

  /// No description provided for @order_details_btn.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get order_details_btn;

  /// No description provided for @chat_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Start the conversation.'**
  String get chat_empty_title;

  /// No description provided for @chat_locked.
  ///
  /// In en, this message translates to:
  /// **'Chat opens once the order is confirmed'**
  String get chat_locked;

  /// No description provided for @chat_sys_proposal.
  ///
  /// In en, this message translates to:
  /// **'Proposal sent'**
  String get chat_sys_proposal;

  /// No description provided for @chat_sys_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Order confirmed'**
  String get chat_sys_confirmed;

  /// No description provided for @chat_sys_rejected.
  ///
  /// In en, this message translates to:
  /// **'Proposal rejected'**
  String get chat_sys_rejected;

  /// No description provided for @chat_sys_work_started.
  ///
  /// In en, this message translates to:
  /// **'Work started'**
  String get chat_sys_work_started;

  /// No description provided for @chat_attach_camera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get chat_attach_camera;

  /// No description provided for @chat_attach_gallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from gallery'**
  String get chat_attach_gallery;

  /// No description provided for @chat_photo_too_big.
  ///
  /// In en, this message translates to:
  /// **'Photo too large (max 8 MB)'**
  String get chat_photo_too_big;

  /// No description provided for @chat_photo_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send photo'**
  String get chat_photo_failed;

  /// No description provided for @order_live_map_on_the_way.
  ///
  /// In en, this message translates to:
  /// **'MASTER ON THE WAY'**
  String get order_live_map_on_the_way;

  /// No description provided for @order_live_map_arrived.
  ///
  /// In en, this message translates to:
  /// **'MASTER ARRIVED'**
  String get order_live_map_arrived;

  /// No description provided for @review_leave.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get review_leave;

  /// No description provided for @review_text_label.
  ///
  /// In en, this message translates to:
  /// **'Your review'**
  String get review_text_label;

  /// No description provided for @review_text_hint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about the work...'**
  String get review_text_hint;

  /// No description provided for @review_photos_label.
  ///
  /// In en, this message translates to:
  /// **'PHOTOS (MAX 5)'**
  String get review_photos_label;

  /// No description provided for @review_label_pick.
  ///
  /// In en, this message translates to:
  /// **'Tap a star'**
  String get review_label_pick;

  /// No description provided for @review_label_terrible.
  ///
  /// In en, this message translates to:
  /// **'Terrible'**
  String get review_label_terrible;

  /// No description provided for @review_label_bad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get review_label_bad;

  /// No description provided for @review_label_ok.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get review_label_ok;

  /// No description provided for @review_label_good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get review_label_good;

  /// No description provided for @review_label_excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get review_label_excellent;

  /// No description provided for @review_for_master.
  ///
  /// In en, this message translates to:
  /// **'REVIEWING MASTER'**
  String get review_for_master;

  /// No description provided for @review_for_client.
  ///
  /// In en, this message translates to:
  /// **'REVIEWING CLIENT'**
  String get review_for_client;

  /// No description provided for @review_tags_label.
  ///
  /// In en, this message translates to:
  /// **'QUICK FEEDBACK'**
  String get review_tags_label;

  /// No description provided for @review_tag_punctual.
  ///
  /// In en, this message translates to:
  /// **'Punctual'**
  String get review_tag_punctual;

  /// No description provided for @review_tag_polite.
  ///
  /// In en, this message translates to:
  /// **'Polite'**
  String get review_tag_polite;

  /// No description provided for @review_tag_professional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get review_tag_professional;

  /// No description provided for @review_tag_tidy.
  ///
  /// In en, this message translates to:
  /// **'Tidy'**
  String get review_tag_tidy;

  /// No description provided for @review_tag_fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get review_tag_fast;

  /// No description provided for @review_tag_fair_price.
  ///
  /// In en, this message translates to:
  /// **'Fair price'**
  String get review_tag_fair_price;

  /// No description provided for @profile_role_master.
  ///
  /// In en, this message translates to:
  /// **'MASTER'**
  String get profile_role_master;

  /// No description provided for @profile_role_client.
  ///
  /// In en, this message translates to:
  /// **'CLIENT'**
  String get profile_role_client;

  /// No description provided for @profile_verified.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get profile_verified;

  /// No description provided for @profile_reviews_count.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get profile_reviews_count;

  /// No description provided for @profile_orders_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get profile_orders_completed;

  /// No description provided for @profile_subscription_active.
  ///
  /// In en, this message translates to:
  /// **'Premium active'**
  String get profile_subscription_active;

  /// No description provided for @profile_subscription_inactive.
  ///
  /// In en, this message translates to:
  /// **'Subscription inactive'**
  String get profile_subscription_inactive;

  /// No description provided for @profile_subscription_inactive_sub.
  ///
  /// In en, this message translates to:
  /// **'Renew to keep accepting orders'**
  String get profile_subscription_inactive_sub;

  /// No description provided for @profile_subscription_until.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get profile_subscription_until;

  /// No description provided for @profile_categories_label.
  ///
  /// In en, this message translates to:
  /// **'Service categories'**
  String get profile_categories_label;

  /// No description provided for @profile_recent_reviews.
  ///
  /// In en, this message translates to:
  /// **'Recent reviews'**
  String get profile_recent_reviews;

  /// No description provided for @profile_add_address.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get profile_add_address;

  /// No description provided for @profile_default.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get profile_default;

  /// No description provided for @profile_years_short.
  ///
  /// In en, this message translates to:
  /// **'yr'**
  String get profile_years_short;

  /// No description provided for @profile_km_short.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get profile_km_short;

  /// No description provided for @profile_work_radius.
  ///
  /// In en, this message translates to:
  /// **'Work radius'**
  String get profile_work_radius;

  /// No description provided for @profile_accepting_orders.
  ///
  /// In en, this message translates to:
  /// **'Accepting orders'**
  String get profile_accepting_orders;

  /// No description provided for @profile_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get profile_yes;

  /// No description provided for @profile_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get profile_no;

  /// No description provided for @first_name.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get first_name;

  /// No description provided for @last_name.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get last_name;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @required_field.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get required_field;

  /// No description provided for @auth_email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get auth_email_invalid;

  /// No description provided for @profile_district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get profile_district;

  /// No description provided for @profile_description_hint.
  ///
  /// In en, this message translates to:
  /// **'A short description about yourself...'**
  String get profile_description_hint;

  /// No description provided for @profile_security_label.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get profile_security_label;

  /// No description provided for @profile_change_password.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profile_change_password;

  /// No description provided for @profile_change_password_sub.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get profile_change_password_sub;

  /// No description provided for @profile_password_changed.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get profile_password_changed;

  /// No description provided for @profile_current_password.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get profile_current_password;

  /// No description provided for @profile_new_password.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get profile_new_password;

  /// No description provided for @profile_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get profile_confirm_password;

  /// No description provided for @profile_password_too_short.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get profile_password_too_short;

  /// No description provided for @profile_passwords_dont_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get profile_passwords_dont_match;

  /// No description provided for @profile_danger_zone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get profile_danger_zone;

  /// No description provided for @profile_no_reviews_yet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get profile_no_reviews_yet;

  /// No description provided for @order_completed_title.
  ///
  /// In en, this message translates to:
  /// **'Order completed!'**
  String get order_completed_title;

  /// No description provided for @order_closed_title.
  ///
  /// In en, this message translates to:
  /// **'Order closed'**
  String get order_closed_title;

  /// No description provided for @order_review_section.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get order_review_section;

  /// No description provided for @order_review_yours.
  ///
  /// In en, this message translates to:
  /// **'Your review'**
  String get order_review_yours;

  /// No description provided for @order_review_master.
  ///
  /// In en, this message translates to:
  /// **'Master\'s review'**
  String get order_review_master;

  /// No description provided for @order_review_client.
  ///
  /// In en, this message translates to:
  /// **'Client\'s review'**
  String get order_review_client;

  /// No description provided for @order_review_done.
  ///
  /// In en, this message translates to:
  /// **'SUBMITTED'**
  String get order_review_done;

  /// No description provided for @order_review_pending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get order_review_pending;

  /// No description provided for @order_final_price.
  ///
  /// In en, this message translates to:
  /// **'FINAL AMOUNT'**
  String get order_final_price;

  /// No description provided for @order_cancel_reason_label.
  ///
  /// In en, this message translates to:
  /// **'CANCELLATION REASON'**
  String get order_cancel_reason_label;

  /// No description provided for @order_reorder_btn.
  ///
  /// In en, this message translates to:
  /// **'Order again'**
  String get order_reorder_btn;

  /// No description provided for @ann_apply_btn.
  ///
  /// In en, this message translates to:
  /// **'Accept order'**
  String get ann_apply_btn;

  /// No description provided for @ann_applying.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get ann_applying;

  /// No description provided for @ann_apply_sent.
  ///
  /// In en, this message translates to:
  /// **'Application sent'**
  String get ann_apply_sent;

  /// No description provided for @chat_locked_master_pending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the client to start the discussion or accept you.'**
  String get chat_locked_master_pending;

  /// No description provided for @payment_add_card.
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get payment_add_card;

  /// No description provided for @payment_no_cards.
  ///
  /// In en, this message translates to:
  /// **'No saved cards yet'**
  String get payment_no_cards;

  /// No description provided for @payment_set_default.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get payment_set_default;

  /// No description provided for @payment_delete_card.
  ///
  /// In en, this message translates to:
  /// **'Delete card'**
  String get payment_delete_card;

  /// No description provided for @payment_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this card?'**
  String get payment_delete_confirm;

  /// No description provided for @payment_card_number.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get payment_card_number;

  /// No description provided for @payment_card_holder.
  ///
  /// In en, this message translates to:
  /// **'Cardholder name'**
  String get payment_card_holder;

  /// No description provided for @payment_card_exp.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get payment_card_exp;

  /// No description provided for @payment_set_as_default.
  ///
  /// In en, this message translates to:
  /// **'Use as default payment method'**
  String get payment_set_as_default;

  /// No description provided for @payment_invalid_card.
  ///
  /// In en, this message translates to:
  /// **'Invalid card number'**
  String get payment_invalid_card;

  /// No description provided for @payment_invalid_exp.
  ///
  /// In en, this message translates to:
  /// **'Invalid expiry'**
  String get payment_invalid_exp;

  /// No description provided for @payment_card_expired.
  ///
  /// In en, this message translates to:
  /// **'This card has expired'**
  String get payment_card_expired;

  /// No description provided for @payment_invalid_cvv.
  ///
  /// In en, this message translates to:
  /// **'Invalid CVV'**
  String get payment_invalid_cvv;

  /// No description provided for @payment_save_card.
  ///
  /// In en, this message translates to:
  /// **'Save card'**
  String get payment_save_card;

  /// No description provided for @payment_card_added.
  ///
  /// In en, this message translates to:
  /// **'Card added'**
  String get payment_card_added;

  /// No description provided for @payment_security_note.
  ///
  /// In en, this message translates to:
  /// **'Card details are encrypted and held by the payment provider.'**
  String get payment_security_note;

  /// No description provided for @call_unknown_caller.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get call_unknown_caller;

  /// No description provided for @call_dialing.
  ///
  /// In en, this message translates to:
  /// **'Calling…'**
  String get call_dialing;

  /// No description provided for @call_incoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get call_incoming;

  /// No description provided for @call_ended.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get call_ended;

  /// No description provided for @order_price_via_chat_hint.
  ///
  /// In en, this message translates to:
  /// **'Work price is agreed in chat. The platform only fixes the arrival time.'**
  String get order_price_via_chat_hint;

  /// No description provided for @callout_modal_title.
  ///
  /// In en, this message translates to:
  /// **'Callout payment'**
  String get callout_modal_title;

  /// No description provided for @callout_modal_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Once paid, the order is assigned to the master.'**
  String get callout_modal_subtitle;

  /// No description provided for @callout_no_cards.
  ///
  /// In en, this message translates to:
  /// **'Add a card in payment methods first.'**
  String get callout_no_cards;

  /// No description provided for @callout_add_card_cta.
  ///
  /// In en, this message translates to:
  /// **'Add a card'**
  String get callout_add_card_cta;

  /// No description provided for @callout_pay_btn.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} AZN'**
  String callout_pay_btn(String amount);

  /// No description provided for @callout_split_master.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get callout_split_master;

  /// No description provided for @callout_split_platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get callout_split_platform;

  /// No description provided for @wallet_title.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet_title;

  /// No description provided for @wallet_balance.
  ///
  /// In en, this message translates to:
  /// **'Available to withdraw'**
  String get wallet_balance;

  /// No description provided for @wallet_withdraw_cta.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get wallet_withdraw_cta;

  /// No description provided for @wallet_withdrawals.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal requests'**
  String get wallet_withdrawals;

  /// No description provided for @wallet_transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get wallet_transactions;

  /// No description provided for @wallet_empty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get wallet_empty;

  /// No description provided for @wallet_withdraw_title.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request'**
  String get wallet_withdraw_title;

  /// No description provided for @wallet_amount_label.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get wallet_amount_label;

  /// No description provided for @wallet_holder_label.
  ///
  /// In en, this message translates to:
  /// **'Account holder'**
  String get wallet_holder_label;

  /// No description provided for @wallet_note_label.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get wallet_note_label;

  /// No description provided for @wallet_withdraw_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get wallet_withdraw_submit;

  /// No description provided for @wallet_amount_exceeds.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds available balance.'**
  String get wallet_amount_exceeds;

  /// No description provided for @wallet_status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get wallet_status_pending;

  /// No description provided for @wallet_status_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get wallet_status_approved;

  /// No description provided for @wallet_status_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get wallet_status_paid;

  /// No description provided for @wallet_status_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get wallet_status_rejected;

  /// No description provided for @wallet_status_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get wallet_status_cancelled;

  /// No description provided for @wallet_kind_callout_fee.
  ///
  /// In en, this message translates to:
  /// **'Callout fee'**
  String get wallet_kind_callout_fee;

  /// No description provided for @wallet_kind_callout_refund.
  ///
  /// In en, this message translates to:
  /// **'Callout refund'**
  String get wallet_kind_callout_refund;

  /// No description provided for @wallet_kind_master_penalty.
  ///
  /// In en, this message translates to:
  /// **'Cancellation penalty'**
  String get wallet_kind_master_penalty;

  /// No description provided for @wallet_kind_withdrawal_hold.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal hold'**
  String get wallet_kind_withdrawal_hold;

  /// No description provided for @wallet_kind_withdrawal_paid.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal paid'**
  String get wallet_kind_withdrawal_paid;

  /// No description provided for @wallet_kind_withdrawal_restore.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal restored'**
  String get wallet_kind_withdrawal_restore;

  /// No description provided for @wallet_kind_manual_adjust.
  ///
  /// In en, this message translates to:
  /// **'Admin adjustment'**
  String get wallet_kind_manual_adjust;

  /// No description provided for @order_create_photos_label.
  ///
  /// In en, this message translates to:
  /// **'Problem photos'**
  String get order_create_photos_label;

  /// No description provided for @order_create_photos_hint.
  ///
  /// In en, this message translates to:
  /// **'Add up to 5 photos — they help the master assess the job upfront.'**
  String get order_create_photos_hint;

  /// No description provided for @apps_withdraw_title.
  ///
  /// In en, this message translates to:
  /// **'Withdraw application?'**
  String get apps_withdraw_title;

  /// No description provided for @apps_reject_title.
  ///
  /// In en, this message translates to:
  /// **'Reject this master?'**
  String get apps_reject_title;

  /// No description provided for @apps_reject_confirm.
  ///
  /// In en, this message translates to:
  /// **'This master will no longer be able to message you about this order.'**
  String get apps_reject_confirm;

  /// No description provided for @apps_reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get apps_reject;

  /// No description provided for @ann_open_chat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get ann_open_chat;

  /// No description provided for @ann_discuss.
  ///
  /// In en, this message translates to:
  /// **'Discuss'**
  String get ann_discuss;

  /// No description provided for @order_action_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get order_action_accept;

  /// No description provided for @chat_sys_callout_paid.
  ///
  /// In en, this message translates to:
  /// **'Callout fee paid'**
  String get chat_sys_callout_paid;

  /// No description provided for @chat_sys_default.
  ///
  /// In en, this message translates to:
  /// **'System message'**
  String get chat_sys_default;

  /// No description provided for @order_status_pending_client.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get order_status_pending_client;

  /// No description provided for @order_status_pending_payment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get order_status_pending_payment;

  /// No description provided for @order_timeline_payment_received.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get order_timeline_payment_received;

  /// No description provided for @error_page_not_found_title.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get error_page_not_found_title;

  /// No description provided for @error_page_not_found_desc.
  ///
  /// In en, this message translates to:
  /// **'This link may be outdated or malformed. Every service is reachable from the home screen.'**
  String get error_page_not_found_desc;

  /// No description provided for @error_back_home.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get error_back_home;

  /// No description provided for @guest_orders_title.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your orders'**
  String get guest_orders_title;

  /// No description provided for @guest_orders_body.
  ///
  /// In en, this message translates to:
  /// **'Order history and active jobs are available once you sign in.'**
  String get guest_orders_body;

  /// No description provided for @guest_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your profile'**
  String get guest_profile_title;

  /// No description provided for @guest_profile_body.
  ///
  /// In en, this message translates to:
  /// **'Personal details, addresses and payment methods are available once you sign in.'**
  String get guest_profile_body;

  /// No description provided for @chat_empty_hint.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Write first — the specialist will reply.'**
  String get chat_empty_hint;

  /// No description provided for @chat_composer_hint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get chat_composer_hint;

  /// No description provided for @order_no_applications.
  ///
  /// In en, this message translates to:
  /// **'No applications yet. Usually takes 5–10 minutes.'**
  String get order_no_applications;

  /// No description provided for @master_meta_years.
  ///
  /// In en, this message translates to:
  /// **'{n} yrs'**
  String master_meta_years(int n);

  /// No description provided for @master_meta_completed.
  ///
  /// In en, this message translates to:
  /// **'{n} orders'**
  String master_meta_completed(int n);

  /// No description provided for @master_view_profile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get master_view_profile;

  /// No description provided for @order_pending_master_q.
  ///
  /// In en, this message translates to:
  /// **'Accept this order?'**
  String get order_pending_master_q;

  /// No description provided for @order_proposal_q.
  ///
  /// In en, this message translates to:
  /// **'The specialist proposed a price'**
  String get order_proposal_q;

  /// No description provided for @order_waiting_master.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the specialist…'**
  String get order_waiting_master;

  /// No description provided for @order_open_in_maps.
  ///
  /// In en, this message translates to:
  /// **'Open in…'**
  String get order_open_in_maps;

  /// No description provided for @order_tab_chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get order_tab_chat;

  /// No description provided for @order_tab_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get order_tab_details;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'az', 'en', 'ru', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'az': return AppLocalizationsAz();
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
