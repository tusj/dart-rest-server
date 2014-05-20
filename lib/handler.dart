library handler;

import 'dart:io';
import 'dart:collection';
import 'package:logging/logging.dart';

// A HTTP request handler which accepts a map containing the 
// value of the path segments who starts with a colon
abstract class HttpRequestHandler {
  handle(HttpRequest r);
}

abstract class HttpRequestParameterHandler {
  handle(HttpRequest r, Map<String, String> parameters);
}

//abstract class RestHandler {
//  void Get(HttpRequest r);
//  void Post(HttpRequest r);
//  void Put(HttpRequest r);
//  void Delete(HttpRequest r);
//  void Head(HttpRequest r);
//  void Trace(HttpRequest r);
//  void Connect(HttpRequest r);
//}
//
//void HttpRequestDelegator(RestHandler h, HttpRequest r) {
//  switch (r.method) {
//    case "GET":
//      h.Get(r);
//      break;
//    case "POST":
//      h.Post(r);
//      break;
//    case "PUT":
//      h.Put(r);
//      break;
//    case "DELETE":
//      h.Delete(r);
//      break;
//    case "HEAD":
//      h.Head(r);
//      break;
//    case "TRACE":
//      h.Trace(r);
//      break;
//    case "CONNECT":
//      h.Connect(r);
//      break;
//    default:
//      throw("Unhandled Http Method: ${r.method}");
//  }
//}


final Logger log = new Logger("TreeHandler");
// Define a root handler
// For all requests not to root, 
class TreeHandler implements HttpRequestHandler {
  static var parameterDelimiter = ":";
  HttpRequestParameterHandler _handler;
  bool _isParameter = false;
  String _parameterName = '';
  bool _hasParameterChild = false;
  bool _isRoot = true;
  TreeHandler _parent = null;
  Map<String,TreeHandler> _children = {};
  TreeHandler([this._handler]);
  
