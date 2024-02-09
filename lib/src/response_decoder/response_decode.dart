library response_decoder;

import 'dart:async';

import 'package:http/http.dart' show Response;
import 'package:http_parser/http_parser.dart';
import 'package:rest_client/src/exception.dart';
import 'package:rest_client/src/response.dart';
import 'package:rest_client/src/utils/utils.dart';

part 'json_decoder.dart';
part 'html_decoder.dart';
part 'fallback_decoder.dart';

typedef ResponseResolver = FutureOr<RCResponse> Function();

abstract interface class IResponseDecode {
  FutureOr<RCResponse> decoder(Response response);
}

abstract base class ResponseDecodeStrategy implements IResponseDecode {
  const ResponseDecodeStrategy();

  const factory ResponseDecodeStrategy.json() = JsonDecodeStrategy;
  const factory ResponseDecodeStrategy.html() = HtmlDecodeStrategy;
  const factory ResponseDecodeStrategy.fallback() = FallbackDecodeStrategy;

  ///Selects a decoding strategy based on content-type
  static ResponseDecodeStrategy fromHeaders(Map<String, String> headers) {
    final type = headers['content-type'];

    if (type == null) return const ResponseDecodeStrategy.fallback();

    final contentType = MediaType.parse(type);

    if (contentType.subtype == 'json') return const ResponseDecodeStrategy.json();
    if (contentType.subtype == 'html') return const ResponseDecodeStrategy.html();

    return const ResponseDecodeStrategy.fallback();
  }

  FutureOr<RCResponse> decode(Response response) async {
    try {
      return await decoder(response);
    } on NetworkException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        RestClientException(message: 'Error occurred during decoding, ${error.message}'),
        stackTrace,
      );
    }
  }
}
