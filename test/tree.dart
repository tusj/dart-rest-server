import 'package:unittest/unittest.dart';
import 'package:restserver/tree.dart';




void main() {
  group('Tree', () {
    var root = "root";
    var endnodes = [
                    "trans/word/language",
                    "trans/word/meaning",
                    "user/settings/oauth/id",
                    "user/settings/oauth/provider",
                    "user/statistics/count/word"
                    ];
    var nodes = [
                 "trans",
                 "trans/word",
                 "user",
                 "user/settings",
                 "user/settings/language",
                 "user/settings/name",
                 "user/settings/oauth",
                 "user/statistics",
                 "user/statistics/count"
                 ];
    nodes.addAll(endnodes);
    nodes.sort();
    Tree<String> tree;
    
    test('Tree', () {
      tree = new Tree<String>("$root content", root);
      expect(tree.identifier, equals(root));
    });
    
    test('newAt', () {
      nodes.forEach((e) {
        var path = e.split("/");
        expect(tree.newAt([root]..addAll(path), "content ${path.last}").content,
            equals("content ${path.last}"));
      });
    });
    
    test('find without making intermediate', () {
      nodes.forEach((e) {
        var path = e.split("/");
        expect(tree.find([root]..addAll(path)).content, equals("content ${path.last}"));
      });
    });
    
    test("find with making intermediate", () {
      var tree = new Tree<String>("$root content", root);
      endnodes.forEach((e) {
        var path = e.split("/");
        tree.newAt([root]..addAll(path), "content ${path.last}", makeIntermediate: true);
      });
      endnodes.forEach((e) {
        var path = e.split("/");
        expect(tree.find([root]..addAll(path)).content, equals("content ${path.last}"));
      });
    });
  });
}