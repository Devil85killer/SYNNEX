class ChatPermission {
  static bool canChat({
    required String myRole,
    required String otherRole,
  }) {
    if (myRole == 'alumni' &&
        (otherRole == 'student' || otherRole == 'teacher')) {
      return true;
    }

    if ((myRole == 'student' || myRole == 'teacher') &&
        otherRole == 'alumni') {
      return true;
    }

    return false;
  }
}
