library server;

import 'dart:io';
import 'dart:async';
import 'package:restserver/handler.dart';
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

serve(HttpRequestHandler h, {int port: 8080}) {
  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port)
    .then((HttpServer server) {
      var cntRequests = 0;
      log.config("starting server on port $port");
      // Log and add CORS headers
      // Handle OPTIONS Methods
      var requests = server.transform(
        new StreamTransformer.fromHandlers(handleData: (HttpRequest r, sink) {
          log.fine('\n${++cntRequests}');
          log.fine(r.uri.path);
          log.fine(r.method);
          log.fine(r.headers.toString());
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
      
      requests.listen(h.handle);
    },
    onError: (e) => log.info("server error: $e"));
}
