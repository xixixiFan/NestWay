import 'package:flutter/material.dart';

import '../pages/home/home_page.dart';
import '../pages/sos/sos_page.dart';
import '../pages/sos/sos_history_page.dart';
import '../pages/sos/send_sos_message_page.dart';
import '../pages/sos/emergency_contacts_page.dart';
import '../pages/escort/escort_page.dart';
import '../pages/safety/safety_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/auth/login_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String sos = '/sos';
  static const String sosHistory = '/sos_history';
  static const String sendSosMessage = '/send_sos_message';
  static const String emergencyContacts = '/emergency_contacts';
  static const String escort = '/escort';
  static const String escortProgress = '/escort_progress';
  static const String success = '/success';
  static const String timeout = '/timeout';
  static const String safety = '/safety';
  static const String profile = '/profile';

  static final routes = <String, WidgetBuilder>{
    home: (context) => const HomePage(),
    login: (context) => const LoginPage(),
    sos: (context) => const SosPage(),
    sosHistory: (context) => const SosHistoryPage(),
    sendSosMessage: (context) => const SendSosMessagePage(),
    emergencyContacts: (context) => const EmergencyContactsPage(),
    escort: (context) => const EscortPage(),
    // escortProgress/success/timeout 改为构造器传参导航，不再使用命名路由
    safety: (context) => const SafetyPage(),
    profile: (context) => const ProfilePage(),
  };
}
