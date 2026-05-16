import 'package:flutter/material.dart';
import '../data/demo_users.dart';
import 'sos_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isDemoMode = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  int? get currentUserId => _currentUser?['id'] as int?;
  bool get isLoggedIn => _currentUser != null;
  bool get isDemoMode => _isDemoMode;

  void loginAsDemoUser(int userId) {
    final user = demoUsers.firstWhere(
      (u) => u['id'] == userId,
      orElse: () => demoUsers[0],
    );
    _currentUser = Map<String, dynamic>.from(user);
    _isDemoMode = true;
    SosService().currentUserId = userId;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isDemoMode = false;
    SosService().currentUserId = null;
    notifyListeners();
  }
}
