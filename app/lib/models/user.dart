/// Profile stored at `users/<uid>` (name, email).
class AppUser {
  const AppUser({required this.uid, required this.name, required this.email});

  final String uid;
  final String name;
  final String email;

  factory AppUser.fromMap(String uid, Map<dynamic, dynamic>? map) {
    return AppUser(
      uid: uid,
      name: (map?['name'] as String?) ?? '',
      email: (map?['email'] as String?) ?? '',
    );
  }
}
