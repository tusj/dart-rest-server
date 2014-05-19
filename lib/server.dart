import 'dart:io';
import 'dart:async';

final CorsAllowedMethods = 'GET, POST, PUT, DELETE';

void addCorsHeaders(HttpResponse r) {
  r.headers
    ..add('Access-Control-Allow-Origin', '*, ')
    ..add('Access-Control-Allow-Methods', CorsAllowedMethods)
    ..add('Access-Control-Allow-Headers',
        'Origin, X-Requested-With, Content-Type, Accept, Authorization');
}

typedef void HttpRequestHandler(HttpRequest r);


void startserver(HttpRequestHandler h, {int port: 8080}) {
  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port)
    .then((HttpServer server) {
      var cntRequests = 0;

      // Log and add CORS headers
      // Handle OPTIONS Methods
      var requests = server.transform(
        new StreamTransformer.fromHandlers(handleData: (HttpRequest r, sink) {
          print('\n${++cntRequests}');
          print(r.uri.path);
          print(r.method);
          print(r.headers);
          addCorsHeaders(r.response);

          if (r.method == 'OPTIONS') {
            r.response
              ..statusCode = HttpStatus.NO_CONTENT
              ..close();
          }
        })
      );
      
      requests.listen(h);
    },
    onError: (e) => print("server error: $e"));
}
