import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskbreakdown/banner.dart';
import 'package:taskbreakdown/providers.dart';
import 'package:uuid/uuid.dart';

import 'settings_page.dart';
import 'speech_to_text_model.dart'; // Add this import
import 'task_tile.dart';
import 'utils.dart'; // Add this import

class SimpleTreeView extends StatefulWidget {
  const SimpleTreeView({super.key});

  @override
  _SimpleTreeViewState createState() => _SimpleTreeViewState();
}

class _SimpleTreeViewState extends State<SimpleTreeView> {
  // Remove the _controllers state
  final Uuid _uuid = const Uuid();
  String _currentRootTitle = "Task 1";
  int _taskCounter = 1;
  int _subtaskCounter = 1;
  final double _treePadding = 16.0;
  String? _currentRootKey;
  OverlayEntry? _loadingOverlayEntry;
  late SpeechToTextModel _speechModel; // Add this line
  late TreeProvider _treeProvider; // Add this line

  @override
  void initState() {
    super.initState();
    _speechModel =
        Provider.of<SpeechToTextModel>(context, listen: false); // Add this line
    _treeProvider =
        Provider.of<TreeProvider>(context, listen: false); // Add this line
    _treeProvider.loadTrees(); // Use loadTrees from TreeProvider
  }

  void _onTapOutside() {
    _treeProvider.setSelectedNode(null); // Update this line
  }

  void _onTapNode(TreeNode node) {
    _treeProvider.setSelectedNode(node); // Update this line
  }

  void _addSubNode(TreeNode node) {
    if (node.level < 12) {
      String newKey = _uuid.v4();
      setState(() {
        TreeNode newNode = TreeNode(key: newKey, data: {
          "key": newKey,
          "content": "Subtask ${_subtaskCounter++}",
          "isChecked": false,
        }); // Ensure data is Map<String, String>
        node.add(newNode);
        _treeProvider
            .setSelectedNode(newNode); // Automatically select the new subtask
        _treeProvider.saveTrees(); // Use saveTrees from TreeProvider
        _uncheckParentNodes(node); // Uncheck all parent nodes
      });
    }
  }

  void _addSiblingNode(TreeNode node) {
    if (node.level < 12) {
      String newKey = _uuid.v4();
      setState(() {
        TreeNode newNode = TreeNode(key: newKey, data: {
          "key": newKey,
          "content": "Subtask ${_subtaskCounter++}",
          "isChecked": false,
        }); // Ensure data is Map<String, String>
        node.parent?.add(newNode);
        _treeProvider
            .setSelectedNode(newNode); // Automatically select the new subtask
        _treeProvider.saveTrees(); // Use saveTrees from TreeProvider
        _uncheckParentNodes(
            node.parent as TreeNode<dynamic>?); // Uncheck all parent nodes
      });
    }
  }

  void _uncheckParentNodes(TreeNode? node) {
    while (node != null) {
      node.data["isChecked"] = false;
      node = node.parent as TreeNode?;
    }
  }

  void _deleteNode(TreeNode node) {
    debugPrint(node.parent.toString());
    if (node.parent == null) {
      _treeProvider.removeTree(node); // Use removeTree from TreeProvider
    } else {
      node.parent?.remove(node);
    }

    _treeProvider.saveTrees(); // Use saveTrees from TreeProvider
  }

  void _addNewTree() {
    _treeProvider.addNewTree();
    _treeProvider.setSelectedNode(_treeProvider.trees.last); // Update this line

    // Automatically start speech-to-text if the setting is enabled
    _startSpeechToTextIfEnabled();
  }

