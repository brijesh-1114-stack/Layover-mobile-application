/// Outcome of verifying a code.
///
/// The flag is [profileComplete], deliberately not "isNewUser". Someone who
/// verifies then quits on the email screen is no longer new, but their profile
/// is half finished. Branching on "new" would drop them into the app with no
/// name and no age check; branching on completeness sends them back to the
/// first missing field.
class AuthResult {
  const AuthResult({required this.userId, required this.profileComplete});

  final String userId;
  final bool profileComplete;
}

/// The profile a new account has to fill in before it can use the app.
class ProfileDraft {
  const ProfileDraft({this.name, this.email, this.birthday});

  final String? name;
  final String? email;
  final DateTime? birthday;

  ProfileDraft copyWith({String? name, String? email, DateTime? birthday}) =>
      ProfileDraft(
        name: name ?? this.name,
        email: email ?? this.email,
        birthday: birthday ?? this.birthday,
      );
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Backend seam for phone based, passwordless sign in.
///
/// Everything here has to live on a server: an app cannot send its own SMS, and
/// a code the client can read is a code the client can skip. The screens talk
/// only to this interface, so the mock can be swapped for Firebase without any
/// screen changing.
abstract interface class AuthService {
  /// Sends a code to [phone]. The response never reveals whether the number is
  /// already registered, otherwise anyone could probe numbers to discover who
  /// uses the app.
  Future<void> requestCode(String phone);

  /// Verifies [code] against [phone]. Only after ownership is proven does the
  /// server say whether this account already exists.
  Future<AuthResult> verifyCode({required String phone, required String code});

  /// Saves the profile collected on the new user screens.
  Future<void> submitProfile(ProfileDraft draft);

  /// How long until [requestCode] may be called again.
  Duration get resendCooldown;
}
