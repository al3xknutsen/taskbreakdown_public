import 'dart:async';

import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'app_config.dart';
import 'package:provider/provider.dart';
import 'package:taskbreakdown/providers.dart';

import 'speech_to_text_model.dart'; // Add this import
import 'subscription_page.dart'; // Add this import
import 'utils.dart'; // Add this import

class TaskTile extends StatefulWidget {
  final TreeNode node;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onAddSubNode;
  final VoidCallback onDeleteNode;
  final VoidCallback onGenerateSubtree;
  final double hue;
  final ValueChanged<TreeNode> onSelect;
  final TreeViewController? controller;
  final void Function(dynamic) onContentChanged;

  const TaskTile({
    required this.node,
    required this.isSelected,
    required this.onTap,
    required this.onAddSubNode,
    required this.onDeleteNode,
    required this.onGenerateSubtree,
    required this.hue,
    required this.onSelect,
    required this.controller,
    required this.onContentChanged,
    super.key,
  });

  @override
  _TaskTileState createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile>
    with SingleTickerProviderStateMixin {
  bool _isChecked = false;
  late TextEditingController _controller;
  late SpeechToTextModel _speechModel; // Add this line
  final FocusNode _focusNode = FocusNode();
  bool _initialSelectionDone = false;
  Timer? _expandTimer;
  Timer? _stopListeningTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.node.data["content"]);
    _controller.addListener(_onTextChanged);
    _speechModel =
        Provider.of<SpeechToTextModel>(context, listen: false); // Add this line
    _speechModel.addListener(_onSpeechRecognized); // Add this line
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _expandTimer?.cancel();
    _stopListeningTimer?.cancel();
    _speechModel.removeListener(_onSpeechRecognized); // Add this line
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    widget.onContentChanged(_controller.text);
  }

  void _onSpeechRecognized() {
    TreeNode? selectedNode =
        Provider.of<TreeProvider>(context, listen: false).selectedNode;
    if (!_speechModel.isListening &&
        _speechModel.recognizedText.isNotEmpty &&
        widget.node.data["key"] == selectedNode?.data["key"]) {
      setState(() {
        _controller.text = _speechModel.recognizedText;
        widget.onContentChanged(_controller.text);
      });
    }
  }

  Color _getTextColor(int level) {
    return level >= 9 ? Colors.white : Colors.black;
  }

  Color _getIconColor(int level) {
    return level >= 9 ? Colors.white : Colors.black;
  }

  Color _getBorderColor(int level) {
    const double lightness = 0.4;
    return HSLColor.fromAHSL(1.0, widget.hue, 0.6, lightness).toColor();
  }

  TextStyle _getTextStyle(bool isChecked, int level) {
    return TextStyle(
      color: isChecked
          ? const Color.fromARGB(255, 84, 84, 84)
          : _getTextColor(level), // Change text color to grey when checked
      decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
      fontStyle: isChecked ? FontStyle.italic : FontStyle.normal,
      fontWeight: level == 0
          ? FontWeight.bold
          : FontWeight.normal, // Make root node text bold
    );
  }

  void _expandSubtree(TreeNode node) {
    widget.controller?.expandNode(node);
    for (var child in node.children.values) {
      _expandSubtree(child as TreeNode);
    }
  }

  void _handleExpandCollapseTap() {
    if (widget.node.isExpanded && !(_expandTimer?.isActive ?? false)) {
      widget.controller?.collapseNode(widget.node);
    } else {
      if (_expandTimer?.isActive ?? false) {
        _expandTimer?.cancel();
        _expandSubtree(widget.node);
      } else {
        widget.controller?.expandNode(widget.node);
        _expandTimer = Timer(const Duration(milliseconds: 300), () {
          _expandTimer = null;
        });
      }
    }
  }

  void _checkSubtree(TreeNode node, bool isChecked) {
    for (var child in node.children.values) {
      final childNode = child as TreeNode;
      childNode.data["isChecked"] = isChecked;
      _checkSubtree(childNode, isChecked);
    }
  }

  bool _areAllSubnodesChecked(TreeNode node) {
    for (var child in node.children.values) {
      final childNode = child as TreeNode;
      if (childNode.data["isChecked"] != true ||
          !_areAllSubnodesChecked(childNode)) {
        return false;
      }
    }
    return true;
  }

  void _updateParentNodes(TreeNode node) {
    if (node.parent != null) {
      final parentNode = node.parent as TreeNode;
      parentNode.data["isChecked"] = _areAllSubnodesChecked(parentNode);
      _updateParentNodes(parentNode);
    }
  }

  void _uncheckParentNodes(TreeNode? node) {
    while (node != null) {
      node.data["isChecked"] = false;
      node = node.parent as TreeNode?;
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete the task "${widget.node.data["content"]}"? This action cannot be undone!'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                widget.onDeleteNode(); // Perform the deletion
                _updateParentNodes(widget.node);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int level = widget.node.level;
    _isChecked = widget.node.data["isChecked"] == true;
    if (widget.isSelected && !_initialSelectionDone) {
      _focusNode.requestFocus();
      _controller.selection =
          TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      _initialSelectionDone = true;
    }
    return GestureDetector(
      onTap: () {
        widget.onTap();
        widget.onSelect(widget.node);
        _initialSelectionDone = false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: getBackgroundColor(level, widget.hue), // Use utility function
          border: Border(
              top: level == 0
                  ? BorderSide(color: _getBorderColor(level), width: 2.0)
                  : BorderSide.none),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
              leading: Checkbox(
                value: _isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    _isChecked = value ?? false;
                    widget.node.data["isChecked"] = _isChecked;
                    _checkSubtree(widget.node, _isChecked);
                    _updateParentNodes(widget.node);
                    widget.onContentChanged(_controller.text);
                  });
                },
              ),
              title: Row(
                children: [
                  Expanded(
                    child: widget.isSelected
                        ? TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            maxLength: 100, // Enforce max length
                            decoration: const InputDecoration(
                              hintText: 'Task name',
                              counterText: '', // Hide counter text
                            ),
                            style: _getTextStyle(_isChecked, level),
                            onSubmitted: (newValue) {
                              setState(() {
                                widget.node.data["content"] = newValue;
                                widget.onContentChanged(_controller.text);
                              });
                            },
                            onChanged: (value) {
                              setState(() {
                                widget.node.data["content"] = value;
                                widget.onContentChanged(_controller.text);
                              });
                            },
                          )
                        : Text(
                            _controller.text,
                            style: _getTextStyle(_isChecked, level),
                          ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(0),
                    width: 35,
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _showDeleteConfirmationDialog,
                      color: _getIconColor(level),
                    ),
                  ),
                  if (level < 12)
                    Container(
                      padding: const EdgeInsets.all(0),
                      width: 35,
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          widget.onAddSubNode();
                          _uncheckParentNodes(widget.node);
                        },
                        color: _getIconColor(level),
                      ),
                    ),
                  GestureDetector(
                    onTap: _handleExpandCollapseTap,
                    child: Container(
                      padding: const EdgeInsets.only(
                          top: 8, bottom: 8, right: 12), // Expand hitbox area
                      child: Visibility(
                        visible: widget.node.children.isNotEmpty,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: Icon(
                          widget.node.isExpanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                          color: _getIconColor(level),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isSelected)
              Row(
                children: [
                  Expanded(child: Container()),
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () => _speechModel.startListening(context),
                    color: _getIconColor(level),
                  ),
                  if (level < 12)
                    Consumer<TreeProvider>(
                        builder: (context, treeProvider, child) {
                      return IconButton(
                        icon: const Icon(Icons.smart_toy),
                        tooltip: AppConfig.demoMode
                            ? 'Add local sample subtasks (not AI)'
                            : 'Generate subtasks using AI',
                        onPressed: _controller.text.isEmpty
                            ? null
                            : () {
                                if (treeProvider.isPro) {
                                  widget.onGenerateSubtree();
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SubscriptionPage(),
                                    ),
                                  );
                                }
                              },
                        color: _controller.text.isNotEmpty && treeProvider.isPro
                            ? _getIconColor(level)
                            : Colors.grey,
                      );
                    }),
                  Expanded(child: Container()),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
