import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

Future<String?> pickCertificateFileContent() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['p12', 'pfx', 'pem', 'crt', 'key', 'txt'],
  );
  if (files.isNotEmpty) {
    final file = files.first;
    final bytes = await file.readAsBytes();
    return processCertificateBytes(bytes, file.name);
  }
  return null;
}

String processCertificateBytes(Uint8List bytes, String fileName) {
  try {
    final text = utf8.decode(bytes);
    if (text.contains('-----BEGIN')) {
      return text;
    }
  } catch (_) {}

  return base64Encode(bytes);
}
