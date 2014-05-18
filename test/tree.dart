import 'package:unittest/unittest.dart';
import 'package:RestServer/tree.dart';




void main() {
  group('Tree', () {
    var nodes = [
                 "user",
                 "user/settings",
                 "user/statistics",
                 "trans",
                 "trans/word"
                 ];
    nodes.sort();
    Tree<String> tree;
    test('Tree', () {
      tree = new Tree<String>("root content", "root");
      expect(tree.identifier, equals("root"));
    });
    test('NewAt', () {
      nodes.forEach((e) {
        var path = e.split("/");
        tree.NewAt(["root"]..addAll(path), "content ${path.last}");
      });
    });
  });
}