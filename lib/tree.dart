library tree;

class Tree<T> {
  String identifier;
  T content;
  List<Tree> children = [];
  
  Tree<T> _walk(List<String> path, {bool makeIntermediate: false}) {
    if (path.length == 1) {
      if (path.first == identifier) {
        return this;
      } else {
        throw("Tree: internal error: identifier is $identifier, want ${path.first}");
      }
    } else {
      path.removeAt(0);
      var match = children.where((e) => e.identifier == path.first);
      switch (match.length) {
        case 0:
          if (makeIntermediate) {
            var newTree = new Tree<T>(null, path.first);
            children.add(newTree);
            return newTree._walk(path, makeIntermediate: makeIntermediate);
          }
          return null;
        case 1:
          return match.first._walk(path, makeIntermediate: makeIntermediate);
        default:
          throw("Tree: internal error: several children with same identifier");
      }
    }
  }
  Tree<T> find(List<String> path) {
    return _walk(path);
  }
  
  Tree<T> newAt(List<String> path, T content, {bool makeIntermediate: false}) {
    var t = _walk(path.sublist(0, path.length - 1), makeIntermediate: makeIntermediate);
    var newTree = new Tree(content, path.last);
    t.children.add(newTree);
    return newTree;
  }
  
  Tree(this.content, this.identifier);
}