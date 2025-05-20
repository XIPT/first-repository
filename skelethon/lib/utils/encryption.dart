import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

class EncryptionUtil {
  // 암호화 키 (안전하게 관리해야 함)
  static final key = encrypt.Key.fromUtf8('0123456789abcdef0123456789abcdef'); // 정확히 32바이트

  // 방법 1: 고정된 IV 사용 (간단하지만 보안상 덜 안전함)
  static final iv = encrypt.IV.fromUtf8('1234567890abcdef'); // 정확히 16바이트
  static final encrypter = encrypt.Encrypter(encrypt.AES(key));

  // 데이터 암호화
  static String encryptData(dynamic data) {
    final text = data is String ? data : jsonEncode(data);
    final encrypted = encrypter.encrypt(text, iv: iv);
    return encrypted.base64;
  }

  // 데이터 복호화 (오류 처리 추가)
  static String decryptData(String encryptedText) {
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print("복호화 오류 (내부): $e");
      throw e;
    }
  }

  // JSON 데이터 복호화 및 파싱 (오류 처리 추가)
  static dynamic decryptJsonData(String encryptedText) {
    try {
      final decrypted = decryptData(encryptedText);
      return jsonDecode(decrypted);
    } catch (e) {
      print("JSON 파싱 오류: $e");
      return [];
    }
  }
}