import 'package:animated_tree_view/animated_tree_view.dart';

extension TreeNodeJson on TreeNode {
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'children':
          children.values.map((child) => (child as TreeNode).toJson()).toList(),
    };
  }

  static TreeNode fromJson(Map<String, dynamic> json) {
    final node = TreeNode(
      key: json['key'],
      data: json['data'],
    );
    for (var childJson in json['children']) {
      node.add(fromJson(childJson));
    }
    return node;
  }
}
