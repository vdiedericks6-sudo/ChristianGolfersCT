import 'package:supabase_flutter/supabase_flutter.dart';

String authErrorMessage(Object error) {
  if (error is AuthApiException) {
    switch (error.code) {
      case 'user_banned':
        return 'This account has been disabled.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Too many attempts. Please wait and try again.';
      case 'provider_disabled':
        return 'Google sign-in is not enabled for this project yet.';
      case 'validation_failed':
        return 'Sign-in could not be completed. Please try again.';
    }

    return error.message;
  }

  if (error is AuthException) {
    return error.message;
  }

  if (error is PostgrestException) {
    // RLS denials and check-constraint failures surface here.
    return error.message;
  }

  return 'Something went wrong. Please try again.';
}
