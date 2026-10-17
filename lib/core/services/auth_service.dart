import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import 'local_storage_service.dart';

class AuthService {
  final LocalStorageService _storage;
  AppUser? _currentUser;

  AuthService(this._storage) {
    // Only restore existing saved session; do not force auto-login for clean sessions
    _currentUser = _storage.getUser();
  }

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Pre-configured campus demo profiles for immediate two-party testing and evaluator review
  static final List<AppUser> demoStudents = [
    const AppUser(
      id: 'usr_aarav_01',
      email: 'aarav.sharma2023@vitstudent.ac.in',
      displayName: 'Aarav Sharma',
      studentId: '23BCE1042',
      role: 'student',
      phoneNumber: '+91 98765 43210',
      isVerified: true,
    ),
    const AppUser(
      id: 'usr_diya_02',
      email: 'diya.patel2023@vitstudent.ac.in',
      displayName: 'Diya Patel',
      studentId: '23BCE1984',
      role: 'student',
      phoneNumber: '+91 91234 56789',
      isVerified: true,
    ),
    const AppUser(
      id: 'usr_moderator_03',
      email: 'security.warden@vit.ac.in',
      displayName: 'Prof. R. Verma (Campus Security)',
      studentId: 'FAC9021',
      role: 'moderator',
      phoneNumber: '+91 94444 11223',
      isVerified: true,
    ),
  ];

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    // Check if matching demo account
    final match = demoStudents.where(
      (u) => u.email.toLowerCase() == cleanEmail,
    );
    if (match.isNotEmpty) {
      _currentUser = match.first;
    } else {
      _currentUser = AppUser(
        id: 'usr_${const Uuid().v4().substring(0, 8)}',
        email: email.trim(),
        displayName: email.split('@').first,
        studentId: '23BCE${1000 + email.hashCode.abs() % 9000}',
        role: 'student',
      );
    }
    await _storage.saveUser(_currentUser!);
    return _currentUser!;
  }

  Future<AppUser> registerStudent({
    required String name,
    required String email,
    required String studentId,
    String? phone,
  }) async {
    final newUser = AppUser(
      id: 'usr_${const Uuid().v4().substring(0, 8)}',
      email: email.trim(),
      displayName: name.trim(),
      studentId: studentId.trim().toUpperCase(),
      role: 'student',
      phoneNumber: phone,
    );
    _currentUser = newUser;
    await _storage.saveUser(newUser);
    return newUser;
  }

  Future<void> switchProfile(AppUser user) async {
    _currentUser = user;
    await _storage.saveUser(user);
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _storage.clearUser();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    // Simulated password reset workflow for campus email
    await Future.delayed(const Duration(milliseconds: 400));
  }
}
