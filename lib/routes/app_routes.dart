import 'package:flutter/material.dart';

import '../pages/home/home_page.dart';
import '../pages/sos/sos_page.dart';
import '../pages/sos/sos_history_page.dart';
import '../pages/escort/escort_page.dart';
import '../pages/escort/progress_page.dart';
import '../pages/common/success_page.dart';
import '../pages/common/timeout_page.dart';
import '../pages/safety/safety_page.dart';
import '../pages/profile/profile_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String sos = '/sos';
  static const String sosHistory = '/sos_history';
  static const String escort = '/escort';
  static const String escortProgress = '/escort_progress';
  static const String success = '/success';
  static const String timeout = '/timeout';
  static const String safety = '/safety';
  static const String profile = '/profile';

  static final routes = <String, WidgetBuilder>{
    home: (context) => const HomePage(),
    sos: (context) => const SosPage(),
    sosHistory: (context) => const SosHistoryPage(),
    escort: (context) => const EscortPage(),
    escortProgress: (context) => const ProgressPage(),
    success: (context) => const SuccessPage(),
    timeout: (context) => const TimeoutPage(),
    safety: (context) => const SafetyPage(),
    profile: (context) => const ProfilePage(),
  };
}