  _handle(HttpRequest r, Queue<String> path, Map<String, String> parameters) {
    if (path.length == 0) {
      if (_handler != null) {
        log.fine("found handler for $path");
        _handler.handle(r, parameters);
        return;
      }
    } else {
      try {
        if (_hasParameterChild) {
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
  

//  TreeHandler _addChild(HttpRequestParameterHandler child, String pathSegment) {
//    var newNode = new TreeHandler(_handler)
//      .._isRoot = false
//      .._parent = this
//      .._parameterName = pathSegment;
//    
//    _hasParameterChild = pathSegment.startsWith(parameterDelimiter);
//    if (_hasParameterChild) {
//      newNode
//        .._isParameter = true
//        .._parameterName = pathSegment.substring(1);
//    }
//    
//    print("adding $pathSegment at $_parameterName which has parameterChild: $_hasParameterChild");
//
//    
//    print("adding ${newNode._parameterName} to children: ${_children.keys.toString()}"); 
//    if (_children.containsKey(newNode._parameterName)) {
//      _children[newNode._parameterName]._handler = newNode._handler;
//    } else if (_hasParameterChild) {
//      throw("Cannot add child $pathSegment to node $_parameterName who already has parameter as child");
//    } else {
//      _children[newNode._parameterName] = newNode;
//    }
//    return _children[pathSegment];
//  }
  
  // If has parameter
  //   if pathSep == childNode
  //     if childNode handler is null
  //       set handler
  // if is parameter
  //   if no children
  //     add to children
  //   if children is one
  //     if child is same as pathSep
  //       if handler is null
  //         set handler
  // else
  //   if not pathSep in children
  //     add to children
  //   else
  //     if child node has handler is null
  //       set handler
  //     else
  //       throw error update handler is set
  TreeHandler _addChild(HttpRequestParameterHandler handler, String pathSep, bool isParam, {bool isFinal}) {
    print("addchild with name $pathSep, is param: $isParam");

    if (_hasParameterChild) {
      var childKey = _children.keys.single;
      var childNode = _children.values.single;
      if (childKey == pathSep) {
        if (childNode._handler == null) {
          if (isFinal) {
            childNode._handler = handler;
            return childNode;
          } else {
            return childNode;
          }
        } else {
          return childNode;
        }
      } else {
        throw("Cannot add child to node which has parameterChild");
        return null;
      }
    }
    if (isParam) {
      if (_children.length == 0) {
        if (isFinal) {
          _children[pathSep] = new TreeHandler(handler)
            .._isParameter = true
            .._isRoot = false
            .._parameterName = pathSep
            .._parent = this;
          return _children[pathSep];
        } else {
          _children[pathSep] = new TreeHandler()
            .._isParameter = true
            .._isRoot = false
            .._parameterName = pathSep
            .._parent = this;
          return _children[pathSep];
        }
      } else if (_children.length == 1) {
        var childKey = _children.keys.single;
        var childValue = _children.values.single;
        if (childKey == pathSep) {
          if (childValue._handler == null) {
            if (isFinal) {
              childValue._handler = handler;
              return childValue;
            } else {
              return childValue;
            }
          } else {
            throw("Cannot set handler which is already set");
          }
        } else {
          throw("Cannot add parameter child when node children are non-empty");
        }
      } else {
        throw("Cannot add parameter child when node children are non-empty");
      }
    } else {
      if (!_children.containsKey(pathSep)) {
        if (isFinal) {
          var newTree = new TreeHandler(handler)
            .._isParameter = isParam
            .._isRoot = false
            .._parameterName = pathSep
            .._parent = this;
          _children[pathSep] = newTree;
          return newTree;
        } else {
          var newTree = new TreeHandler()
            .._isParameter = isParam
            .._isRoot = false
            .._parameterName = pathSep
            .._parent = this;
          _children[pathSep] = newTree;
          return newTree;
        }
      } else {
        var child = _children[pathSep];
        if (child._handler == null) {
          if (isFinal) {
            child._handler = handler;
            return child;
          } else {
            return child;
          }
        } else {
          throw("Set handler while previously set");
        }
      }
    }
    
//    if (_children.containsKey(pathSep)) {
//      print("containsKey $pathSep");
//      var node = _children[pathSep];
//      if (node._handler != null) {
//        throw("Will not override previously set handler at $pathSep");
//      } else {
//        node._handler = handler;
//      }
//    } else if (_hasParameterChild) {
//      throw("Cannot add $pathSep to ${_children.keys.single}");
//    } else if (isParam && _children.length > 0) {
//      throw("Cannot add parameter $pathSep to non-empty children");
//    } else {
//      print("adding new tree");
//      _children[pathSep] = new TreeHandler(handler)
//        .._isParameter = isParam
//        .._parameterName = pathSep
//        .._isRoot = false
//        .._parent = this;
//      _hasParameterChild = true;
//    }
//    return _children[pathSep];
  }
  
  // Adds a handler at path end
  // Creates intermediate nodes as needed
  // If path exists
  //   if handler exists
  //     throw error
  //   else
  //     set handler
  // If child is parameter
  //   do not accept any more children
  
  _add(HttpRequestParameterHandler handler, Queue<String> path) {
    // Init
    var pathSep = path.first;
    bool isParam = pathSep.startsWith(parameterDelimiter);
    pathSep = isParam ? pathSep.substring(1) : pathSep;
    
    print("");
    print("node is $_parameterName");
    print("path is $path");
    print("children are ${_children.keys.toString()}");
    
    // Stop condition
    if (path.length == 1) {
      _addChild(handler, pathSep, isParam, isFinal: true);
      return;
    }
    // Make intermediate
    if (!_children.containsKey(pathSep)) {
      print("making intermediate");
      _addChild(handler, pathSep, isParam, isFinal: false);
    }
    // Recurse
    print("recursing");
    _children[pathSep]._add(handler, path..removeFirst());
  }
//  _add(HttpRequestParameterHandler handler, Queue<String> path) {
//    print("");
//    print("node is $parameterName");
//    print("path is $path");
//    print("children is ${_children.keys.toString()}");
//    var nextSeg = path.removeFirst();
//    if (nextSeg.startsWith(parameterDelimiter)) {
//      nextSeg = nextSeg.substring(1);
//    }
//    if (path.length == 1) {
//      print("nextSeg is $nextSeg");
//      if (_children.containsKey(nextSeg)) {
//        print("children contains $nextSeg");
//        var child = _children[nextSeg];
//        print("child handler is null: ${child.handler == null}");
//        if (child.handler == null) {
//          child.handler = handler;
//          return;
//        } else {
//          throw("Error: overwriting handler on node ${nextSeg}");
//        }
//      }
//      print("_children contains p which is $nextSeg: ${_children.containsKey(nextSeg)}");
//      _addChild(handler, path.single);
//      return;
//    }
//
//    try {
//      _children[nextSeg]
//        .._add(handler, path);
//    } catch(_) {
//      var intermediate = _addChild(null, nextSeg);
//      intermediate._add(handler, path);
//    }
//  }
  
  // Adds a handler for the path specified with / as delimiter and
  // : acts as a path parameter which will be passed to the handler as a map
  add(HttpRequestParameterHandler handler, String path) {
    if(path.startsWith("/")) {
      path = path.substring(1);
    }
    print("");
    print("");
    print("add at $path");
    _add(handler, new Queue<String>.from(path.split("/")));
  }
  
  // Makes a simple page with relative links to the available children
  _showAvailable(HttpRequest r) {
    r.response
      ..statusCode = HttpStatus.NOT_FOUND
      ..write("<html><body><h1>Available resources at \"${_trace()}\"</h1></body>")
      ..writeAll(_children.keys.map((e) => "<a href=\"${this._parameterName}/$e\">$e</a><br>"))
      ..write("</body></html>")
      ..close();
  }
  
  String _trace() {
    var path = new Queue<String>();
    var ptr = this;
    while(!ptr._isRoot) {
      path.addFirst(ptr._parameterName);
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