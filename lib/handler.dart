library handler;

import 'dart:io';
import 'dart:collection';

// A HTTP request handler which accepts a map containing the 
// value of the path segments who starts with a colon
abstract class HttpRequestHandler {
  handle(HttpRequest r);
}

abstract class HttpRequestParameterHandler {
  handle(HttpRequest r, Map<String, String> parameters);
}

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



// Define a root handler
// For all requests not to root, 
class TreeHandler implements HttpRequestHandler {
  static var parameterDelimiter = ":";
  HttpRequestParameterHandler handler;
  bool isParameter = false;
  String parameterName = '';
  bool hasParameterChild = false;
  bool isRoot = true;
  TreeHandler _parent = null;
  Map<String,TreeHandler> _children = {};
  TreeHandler([this.handler]);
  
  _handle(HttpRequest r, Queue<String> path, Map<String, String> parameters) {
    if (path.length == 0) {
      if (handler != null) {
        handler.handle(r, parameters);
      }
    } else {
      try {
        if (hasParameterChild) {
          parameters[_children.keys.single] = path.removeFirst();
          _children.values.single._handle(r, path, parameters);
        } else {
          _children[path.removeFirst()]._handle(r, path, parameters);
        }
        return;
      } catch (err) {
        print(err);
      }
    }
    _showAvailable(r);
    
  }
  
  // Finds the appropriate handler according to the path requested
  handle(HttpRequest r) {
    var path = new Queue.from(r.requestedUri.pathSegments);
    _handle(r, path, {});
  }
  
  // Adds a child and checks if it is a parameter
  // Sets hasParameterChild accordingly
  TreeHandler _addChild(HttpRequestParameterHandler child, String pathSegment) {
    if (hasParameterChild) {
      throw("Cannot add child to node who already has parameter as child");
    }
    var newNode = new TreeHandler(handler)
      ..isRoot = false
      .._parent = this
      ..parameterName = pathSegment;
    
    hasParameterChild = pathSegment.startsWith(parameterDelimiter);
    if (hasParameterChild) {
      newNode
        ..isParameter = true
        ..parameterName = pathSegment.substring(1);
    }
    
    
    _children[newNode.parameterName] = newNode;
    return _children[pathSegment];
  }
  
  // Adds a handler according to path, and creates
  // intermediate nodes as needed
  _add(HttpRequestParameterHandler handler, Queue<String> path) {
    if (path.length == 1) {
      _addChild(handler, path.single);
      return;
    }
    var nextSeg = path.removeFirst();
    try {
      _children[nextSeg]
        .._add(handler, path);
    } catch(_) {
      var intermediate = _addChild(null, nextSeg);
      intermediate._add(handler, path);
    }
  }
  
  // Adds a handler for the path specified with / as delimiter and
  // : acts as a path parameter which will be passed to the handler as a map
  add(HttpRequestParameterHandler handler, String path) {
    if(path.startsWith("/")) {
      path = path.substring(1);
    }
    _add(handler, new Queue<String>.from(path.split("/")));
  }
  
  // Makes a simple page with relative links to the available children
  _showAvailable(HttpRequest r) {
    r.response
      ..statusCode = HttpStatus.NOT_FOUND
      ..write("<html><body><h1>The resource \"${r.requestedUri.path}\" does not exist</h1>")
      ..write("<h2>Available resources at \"${_trace()}\"</h2>")
      ..writeAll(_children.keys.map((e) => "<a href=\"${this.parameterName}/$e\">$e</a><br>"))
      ..write("</body></html>")
      ..close();
  }
  
  String _trace() {
    var path = new Queue<String>();
    var ptr = this;
    while(!ptr.isRoot) {
      path.addFirst(ptr.parameterName);
      ptr = ptr._parent;
    }
    if (path.length == 1) {
      return "/" + path.first;
    }
    if (path.length == 0) {
      return "/";
    }
    return "/" + path.reduce((a, b) => a + "/" + b);
  }

  _notFound(HttpRequest r) {
    r.response
      ..statusCode = HttpStatus.NOT_FOUND
      ..write("<html><body><h1>The resource \"${r.requestedUri.path}\" does not exist</h1></body></html>")
      ..close();
  }

}