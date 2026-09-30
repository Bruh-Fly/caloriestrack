import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  static const _googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        _googleServerClientId.isEmpty ? null : _googleServerClientId,
  );
  final _api = ApiClient();
  String? lastSignInError;

  static const _profileKey = 'user_profile';
  static const _onboardedKey = 'onboarding_done';

  // ── Google Sign-in ─────────────────────────────────────────────
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    lastSignInError = null;
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        lastSignInError =
            'Google sign-in was cancelled or returned no account.';
        return null;
      }
      final idToken = (await account.authentication).idToken;
      if (idToken == null) {
        lastSignInError =
            'Google did not return an ID token. Check the Web OAuth client ID and Android SHA-1 configuration.';
        return null;
      }
      await _api.signInWithGoogle(idToken);
      return account;
    } catch (error, stackTrace) {
      lastSignInError = error.toString();
      debugPrint('Google sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> signOut() async {
    await _api.signOut();
    await _googleSignIn.signOut();
    // Keep the account-matched cache; it is never treated as authentication.
  }

  Future<GoogleSignInAccount?> get currentUser async {
    return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  }

  // ── Profile Storage (local) ────────────────────────────────────
  Future<void> saveProfile(UserProfile profile) async {
    await _api.saveProfile(profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    await prefs.setBool(_onboardedKey, true);
  }

  Future<UserProfile?> loadProfile() async {
    try {
      final remoteProfile = await _api.loadProfile();
      if (remoteProfile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileKey, jsonEncode(remoteProfile.toJson()));
        await prefs.setBool(_onboardedKey, true);
      }
      return remoteProfile;
    } catch (error) {
      // A cached profile is not authentication; require a valid backend session.
      lastSignInError =
          'Đăng nhập được nhưng không tải được hồ sơ từ máy chủ: $error';
      return null;
    }
  }

  /// Reads cached display/profile data only when a secure backend session exists.
  /// Protected API calls still validate or refresh that session server-side.
  Future<UserProfile?> loadCachedProfileForSession() async {
    if (!await _api.hasStoredSession()) return null;
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_profileKey);
    if (json == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isOnboarded() async {
    return await loadProfile() != null;
  }

  // ── Already-have-account: sign in + load existing profile ──────
  Future<UserProfile?> signInExisting() async {
    // Clear Google's cached account selection so Android presents the chooser.
    await _googleSignIn.signOut();
    final account = await signInWithGoogle();
    if (account == null) return null;
    final remote = await loadProfile();
    if (remote != null) return remote;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw != null) {
      try {
        final cached =
            UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (cached.uid == account.id) return cached;
      } catch (_) {}
    }
    lastSignInError ??=
        'Đã đăng nhập Google nhưng backend chưa tìm thấy hồ sơ của tài khoản này.';
    return null;
  }
}
