import 'package:flutter/material.dart';
import 'sos_service.dart';

class ContactsProvider extends ChangeNotifier {
  final SosService _sosService = SosService();
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get contacts => _contacts;
  bool get isLoading => _isLoading;

  Future<void> loadContacts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _contacts = await _sosService.getEmergencyContacts();
    } catch (e) {
      print('加载联系人失败: $e');
      _contacts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addContact({
    required String name,
    required String phone,
  }) async {
    final success = await _sosService.addEmergencyContact(
      name: name,
      phone: phone,
    );
    if (success) {
      await loadContacts();
    }
    return success;
  }

  Future<bool> updateContact({
    required int id,
    required String name,
    required String phone,
  }) async {
    final success = await _sosService.updateEmergencyContact(
      id: id,
      name: name,
      phone: phone,
    );
    if (success) {
      await loadContacts();
    }
    return success;
  }

  Future<bool> deleteContact(int id) async {
    final success = await _sosService.deleteEmergencyContact(id);
    if (success) {
      await loadContacts();
    }
    return success;
  }
}