  Future<void> _startSpeechToTextIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final autoStartSpeechToText =
        prefs.getBool('autoStartSpeechToText') ?? false;
    if (autoStartSpeechToText && _treeProvider.selectedNode != null) {
      _speechModel.startListening(context);
      _speechModel.addListener(() async {
        if (!_speechModel.isListening &&
            _speechModel.recognizedText.isNotEmpty) {
          setState(() {
            _treeProvider.selectedNode!.data["content"] =
                _speechModel.recognizedText;
            _treeProvider.saveTrees();
          });
        }
      });
    }
  }

  void _updateCurrentRootTitle(double offset) {
    if (_treeProvider.trees.isEmpty) return; // Add this check

    int index = 0;
    double cumulativeHeight = 0.0;
    for (int i = 0; i < _treeProvider.trees.length; i++) {
      cumulativeHeight += _calculateTreeHeight(_treeProvider.trees[i]);
      if (cumulativeHeight > offset) {
        index = i;
        break;
      }
    }
    setState(() {
      _currentRootTitle = _treeProvider.trees[index].data["content"];
      _currentRootKey = _treeProvider.trees[index].key;
    });
  }

  double _calculateTreeHeight(TreeNode tree) {
    // Approximate height calculation for each tree
    double height = 56.0; // Base height for the root node
    height += _calculateSubtreeHeight(tree);
    return height + 2 + _treePadding; // 2 for the border, + padding
  }

  double _calculateSubtreeHeight(TreeNode node) {
    double height = 0.0;
    if (node.isExpanded) {
      for (var child in node.children.values) {
        height += 56.0; // Height for each child node
        if (child.children.isNotEmpty) {
          height += _calculateSubtreeHeight(child as TreeNode<dynamic>);
        }
      }
    }
    return height;
  }

  void _unselectAllNodes() {
    _treeProvider.setSelectedNode(null); // Update this line
  }

  void _onContentChanged(TreeNode node, String newContent) {
    setState(() {
      node.data["content"] = newContent;
      if (_currentRootKey == node.key) {
        _currentRootTitle = newContent;
      }
      _treeProvider.saveTrees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            onTap: _unselectAllNodes,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _unselectAllNodes,
                      child: Text(
                        _currentRootTitle,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsPage()),
                      );
                      /* _treeProvider
                          .loadTrees(); */ // Reload trees when returning from settings
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _onTapOutside,
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollUpdateNotification) {
                    _updateCurrentRootTitle(scrollNotification.metrics.pixels);
                  }
                  return true;
                },
                child: Consumer<TreeProvider>(
                  builder: (context, treeProvider, child) {
                    return ListView.builder(
                      key: ValueKey(treeProvider.trees.length),
                      itemCount: treeProvider.trees.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: _treePadding),
                          child: TreeView.simple(
                            shrinkWrap: true,
                            onTreeReady: (controller) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  treeProvider.controllers[index] =
                                      controller; // Use controllers from TreeProvider
                                });
                              });
                            },
                            indentation:
                                const Indentation(width: 5, thickness: 0),
                            tree: treeProvider.trees[index],
                            builder: (context, node) {
                              return Column(
                                children: [
                                  TaskTile(
                                    node: node,
                                    isSelected:
                                        treeProvider.selectedNode?.key ==
                                                node.key &&
                                            treeProvider.selectedNode
                                                    ?.data["key"] ==
                                                node.data[
                                                    "key"], // Update this line
                                    onTap: () => _onTapNode(node),
                                    onAddSubNode: () => _addSubNode(node),
                                    onDeleteNode: () => _deleteNode(node),
                                    onGenerateSubtree: () {
                                      treeProvider.generateSubtree(
                                          node, node.data["content"], context);
                                    },
                                    hue: treeProvider.hues[
                                        index], // Use hues from TreeProvider
                                    onSelect: (selectedNode) {
                                      treeProvider.setSelectedNode(
                                          selectedNode); // Update this line
                                    },
                                    controller: treeProvider.controllers[
                                        index], // Use controllers from TreeProvider
                                    onContentChanged: (newContent) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        _onContentChanged(node, newContent);
                                      });
                                    },
                                  ),
                                  if (node.level > 0 &&
                                      node.parent != null &&
                                      node.parent!.children.isNotEmpty &&
                                      node.parent!.children.values.last == node)
                                    Card(
                                      elevation: 0,
                                      margin: EdgeInsets.zero, // Remove margins
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius
                                            .zero, // Remove rounding
                                      ),
                                      color: getBackgroundColor(
                                          node.level, treeProvider.hues[index]),
                                      child: InkWell(
                                        onTap: () => _addSiblingNode(node),
                                        child: const SizedBox(
                                          height: 56.0,
                                          child: Center(
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                            expansionIndicatorBuilder: (context, node) =>
                                ChevronIndicator.rightDown(
                              tree: node,
                              color: Colors.transparent,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
      bottomNavigationBar: GestureDetector(
        onTap: _unselectAllNodes,
        child: BottomAppBar(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _unselectAllNodes,
                child: Container(
                  color: Colors.transparent,
                  height: kBottomNavigationBarHeight,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: "add",
                    onPressed: () {
                      _unselectAllNodes();
                      _addNewTree();
                    },
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
