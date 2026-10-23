import 'app_user.dart';

abstract interface class AuthService {
  AppUser get currentUser;
}
