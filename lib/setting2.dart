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

  static const double itemHeight = 75;
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

  void _showCreateSectionModal() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: CreateSectionModal(
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

          Navigator.of(context).pop(); // Close modal
        },
      ),
    ),
    isDismissible: true,
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
    
    double baseTop =  index * (itemHeight - overlap);

    if (draggingIndex == null || targetIndex == null || draggingIndex == targetIndex) {
      return baseTop;
    }

    if ( index == draggingIndex) {
      return baseTop;
    }

    if (index > draggingIndex! && index <= targetIndex!) {
      return (index - 1) * (itemHeight - overlap);
    } else if (index < draggingIndex! && index >= targetIndex!) {
      return (index + 1) * (itemHeight - overlap);
    }

    return baseTop;
  }

  // New method to move a section up
  void _moveSectionUp(int index) {
    if (index > 0 && !sections[index].isFixed) {
      final targetIndex = index - 1;
      if (!sections[targetIndex].isFixed) { // Only swap if the target is not fixed
        setState(() {
          final section = sections.removeAt(index);
          sections.insert(targetIndex, section);
          _saveSections();
        });
      }
    }
  }

  // New method to move a section down
  void _moveSectionDown(int index) {
    if (index < sections.length - 1 && !sections[index].isFixed) {
      final targetIndex = index + 1;
      if (!sections[targetIndex].isFixed) { // Only swap if the target is not fixed
        setState(() {
          final section = sections.removeAt(index);
          sections.insert(targetIndex, section);
          _saveSections();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     bool shouldShowEmptyState = sections.length == 1 && 
                                sections[0].name == "Complete";
    if (shouldShowEmptyState) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Column(
              children: [
                Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Categories',
                    style: AppTextStyles.header.copyWith(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
                const SizedBox(height: 32),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _showCreateSectionModal,
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
          ),
        );
      }
      
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Categories',
                style: AppTextStyles.header.copyWith(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: SizedBox(
                  height: sections.length * (itemHeight - overlap) + 16, 
                  child: Stack(
                    children: List.generate(sections.length, (index) {
                      final section = sections[index];
                      final isDragging = index == draggingIndex;

                      return AnimatedPositioned(
                        key: ValueKey(section.id),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        top: _getTileTop(index),
                        left: 0,
                        right: 0,
                        child: _buildTile(
                          index,
                          section,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _showCreateSectionModal,
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text(
                  'Create Section',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Additional Settings',
                   style: AppTextStyles.taskItem.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            

            _FiltersBar(
                    selectedFilters: {currentFilter},
                    onFilterToggle: (filter) {
                      setState(() {
                        currentFilter = filter;
                      });
                    },
                  ),

          ],
        )

        ],
      ),
    );
  }

  Widget _buildTile(int index, Section section) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      color: section.color,
      child: Container(
        height: section.isFixed ? 59 : 71, // Adjusted height for fixed items for better consistency
        margin: EdgeInsets.only(bottom: section.isFixed ? 4 : 16),
        padding: const EdgeInsets.only(left: 0, right: 0, top: 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ListTile(
            title: Text(
              section.name,
              style: AppTextStyles.groupTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
             leading: section.isFixed
                ? IconButton(
                        icon: const Icon(Icons.lock, color: Colors.white), // iOS lock icon
                        onPressed: (){},
                      )
                : IconButton(
                        icon: const Icon(CupertinoIcons.chevron_up, color: Colors.white), // iOS up arrow
                        onPressed: index > 0 && !sections[index - 1].isFixed
                            ? () => _moveSectionUp(index)
                            : null,
                      ),
            trailing: section.isFixed
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.chevron_down, color: Colors.white), // iOS down arrow
                        onPressed: index < sections.length - 1 && !sections[index + 1].isFixed && !sections[index].isFixed
                            ? () => _moveSectionDown(index)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white), // iOS delete icon
                        onPressed: () => _deleteSection(index),
                      ),
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
  int selectedIndex = 0;
  final List<String> labels = ['Hide', 'Show'];
final List<IconData> icons = [Icons.visibility_off, Icons.visibility];

  @override
  Widget build(BuildContext context) {
      final isSmallScreen = MediaQuery.of(context).size.width < 340;

    if (isSmallScreen) {
      // 👉 Stack vertically on narrow screens
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _buildExpandChip(), // "Expand All" button
            ),
            const SizedBox(height: 16),
            _buildToggleSegment(), // toggle chips
            
            
          ],
        ),
      );
    } else {
      // 👉 Normal horizontal layout for wider screens
      return Padding(
        padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
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
          final isSelected = widget.selectedFilters.contains(labels[index]);
          return GestureDetector(
            onTap: () {
              widget.onFilterToggle(labels[index]);
            },
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
                    labels[index],
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

  