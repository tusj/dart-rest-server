library handler;

import 'dart:io';

typedef void HttpRequestHandler(HttpRequest r);

abstract class RestHandler {
  void Get(HttpRequest r);
  void Post(HttpRequest r);
  void Put(HttpRequest r);
  void Delete(HttpRequest r);
  void Head(HttpRequest r);
}

void HttpRequestDelegator(RestHandler h, HttpRequest r) {
  switch (r.method) {
    case "GET":
      h.Get(r);
      break;
    case "POST":
      h.Post(r);
      break;
    case "PUT":
      h.Put(r);
      break;
    case "DELETE":
      h.Delete(r);
      break;
    case "HEAD":
      h.Head(r);
      break;
    default:
      throw("Unhandled Http Method: ${r.method}");
  }
}

HttpRequestHandler MakeHttpRequestHandler(RestHandler h) {
  return (HttpRequest r) => HttpRequestDelegator(h, r);
}
class MongoHandler implements RestHandler {
  String res;
  void Get(HttpRequest r) {
    print('GET');

    r.response
      ..write(res)
      ..close();
  }
  void Post(HttpRequest r) {
    print('Post');

    var newres = new StringBuffer();
    r.listen((List<int> data) => 
        newres.write(new String.fromCharCodes(data)),
        onError: (error) {
          r.response
            ..write(error)
            ..statusCode = HttpStatus.INTERNAL_SERVER_ERROR
            ..close();
        },
        onDone: () {
          res = newres;
          r.response
            ..close();
        });
  }
  void Put(HttpRequest r) => Post(r);
  void Delete(HttpRequest r) {
    print('Delete');

    res = "";
  }
  void Head(HttpRequest r) {
    print('Head');

    r.response
     ..write("yeah")
     ..close();
  }
}