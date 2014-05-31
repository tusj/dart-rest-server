dart-rest-server
================

Simple tree-based REST-configuration with a tree-based handler

## Usage
import 'package:rest-server/handler.dart';
import 'package:rest-server/server.dart';


void main() {
  // set up the tree
  // at each path segment
  var tree = new TreeHandler()
    ..add(new WelcomeHandler(), "")
    ..add(new userHandler(), "user").add(specificUserHandler, ":id") // each add returns a new tree to allow nesting
    ..add(null, "mail").add(specicMailHandler, ":id")                // can also provide null to indicate no handler
    ..add(new whatNotHandler(), "what/not/handler")                  // can also add intermediate paths
  
  // start the server, which is a convenience method
  // allowing all CORS-headers
  // Not for production!!
  serve(tree.handleHttpRequest, serverPort);
}

## Status
Works nicely

## Todo
- Performance testing
  - node lookup is not efficient
- Add convenience method for same handlers for several path segments
