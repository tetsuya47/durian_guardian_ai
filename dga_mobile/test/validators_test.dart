import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Email Validator Tests', () {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    test('Valid emails should return true', () {
      expect(emailRegExp.hasMatch('test@gmail.com'), isTrue);
      expect(emailRegExp.hasMatch('user.name@dga.vn'), isTrue);
      expect(emailRegExp.hasMatch('farmer_123@abc.co.uk'), isTrue);
    });

    test('Invalid emails should return false', () {
      expect(emailRegExp.hasMatch('test'), isFalse);
      expect(emailRegExp.hasMatch('test@'), isFalse);
      expect(emailRegExp.hasMatch('test@gmail'), isFalse);
      expect(emailRegExp.hasMatch('test@.com'), isFalse);
      expect(emailRegExp.hasMatch('@gmail.com'), isFalse);
    });
  });

  group('Vietnamese Phone Validator Tests', () {
    final phoneRegExp = RegExp(r'^(0[35789])[0-9]{8}$');

    test('Valid Vietnamese phone numbers should return true', () {
      expect(phoneRegExp.hasMatch('0987654321'), isTrue);
      expect(phoneRegExp.hasMatch('0312345678'), isTrue);
      expect(phoneRegExp.hasMatch('0799887766'), isTrue);
      expect(phoneRegExp.hasMatch('0865432109'), isTrue);
    });

    test('Invalid phone numbers should return false', () {
      expect(phoneRegExp.hasMatch('0287654321'), isFalse); // Carrier 2 not allowed (typically landlines)
      expect(phoneRegExp.hasMatch('098765432'), isFalse);  // 9 digits instead of 10
      expect(phoneRegExp.hasMatch('09876543210'), isFalse); // 11 digits instead of 10
      expect(phoneRegExp.hasMatch('1987654321'), isFalse);  // Doesn't start with 0
      expect(phoneRegExp.hasMatch('098abc4321'), isFalse);  // Contains alphabet characters
    });
  });
}
