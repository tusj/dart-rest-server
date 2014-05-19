library handler;

import 'dart:io';
import 'package:path/path.dart';

typedef void HttpRequestHandler(HttpRequest r);

abstract class RestHandler {
  void Get(HttpRequest r);
  void Post(HttpRequest r);
  void Put(HttpRequest r);
  void Delete(HttpRequest r);
  void Head(HttpRequest r);
  void Trace(HttpRequest r);
  void Connect(HttpRequest r);
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
    case "TRACE":
      h.Trace(r);
      break;
    case "CONNECT":
      h.Connect(r);
      break;
    default:
      throw("Unhandled Http Method: ${r.method}");
  }
}

HttpRequestHandler MakeHttpRequestHandler(RestHandler h) {
  return (HttpRequest r) => HttpRequestDelegator(h, r);
}
class MongoHandler implements RestHandler {
  var res;
  void Get(HttpRequest r) {
    print('GET');
    r.response
      ..write(res)
      ..close();
  }
  void _getData(HttpRequest r, Function onError, Function onDone) {
    var newres = new StringBuffer();
    r.listen((List<int> data) => 
        newres.write(new String.fromCharCodes(data)),
        onError: (error) {
          onError(error);
        },
        onDone: () {
          onDone(newres.toString());
        });
  }
  void Post(HttpRequest r) {
    if (!(res is List)) {
      r.response
          ..statusCode = HttpStatus.METHOD_NOT_ALLOWED
          ..close();
      return;
    }
    _getData(r, () {
        r.response
          ..statusCode = HttpStatus.INTERNAL_SERVER_ERROR
          ..close();
      },
      (data) {
        res.add(data);
        r.response
          ..statusCode = HttpStatus.CREATED
          ..headers.add("Location", join(r.requestedUri.path, res.length - 1))
          ..close();
    });
  }
  void Put(HttpRequest r) {
    if (res is Iterable) {
      r.response
        ..statusCode = HttpStatus.METHOD_NOT_ALLOWED
        ..close();
      return;
    }
    
    _getData(r, () {
        r.response
          ..statusCode = HttpStatus.INTERNAL_SERVER_ERROR
          ..close();
      },
      (data) {
        if (res == null) {
          r.response.statusCode = HttpStatus.CREATED;
        }
        res = data;
        r.response.close();
      }
    );
  }
  void Delete(HttpRequest r) {
    res = null;
    r.response.close();
  }
  void Head(HttpRequest r) {
    r.response.close();
  }
  
  void Trace(HttpRequest r) {
    r.response.close();
  }
  
  void Connect(HttpRequest r) {
    r.response.close();
  }
}