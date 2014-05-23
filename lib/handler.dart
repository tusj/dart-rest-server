library handler;

import 'dart:io';
import 'package:logging/logging.dart';
import 'dart:collection';

// A HTTP request handler which accepts a map containing the 
// value of the path segments who starts with a colon
typedef handleHttpRequest(HttpRequest r);


abstract class HttpRequestParameterHandler {
  handle(HttpRequest r, Map<String, String> parameters);
}

final Logger log = new Logger("TreeHandler");
// Define a root handler
// For all requests not to root, 
class TreeHandler {
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
        log.fine("found handler for $_parameterName");
        _handler.handle(r, parameters);
        return;
      }
    } else {
      try {
        print("has parameter child: $_hasParameterChild");
        if (_hasParameterChild) {
          parameters[_children.keys.single] = path.removeFirst();
          _children.values.single._handle(r, path, parameters);
        } else {
          _children[path.removeFirst()]._handle(r, path, parameters);
        }
        return;
      } catch (_) {}
    }
    
    _showAvailable(r);
    
  }
  
  // Finds the appropriate handler according to the path requested
  handleHttpRequest(HttpRequest r) {
    var path = new Queue.from(r.requestedUri.pathSegments);
    _handle(r, path, {});
  }
  
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
    log.finer("addchild with name $pathSep, is param: $isParam");

    var addNewTree = () {
      this._hasParameterChild = isParam;
      return _children[pathSep] = new TreeHandler(isFinal ? handler : null)
      .._isParameter = isParam
      .._isRoot = false
      .._parameterName = pathSep
      .._parent = this;
    };
    
    var setHandler = (String errMsg) {
      var childKey = _children.keys.single;
      var child = _children.values.single;
      if (childKey == pathSep) {
        return child.._handler = child._handler == null && isFinal ? handler : null;
      }
      throw(errMsg);
    };
    
    if (_hasParameterChild) {
      return setHandler("Cannot add child to node which has parameterChild");
    }
    if (isParam) {
      if (_children.length == 0) {
        return addNewTree();
      }
      if (_children.length == 1) {
        return setHandler("Cannot set handler which is already set");
      }
      throw("Cannot add parameter child when node children are non-empty");
    }
    
    if (!_children.containsKey(pathSep)) {
      return addNewTree();
    }
    
    var child = _children[pathSep];
    if (child._handler != null) {
      throw("Set handler while previously set");
    }
    return child.._handler = child._handler == null && isFinal ? handler : null;
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
  
  TreeHandler _add(HttpRequestParameterHandler handler, Queue<String> path) {
    // Init
    var pathSep = path.first;
    bool isParam = pathSep.startsWith(parameterDelimiter);
    pathSep = isParam ? pathSep.substring(1) : pathSep;
    
    log.finest("node is $_parameterName");
    log.finest("new node is param: $isParam");
    log.finest("path is $path");
    log.finest("children are ${_children.keys.toString()}");
    
    // Stop condition
    if (path.length == 1) {
      return _addChild(handler, pathSep, isParam, isFinal: true);
    }
    // Make intermediate
    if (!_children.containsKey(pathSep)) {
      log.finest("making intermediate");
      _addChild(handler, pathSep, isParam, isFinal: false);
    }
    // Recurse
    log.finest("recursing");
    return _children[pathSep]._add(handler, path..removeFirst());
  }
  
  // Adds a handler for the path specified with / as delimiter and
  // : acts as a path parameter which will be passed to the handler as a map
  TreeHandler add(HttpRequestParameterHandler handler, String path) {
    if(path.startsWith("/")) {
      path = path.substring(1);
    }
    log.fine("");
    log.fine("add at $path from $_parameterName");
    return _add(handler, new Queue<String>.from(path.split("/")));
  }
  
  // Makes a simple page with relative links to the available children
  _showAvailable(HttpRequest r) {
    var p = (e) => _children[e]._isParameter ? ":" : "";
    r.response
      ..statusCode = HttpStatus.NOT_FOUND
      ..write("<html><body><h1>Available resources at \"${_trace()}\"</h1></body>")
      ..writeAll(_children.keys.map((e) => 
          "<a href=\"$_parameterName/${p(e)}$e\">${p(e)}$e</a><br>"))
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