import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'styles.dart';
import '../models/section.dart';
import 'create_section_page.dart';
import 'package:flutter/cupertino.dart';

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
  String currentFilter = 'Hide';
  final uuid = Uuid();

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

    // Ensure the "Complete" section is always present and at the end
    if (sections.where((s) => s.name == 'Completed').isEmpty) {
      sections.add(Section(
        id: uuid.v4(),
        name: 'Completed',
        color: AppColors.complete,
        isFixed: true,
      ));
      _saveSections();
    } else {
      // Ensure 'Complete' is always the last fixed item if it exists
      final completeSectionIndex =
          sections.indexWhere((s) => s.name == 'Completed');
      if (completeSectionIndex != -1 &&
          completeSectionIndex != sections.length - 1) {
        final completeSection = sections.removeAt(completeSectionIndex);
        sections.add(completeSection);
        _saveSections();
      }
    }

    final completedSection = sections.firstWhere(
      (s) => s.name == 'Completed',
    );
    currentFilter = completedSection.isFixed ? 'Show' : 'Hide';

    setState(() {});
  }

  void _saveSections() {
    sectionBox.put('list', sections.map((s) => s.toMap()).toList());
  }

 void _showCreateSectionModal() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalContext) {
      String? errorText;
      
      return StatefulBuilder(
        builder: (context, modalSetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: CreateSectionModal(
              errorText: errorText,
              onError: (msg) => modalSetState(() => errorText = msg),
              onSectionCreated: (newSection) {
                final exists = sections.any((s) => 
                    s.name.trim().toLowerCase() == 
                    newSection.name.trim().toLowerCase());
                
                if (exists) {
                  modalSetState(() {
                    errorText = "Category with this name already exists";
                  });
                  return;
                }
                
                // Only close the modal if section is valid
                Navigator.of(modalContext).pop();
                
                // Update main state
                if (mounted) {
                  setState(() {
                    sections.insert(sections.length - 1, newSection);
                    _saveSections();
                  });
                }
              },
            ),
          );
        },
      );
    },
  );
}
  
  

  // void _deleteSection(int index) {
  //   if (sections[index].isFixed) return;

  //   setState(() {
  //     sections.removeAt(index);
  //     _saveSections();
  //   });
  // }

  void _deleteSection(int index) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.only(left: 8,right:8, top: 16,bottom:0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // White Modal Card with content
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.only(left: 0,right:0, top: 0,bottom:0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Image.asset(
                            'assets/images/delete.png',
                            width: 154,
                            height: 154,
                          ),

                

                // Title
                const Text(
                  'Delete this Category?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Padding(
                padding: EdgeInsets.symmetric(horizontal:20), // You can adjust this value
                child: Text(
                  "Once deleted, you'll no longer see this category & it's tasks",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

                const SizedBox(height: 24),

              
               // Yes, Delete Button (flat with black top border)
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.black12, width: 1), // ✅ thin top border
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical:10),
                  child: TextButton(
                    onPressed: () {
                       if (sections[index].isFixed) return;

                        setState(() {
                          sections.removeAt(index);
                          _saveSections();
                        });
                       Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.red,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    child: const Text('Yes, Delete'),
                  ),
                ),
              ),
              

              ],
            ),
          ),

          const SizedBox(height: 8),

          // Cancel button below with transparent background between
                    SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.white, // ✅ Force background color here
              borderRadius: BorderRadius.circular(12),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: const Text(
                  'No, Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),



          const SizedBox(height: 8), // Space from bottom
        ],
      ),
    ),
  );
}

  void _onReorder(int oldIndex, int newIndex) {
    // Get only the reorderable sections
    final reorderableSections =
        sections.where((s) => s.name != "Completed").toList();

    // Adjust indices for the reorderable list
    final actualOldIndex = sections.indexOf(reorderableSections[oldIndex]);

    // Calculate the actual new index in the full list
    int actualNewIndex;
    if (newIndex >= reorderableSections.length) {
      // Dragged to the end of reorderable sections
      actualNewIndex = sections.lastIndexWhere((s) => s.name == "Completed");
    } else {
      actualNewIndex = sections.indexOf(reorderableSections[newIndex]);
      if (oldIndex < newIndex) {
        // If moving down, the target index shifts by one less because an item is removed before insertion
        actualNewIndex -= 1;
      }
    }

    setState(() {
      final Section section = sections.removeAt(actualOldIndex);
      sections.insert(actualNewIndex, section);
      _saveSections();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter out the "Complete" section for display in the ReorderableListView
    final displaySections =
        sections.where((s) => s.name != "Completed").toList();

    bool shouldShowEmptyState =
        displaySections.isEmpty; // Check if there are no user-created sections

    if (shouldShowEmptyState) {
      return Scaffold(
        //appBar: AppBar(title: const Text('Settings')),
        //backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12,vertical:12),
            child: Row(
                children: [
                 
                  Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 0.3),
                  ),
                  child: IconButton(
                        //  icon: const Icon(Icons.arrow_back, color: Colors.white),
                          icon: const Icon(CupertinoIcons.back, color: Colors.black), 
                          onPressed: () => Navigator.pop(context),
                        ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Setting',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                 
                    
                   
                ],
              )

          ),
              // Align(
              //   alignment: Alignment.centerLeft,
              //   child: Padding(
              //     padding: const EdgeInsets.symmetric(horizontal: 16),
              //     child: Text(
              //       'Categories',
              //       style: AppTextStyles.header.copyWith(
              //         color: Colors.black,
              //         fontSize: 16,
              //         fontWeight: FontWeight.w600,
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 46),
              Image.asset(
                'assets/images/notasks.png',
                width: 154,
                height: 154,
              ),
              const SizedBox(height: 20),
              Text(
                'No Categories Created Yet',
                style: AppTextStyles.header.copyWith(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _showCreateSectionModal,
                    icon: const Icon(Icons.add,size:20, color: Colors.black),
                    label: const Text(
                      'Create Category',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
                children: [
                 
                  Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 0.3),
                  ),
                  child: IconButton(
                        //  icon: const Icon(Icons.arrow_back, color: Colors.white),
                          icon: const Icon(CupertinoIcons.back, color: Colors.black), 
                          onPressed: () => Navigator.pop(context),
                        ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Setting',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                 
                    
                   
                ],
              )

          ),
          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 12),
          //     child: Text(
          //       'Categories',
          //       style: AppTextStyles.header.copyWith(
          //         color: Colors.black,
          //         fontSize: 16,
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //   ),
          // ),
          // Height calculated based on `displaySections`
          const SizedBox(height: 12),
          SizedBox(
            height: (48.0 * displaySections.length) +
                (displaySections.isNotEmpty ? 8.0 * 2 : 0),
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: displaySections.length,
              itemBuilder: (BuildContext context, int index) {
                final section = displaySections[index]; // Use displaySections
                return _buildTile(index, section);
              },
              onReorder: _onReorder,
              buildDefaultDragHandles: false,
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) {
                return Material(
                  elevation: 0,
                  color: Colors.transparent,
                  child: child,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _showCreateSectionModal,
                icon: const Icon(Icons.add,size:20, color: Colors.black),
                label: const Text(
                  'Create Category',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
          Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12,vertical:12),
                  child: Container(
                    height: 0.2,
                    color: Colors.black,
                  ),
                ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 12, right: 12, top: 16, bottom: 4),
                  child: Text(
                    'Additional Settings',
                    style: AppTextStyles.taskItem.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _FiltersBar(
                selectedFilters: {currentFilter},
                onFilterToggle: (filter) {
                  setState(() {
                    currentFilter = filter; // update live

                    final index =
                        sections.indexWhere((s) => s.name == 'Completed');
                    if (index != -1) {
                      final original = sections[index];
                      sections[index] = Section(
                        id: original.id,
                        name: original.name,
                        color: original.color,
                        tasks: original.tasks,
                        isFixed: filter == 'Show',
                      );
                      _saveSections();
                    }
                  });
                },
              ),
            ],
          )
        ],
      ),
      ),
    );
  }

  Widget _buildTile(int index, Section section) {
  return Material(
    key: ValueKey(section.id),
    elevation: 4,
    borderRadius: BorderRadius.circular(20),
    color: section.color,
    child: Container(
      height: 48,
      child: Center(  // This centers everything in the tile
        child: ReorderableDragStartListener(
          index: index,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,  // Centers the row contents
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.drag_indicator, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.name,
                  style: AppTextStyles.groupTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  //textAlign: TextAlign.center,  // Centers the text
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => _deleteSection(sections.indexOf(section)),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _FiltersBar extends StatefulWidget {
  final Set<String> selectedFilters;
  final void Function(String) onFilterToggle;

  const _FiltersBar({
    Key? key,
    required this.selectedFilters,
    required this.onFilterToggle,
  }) : super(key: key);

  @override
  State<_FiltersBar> createState() => __FiltersBarState();
}

class __FiltersBarState extends State<_FiltersBar> {
  final List<String> labels = ['Hide', 'Show'];
  final List<IconData> icons = [Icons.visibility_off, Icons.visibility];

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 340;

    if (isSmallScreen) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _buildExpandChip(),
            ),
            const SizedBox(height: 16),
            _buildToggleSegment(),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
        child: Row(
          children: [
            _buildExpandChip(),
            const Spacer(),
            _buildToggleSegment(),
          ],
        ),
      );
    }
  }

  Widget _buildToggleSegment() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: List.generate(labels.length, (index) {
          final label = labels[index];
          final isSelected = widget.selectedFilters.contains(label);
          return GestureDetector(
            onTap: () => widget.onFilterToggle(label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    icons[index],
                    size: 16,
                    color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: AppTextStyles.chipText.copyWith(
                      color: isSelected ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildExpandChip() {
    return Text(
      'Completed List',
      style: AppTextStyles.header.copyWith(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}