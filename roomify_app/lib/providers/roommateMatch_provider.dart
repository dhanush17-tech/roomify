import 'package:flutter/material.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/repository/rommate_match_repo.dart';

class RoommateMatchProvider extends ChangeNotifier {
  final RoommateMatchRepository _repository;
  List<User> _matches = [];
  bool _isLoading = false;
  String? _error;

  RoommateMatchProvider(this._repository);

  List<User> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMatches() async {
    try {
      _setLoading(true);
      _matches = await _repository.getMatches();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> swipeLeft(String userId) async {
    // try {
    //   await _repository.recordSwipe(userId, 'left');
    //   _removeMatch(userId);
    // } catch (e) {
    //   _error = e.toString();
    //   notifyListeners();
    // }
  }

  Future<void> swipeRight(String userId) async {
    // try {
    //   await _repository.recordSwipe(userId, 'right');
    //   _removeMatch(userId);
    // } catch (e) {
    //   _error = e.toString();
    //   notifyListeners();
    // }
  }

  void _removeMatch(String userId) {
    _matches.removeWhere((match) => match.id == userId);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
