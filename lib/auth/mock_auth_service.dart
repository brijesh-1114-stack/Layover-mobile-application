import 'auth_service.dart';

/// Stand in for the real backend so the flow is walkable before one exists.
///
/// Rules, chosen so both branches can be exercised by hand:
///   * the code is always `123456`
///   * a number ending in an even digit is treated as already registered and
///     goes straight to the app
///   * anything else is treated as new and runs the profile screens
class MockAuthService implements AuthService {
  MockAuthService({this.latency = const Duration(milliseconds: 700)});

  /// Fake network delay, so loading states are exercised rather than skipped.
  final Duration latency;

  static const String demoCode = '123456';

  ProfileDraft _draft = const ProfileDraft();
  ProfileDraft get draft => _draft;

  @override
  Duration get resendCooldown => const Duration(seconds: 30);

  @override
  Future<void> requestCode(String phone) async {
    await Future<void>.delayed(latency);
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) {
      throw const AuthException('Enter a valid phone number.');
    }
  }

  @override
  Future<AuthResult> verifyCode({
    required String phone,
    required String code,
  }) async {
    await Future<void>.delayed(latency);
    if (code != demoCode) {
      throw const AuthException('That code is not right. Try again.');
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final lastDigit = int.tryParse(digits.characters.last) ?? 1;
    final returning = lastDigit.isEven;
    return AuthResult(
      userId: 'u_${digits.hashCode.toUnsigned(32).toRadixString(16)}',
      profileComplete: returning,
    );
  }

  @override
  Future<void> submitProfile(ProfileDraft draft) async {
    await Future<void>.delayed(latency);
    _draft = draft;
  }
}

extension on String {
  Iterable<String> get characters => split('');
}
