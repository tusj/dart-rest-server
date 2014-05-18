class Tree<T> {
  String identifier;
  T content;
  List<Tree> children = [];
  
  Tree<T> _Find(List<String> path) {
    print(path.first);
    print(identifier);
    if (path.first == identifier) {
      if (path.length == 1) {
        print("return $this");
        return this;
      } else {
        try {
          path.removeAt(0);
          var child = children.singleWhere((child) => child.identifier == path.first);
          return child.Find(path);
        } catch (_) {}
      }
    }
    return null;
  }
  T Find(List<String> path) {
    var t = _Find(path);
    if (t == null) {
      return null;
    }
    return t.content;
  }
  
  Tree<T> NewAt(List<String> path, T content) {
    var t = _Find(path.sublist(0, path.length - 1));
    if (t == null) {
      return null;
    }
    var newTree = new Tree(content, identifier);
    t.children.add(newTree);
    return newTree;
  }
  Tree(this.content, this.identifier);
}