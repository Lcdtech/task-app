import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'styles.dart';
import '../models/section.dart';
import 'create_section_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<Section> sections = [];
  final TextEditingController _sectionController = TextEditingController();
  Color _currentColor = Colors.red;
  late Box sectionBox;

  static const double itemHeight = 71;
  static const double overlap = 15;

  final uuid = Uuid();
  int? draggingIndex;
  int? targetIndex;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    sectionBox = await Hive.openBox('sections');

    final stored = sectionBox.get('list') ?? [];
    sections = (stored as List)
        .map((e) => Section.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    if (sections.where((s) => s.isFixed).isEmpty) {
      sections.add(Section(
        id: uuid.v4(),
        name: 'Complete',
        color: AppColors.complete,
        isFixed: true,
      ));
      _saveSections();
    }

    setState(() {});
  }

  void _saveSections() {
    sectionBox.put('list', sections.map((s) => s.toMap()).toList());
  }

  void _navigateToCreateSectionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSectionPage(
          onSectionCreated: (newSection) {
            final exists = sections.any((s) =>
                s.name.trim().toLowerCase() ==
                newSection.name.trim().toLowerCase());

            if (exists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('A section with this name already exists.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            setState(() {
              sections.insert(sections.length - 1, newSection);
              _saveSections();
            });
          },
        ),
      ),
    );
  }

  void _deleteSection(int index) {
    if (sections[index].isFixed) return;

    setState(() {
      sections.removeAt(index);
      _saveSections();
    });
  }

  double _getTileTop(int index) {
    double baseTop = index * (itemHeight - overlap);

    if (draggingIndex == null || targetIndex == null || draggingIndex == targetIndex) {
      return baseTop;
    }

    if (index == draggingIndex) {
      return baseTop;
    }

    if (index > draggingIndex! && index <= targetIndex!) {
      return (index - 1) * (itemHeight - overlap);
    } else if (index < draggingIndex! && index >= targetIndex!) {
      return (index + 1) * (itemHeight - overlap);
    }

    return baseTop;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: SizedBox(
                  height: sections.length * 50 + 100,
                  child: Stack(
                    children: List.generate(sections.length, (index) {
                      final section = sections[index];
                      final isDragging = index == draggingIndex;

                      return AnimatedPositioned(
                        key: ValueKey(section.id),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        top: _getTileTop(index),
                        left: 0,
                        right: 0,
                        child: DragTarget<int>(
                          onWillAccept: (fromIndex) {
                            if (fromIndex != null &&
                                fromIndex != index &&
                                !sections[index].isFixed) {
                              if (targetIndex != index) {
                                setState(() {
                                  targetIndex = index;
                                });
                              }
                              return true;
                            }
                            return false;
                          },
                          onLeave: (_) => setState(() => targetIndex = null),
                          onAccept: (fromIndex) {
                            if (sections[fromIndex].isFixed) return;

                            final fixedIndex = sections.lastIndexWhere((s) => s.isFixed);
                            var insertIndex = index;

                            if (insertIndex >= fixedIndex) {
                              insertIndex = fixedIndex - (fromIndex < fixedIndex ? 0 : 1);
                            }

                            setState(() {
                              final moved = sections.removeAt(fromIndex);
                              sections.insert(insertIndex, moved);
                              draggingIndex = null;
                              targetIndex = null;
                              _saveSections();
                            });
                          },
                          builder: (context, candidateData, rejectedData) {
                            final tile = Visibility(
                              visible: !isDragging,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: _buildTile(index, section, draggable: true),
                            );

                            return section.isFixed
                                ? tile
                                : LongPressDraggable<int>(
                                    data: index,
                                    onDragStarted: () => setState(() {
                                      draggingIndex = index;
                                    }),
                                    onDragEnd: (_) => setState(() {
                                      draggingIndex = null;
                                      targetIndex = null;
                                    }),
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: SizedBox(
                                        width: MediaQuery.of(context).size.width - 32,
                                        child: _buildTile(index, section, draggable: true),
                                      ),
                                    ),
                                    child: tile,
                                  );
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _navigateToCreateSectionPage,
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text(
                  'Create Section',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(int index, Section section, {bool draggable = true}) {
    final tile = Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      color: section.color,
      child: Container(
        height: section.isFixed ? 56 : 71,
        margin: EdgeInsets.only(bottom: section.isFixed ? 4 : 16),
        padding: const EdgeInsets.only(left: 8, right: 0, top: 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ListTile(
            title: Text(section.name, style: AppTextStyles.groupTitle,maxLines: 1,
             overflow: TextOverflow.ellipsis),
            trailing: section.isFixed
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () => _deleteSection(index),
                  ),
            leading: section.isFixed
                ? const Icon(Icons.lock, color: Colors.white)
                : draggable
                    ? Draggable<int>(
                        data: index,
                        onDragStarted: () => setState(() => draggingIndex = index),
                        onDraggableCanceled: (_, __) => setState(() {
                          draggingIndex = null;
                          targetIndex = null;
                        }),
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width - 32,
                            child: _buildTile(index, section, draggable: false),
                          ),
                        ),
                        child: const Icon(Icons.drag_indicator, color: Colors.white),
                      )
                    : const Icon(Icons.drag_indicator, color: Colors.white),
          ),
        ),
      ),
    );

    return tile;
  }
}
