import 'package:domain/model/failure/failures.dart';

import '../consts/error_messages.dart';
import '../consts/http_constants.dart';
import '../consts/receipt_constants.dart';
import 'content_type_resolver.dart';

class ContentTypeResolverImpl implements ContentTypeResolver {
  @override
  String resolveContentType(String extension) {
    switch (extension.toLowerCase()) {
      case ReceiptConstants.jpgExtension:
      case ReceiptConstants.jpegExtension:
        return HttpConstants.contentTypeJpeg;
      case ReceiptConstants.pngExtension:
        return HttpConstants.contentTypePng;
      case ReceiptConstants.pdfExtension:
        return HttpConstants.contentTypePdf;
      default:
        throw ValidationFailure([
          {'msg': ErrorMessages.unsupportedFileType}
        ]);
    }
  }
}
