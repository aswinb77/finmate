import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/app_user.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalStorageService _storage = LocalStorageService();

  AppUser? _currentUser;
  bool _isInitialized = false;
  bool _isGuest = true;
  bool _hasSeenWelcome = false;
  String? _lastError;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && !_isGuest;
  bool get isGuest => _isGuest;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isInitialized => _isInitialized;
  bool get hasSeenWelcome => _hasSeenWelcome;
  String? get lastError => _lastError;

  static const String defaultAdminEmail = 'varientLoki7@gmail.com';

  /// Check if Firebase is ready for auth operations
  bool get _firebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
      final cachedUid = prefs.getString('auth_uid');
      final wasGuest = prefs.getBool('is_guest') ?? true;

      if (cachedUid != null && cachedUid.isNotEmpty) {
        _currentUser = await _storage.getUser(cachedUid);
        _isGuest = wasGuest;
      }

      // If no cached user exists, initialize guest user
      if (_currentUser == null) {
        _currentUser = AppUser(
          uid: 'guest_user',
          email: '',
          name: 'Guest',
          role: 'user',
          lastActiveAt: DateTime.now(),
        );
        _isGuest = true;
        await _storage.saveUser(_currentUser!);
        await prefs.setString('auth_uid', 'guest_user');
        await prefs.setBool('is_guest', true);
      } else {
        _currentUser = _currentUser!.copyWith(lastActiveAt: DateTime.now());
        await _storage.saveUser(_currentUser!);
      }

      if (!_isGuest) {
        SyncService().triggerSync();
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> markWelcomeSeen() async {
    _hasSeenWelcome = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
  }

  Future<void> continueAsGuest() async {
    try {
      _currentUser = AppUser(
        uid: 'guest_user',
        email: '',
        name: 'Guest',
        role: 'user',
        lastActiveAt: DateTime.now(),
      );
      _isGuest = true;

      await _storage.saveUser(_currentUser!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_uid', 'guest_user');
      await prefs.setBool('is_guest', true);
      await markWelcomeSeen();
      _lastError = null;
    } catch (e) {
      debugPrint('continueAsGuest error: $e');
      _lastError = e.toString();
      _hasSeenWelcome = true;
    }
    notifyListeners();
  }

  Future<bool> signup(String name, String email, String password) async {
    _lastError = null;
    final cleanEmail = email.trim();
    final cleanName = name.trim().isNotEmpty ? name.trim() : cleanEmail.split('@').first;
    final role = (cleanEmail.toLowerCase() == defaultAdminEmail.toLowerCase())
        ? 'admin'
        : 'user';
    String uid = 'uid_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    if (_firebaseReady) {
      try {
        final credential = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        if (credential.user?.uid != null) {
          uid = credential.user!.uid;
        }
      } on fb.FirebaseAuthException catch (e) {
        debugPrint('Firebase signup error: ${e.code} - ${e.message}');
        if (e.code == 'email-already-in-use') {
          // If already registered in Firebase, attempt login instead
          return login(email, password);
        } else {
          _lastError = e.message ?? 'Signup failed: ${e.code}';
          notifyListeners();
          return false;
        }
      } catch (e) {
        debugPrint('Firebase signup generic error: $e');
      }
    }

    try {
      final newUser = AppUser(
        uid: uid,
        email: cleanEmail,
        name: cleanName,
        role: role,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      _currentUser = newUser;
      _isGuest = false;
      await _storage.saveUser(newUser);
      await _storage.migrateUserData(fromUserId: 'guest_user', toUserId: uid);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_uid', uid);
      await prefs.setBool('is_guest', false);
      await markWelcomeSeen();

      notifyListeners();
      SyncService().triggerSync();
      return true;
    } catch (e) {
      debugPrint('Local signup save error: $e');
      _lastError = 'Failed to save account locally: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _lastError = null;
    final cleanEmail = email.trim();
    final role = (cleanEmail.toLowerCase() == defaultAdminEmail.toLowerCase())
        ? 'admin'
        : 'user';
    String uid = 'uid_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    if (_firebaseReady) {
      try {
        final credential = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        if (credential.user?.uid != null) {
          uid = credential.user!.uid;
        }
      } on fb.FirebaseAuthException catch (e) {
        debugPrint('Firebase login error: ${e.code} - ${e.message}');
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // Attempt auto signup if account doesn't exist in Firebase yet
          try {
            final credential = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: cleanEmail,
              password: password,
            );
            if (credential.user?.uid != null) {
              uid = credential.user!.uid;
            }
          } catch (signupErr) {
            if (signupErr is fb.FirebaseAuthException && signupErr.code == 'wrong-password') {
              _lastError = 'Incorrect password. Please check your password.';
              notifyListeners();
              return false;
            }
          }
        } else if (e.code == 'wrong-password') {
          _lastError = 'Incorrect password. Please check your password.';
          notifyListeners();
          return false;
        }
      } catch (e) {
        debugPrint('Firebase login generic error: $e');
      }
    }

    try {
      final existingUser = await _storage.getUser(uid);
      final user = existingUser?.copyWith(
        lastActiveAt: DateTime.now(),
        role: role,
      ) ?? AppUser(
        uid: uid,
        email: cleanEmail,
        name: cleanEmail.split('@').first,
        role: role,
        lastActiveAt: DateTime.now(),
      );

      _currentUser = user;
      _isGuest = false;
      await _storage.saveUser(user);
      await _storage.migrateUserData(fromUserId: 'guest_user', toUserId: uid);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_uid', uid);
      await prefs.setBool('is_guest', false);
      await markWelcomeSeen();

      notifyListeners();
      SyncService().triggerSync();
      return true;
    } catch (e) {
      debugPrint('Local login save error: $e');
      _lastError = 'Failed to save login locally: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminLogin(String email, String password, String passphrase) async {
    if (passphrase != 'finmate-admin-2026') return false;
    _lastError = null;

    final cleanEmail = email.trim().isEmpty ? defaultAdminEmail : email.trim();
    final uid = 'uid_admin_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    try {
      final adminUser = AppUser(
        uid: uid,
        email: cleanEmail,
        name: 'Admin Loki',
        role: 'admin',
        lastActiveAt: DateTime.now(),
      );

      _currentUser = adminUser;
      _isGuest = false;
      await _storage.saveUser(adminUser);
      await _storage.migrateUserData(fromUserId: 'guest_user', toUserId: uid);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_uid', uid);
      await prefs.setBool('is_guest', false);
      await markWelcomeSeen();

      notifyListeners();
      SyncService().triggerSync();
      return true;
    } catch (e) {
      debugPrint('Admin login error: $e');
      _lastError = 'Admin login failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_firebaseReady) {
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (_) {}
    }

    _currentUser = AppUser(
      uid: 'guest_user',
      email: '',
      name: 'Guest',
      role: 'user',
      lastActiveAt: DateTime.now(),
    );
    _isGuest = true;

    try {
      await _storage.clearAllData();
      await _storage.saveUser(_currentUser!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_uid', 'guest_user');
      await prefs.setBool('is_guest', true);
    } catch (e) {
      debugPrint('Logout save error: $e');
    }

    notifyListeners();
    SyncService().refreshUnsyncedCount();
  }

  Future<void> updateRole(String newRole) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      role: newRole,
      lastActiveAt: DateTime.now(),
    );
    await _storage.saveUser(_currentUser!);
    notifyListeners();
  }
}
