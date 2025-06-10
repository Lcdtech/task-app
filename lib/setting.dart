import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart'; // Add this line
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

  static const double itemHeight = 50;
  static const double overlap = 2;

  final uuid = Uuid(); // Unique ID generator

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

    // Ensure "Complete" section exists
    if (sections.where((s) => s.isFixed).isEmpty) {
      sections.add(Section(
        id: uuid.v4(), // Assign unique ID
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
              s.name.trim().toLowerCase() == newSection.name.trim().toLowerCase());

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



  void _onReorder(int oldIndex, int newIndex) {
    if (sections[oldIndex].isFixed) return;
    if (newIndex >= sections.length - 1) {
      newIndex = sections.length - 1;
    }

    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = sections.removeAt(oldIndex);
      sections.insert(newIndex, item);
      _saveSections();
    });
  }

  void _deleteSection(int index) {
    if (sections[index].isFixed) return;
    setState(() {
      sections.removeAt(index);
      _saveSections();
    });
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
              child: ReorderableListView.builder(
                itemCount: sections.length,
                onReorder: _onReorder,
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.only(bottom: 100), // leave room for overlap
                proxyDecorator: (child, index, animation) {
                  return Material(
                    color: Colors.transparent,
                    child: Transform.translate(
                      offset: Offset(0, 2),
                      child: child,
                    ),
                  );
                },
                itemBuilder: (context, index) {
                final section = sections[index];
                final isDraggable = !section.isFixed;

                return Transform.translate(
                  key: ValueKey(section.id),
                  offset: Offset(0, index * -25), // Keep your overlapping logic
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Background tile
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(20),
                        color: section.color,
                        child: Container(
                          height: 60,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.only(left: 56, right: 16), // leave space for drag icon
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ListTile(
                              title: Text(
                                section.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: section.isFixed || index == sections.length - 1
                                  ? const SizedBox.shrink()
                                  : IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.white),
                                      onPressed: () => _deleteSection(index),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // Floating drag/lock icon (z-index on top)
                      Positioned(
                        left: 12,
                        top: 14,
                        child: section.isFixed
                            ? const Icon(Icons.lock, color: Colors.white)
                            : ReorderableDragStartListener(
                                index: index,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black26,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.drag_indicator, color: Colors.white),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              }

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
              label: const Text('Create Section', style: TextStyle(color: Colors.black)),
            ),
            ),
          ),
        ],
      ),
    );
  }
}
