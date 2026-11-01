import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<String?> pickCertificateFileContent() async {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement()
    ..accept = '.p12,.pfx,.pem,.crt,.key,.txt';
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        try {
          final result = reader.result;
          Uint8List bytes;
          if (result is Uint8List) {
            bytes = result;
          } else if (result is ByteBuffer) {
            bytes = Uint8List.view(result);
          } else {
            final readerText = html.FileReader();
            readerText.readAsText(file);
            readerText.onLoadEnd.listen((_) {
              completer.complete(readerText.result as String?);
            });
            return;
          }

          completer.complete(processCertificateBytes(bytes, file.name));
        } catch (_) {
          completer.complete(null);
        }
      });
      reader.onError.listen((e) {
        completer.complete(null);
      });
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
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
