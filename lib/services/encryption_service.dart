import 'dart:math';

class EncryptionService {
  static const String _headerPrefix = '0010010';
  static const String _printable =
      ' !"#\%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~';

  static bool hasForbiddenCharacter(String s) {
    for (var c in s.runes) {
      int idx = _printable.indexOf(String.fromCharCode(c));
      if (idx == -1) return true;
    }
    return false;
  }

  static List<String> _shuffledAlphabet(String passkey) {
    final chars = _printable.split('');
    int hash = passkey.codeUnits.fold(0, (a, b) => a * 31 + b);
    final prng = Random(hash);
    for (int i = chars.length - 1; i > 0; i--) {
      int j = prng.nextInt(i + 1);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }
    return chars;
  }

  static String encrypt(String message, String passkey) {
    final shuffled = _shuffledAlphabet(passkey);
    final buffer = StringBuffer();
    for (var c in message.runes) {
      int idx = _printable.indexOf(String.fromCharCode(c));
      if (idx == -1) throw Exception('Message contains non-printable character');
      buffer.write(shuffled[idx]);
    }
    return buffer.toString();
  }

  static String decrypt(String encrypted, String passkey) {
    final shuffled = _shuffledAlphabet(passkey);
    final buffer = StringBuffer();
    for (var c in encrypted.runes) {
      int idx = shuffled.indexOf(String.fromCharCode(c));
      if (idx == -1) throw Exception('Encrypted message contains non-printable character');
      buffer.write(_printable[idx]);
    }
    return buffer.toString();
  }

  static String createHeader(bool isDataMessage) {
    final suffix = isDataMessage ? '1' : '0';
    return String.fromCharCode(int.parse(_headerPrefix + suffix, radix: 2));
  }

  static bool hasAppHeader(String message) {
    if (message.isEmpty) return false;
    print(message);
    final firstChar = message[0];
    final charCode = firstChar.codeUnitAt(0);
    final binary = charCode.toRadixString(2).padLeft(8, '0');
    print("Content : $message -> Binary is $binary and prefix should be $_headerPrefix");
    final b = binary.startsWith(_headerPrefix);
    print("Will return $b");
    return binary.startsWith(_headerPrefix);
  }

  static bool isDataMessage(String message) {
    if (!hasAppHeader(message)) return false;
    final firstChar = message[0];
    final charCode = firstChar.codeUnitAt(0);
    final binary = charCode.toRadixString(2).padLeft(8, '0');
    //print("Content : $message -> $binary (Should end with 1)");
    return binary.endsWith('1');
  }

  static String removeHeader(String message) {
    if (!hasAppHeader(message)) return message;
    return message.substring(1);
  }

  static String addHeader(String message, bool isDataMessage) {
    final header = createHeader(isDataMessage);
    return header + message;
  }
} 