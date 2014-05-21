import 'package:unittest/unittest.dart';
import 'package:restserver/handler.dart';
import 'package:restserver/server.dart';
import 'dart:async';
//import 'dart:html';

void main() {
//  var settingsResource = new MongoDbResource("user");
  group("TreeHandler", () {
    Future<StreamSubscription> soonToBeServer;
    setUp(() {
      var tree = new TreeHandler()
        ..add(null, "/words/:word")
        ..add(null, "/words")
        ..add(null, "/users")
        ..add(null, "/users/:id")
        ..add(null, "/users/:id/:setting")
        ..add(null, "/translations/:id")
        ..add(null, "/tests/:id");
    
      soonToBeServer = serve(tree);
    });
    tearDown(() {
//      soonToBeServer.then((server) => server.cancel());
    });
    test("Crawl", () {
      // read main page and get all links mentioned in tree...
      //
//      var req = HttpRequest.getString("http://localhost:8080");
//      req.then((onData) => print(onData));
    });
    
  });
}