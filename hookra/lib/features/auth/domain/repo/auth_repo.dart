abstract class AuthRepo {
  Future<String> signup(
    String email,
    String password,
    String firstName,
    String lastName,
  );
  Future<void> login(String email, String password);
}
