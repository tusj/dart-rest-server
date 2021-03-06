library server;

import 'package:rest_server/handler.dart';
import 'dart:io';
import 'dart:async';
import 'package:logging/logging.dart';

final CorsAllowedMethods = 'GET, POST, PUT, DELETE';

addCorsHeaders(HttpResponse r) {
  r.headers
    ..add('Access-Control-Allow-Origin', '*, ')
    ..add('Access-Control-Allow-Methods', CorsAllowedMethods)
    ..add('Access-Control-Allow-Headers',
        'Origin, X-Requested-With, Content-Type, Accept, Authorization');
}

final Logger log = new Logger('Server');

Future<StreamSubscription> serve([handleHttpRequest handler, int port = 8080]) {
  return HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port)
    .then((HttpServer server) {
      var cntRequests = 0;
      log.config("starting server on port $port");
      // Log and add CORS headers
      // Handle OPTIONS Methods
      var requests = server.transform(
        new StreamTransformer.fromHandlers(handleData: (HttpRequest r, sink) {
          log.fine('#${++cntRequests}: ${r.uri.path}: ${r.method}');
          addCorsHeaders(r.response);

          if (r.method == 'OPTIONS') {
            r.response
              ..statusCode = HttpStatus.NO_CONTENT
              ..close();
          } else {
            sink.add(r);
          }
        })
      );

      return requests.listen(handler);
    },
    onError: (e) => log.info("server error: $e"));
}
