import 'certificate_picker_stub.dart'
    if (dart.library.html) 'certificate_picker_web.dart'
    if (dart.library.io) 'certificate_picker_mobile.dart';

Future<String?> pickCertificateContent() => pickCertificateFileContent();
