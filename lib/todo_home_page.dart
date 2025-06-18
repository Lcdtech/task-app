import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'styles.dart';
import 'setting.dart';
import 'add_task_page.dart';
import '../models/section.dart';

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({Key? key}) : super(key: key);

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  late Box sectionBox;
  final Map<String, bool> _expanded = {};
  bool _allExpanded = false;
  String currentFilter = 'Color';

   @override
  void initState() {
    super.initState();
    sectionBox = Hive.box('sections');
  }

  List<Section> getAllSections() {
    final rawList = sectionBox.get('list');
    if (rawList == null || rawList is! List) return [];

    return rawList.whereType<Map>().map((e) {
      final map = Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
      return Section(
        id: map['id'] ?? const Uuid().v4(),
        name: map['name'] ?? '',
        color: Color(map['color'] ?? Colors.grey.value),
        isFixed: map['isFixed'] ?? false,
        tasks: List<Map<String, dynamic>>.from(
          (map['tasks'] ?? []).map((task) => Map<String, dynamic>.from(task as Map)).toList(),
        ),
      );
    }).toList();
  }

  void toggleExpand(String id) {
    setState(() {
      _expanded[id] = !(_expanded[id] ?? false);
    });
  }

  void expandAll(List<Section> sections) {
    setState(() {
      _allExpanded = !_allExpanded;
      
      if (currentFilter == 'Color') {
        // Expand/collapse section groups
        for (var section in sections) {
          _expanded[section.id] = _allExpanded;
        }
      } else {
        // Expand/collapse date groups
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        
        // Get all date categories (similar to _buildTaskGroups logic)
        final dateCategories = <String>{};
        for (final section in sections) {
          for (final task in section.tasks) {
            if (task['dueDate'] != null) {
              final dueDate = DateTime.parse(task['dueDate']);
              if (dueDate.isBefore(today)) continue;
              
              String category;
              if (dueDate.isBefore(tomorrow)) {
                category = 'Today';
              } else if (dueDate.isBefore(tomorrow.add(const Duration(days: 1)))) {
                category = 'Tomorrow';
              } else if (dueDate.year == now.year && dueDate.month == now.month) {
                category = DateFormat('d MMMM y').format(dueDate);
              } else {
                category = DateFormat('MMMM y').format(dueDate);
              }
              
              dateCategories.add(category);
            }
          }
        }
        
        // Set expanded state for all date groups
        for (final category in dateCategories) {
          _expanded['date_$category'] = _allExpanded;
        }
      }
    });
  }

  void _navigateToAddTask() async {
    final sections = getAllSections();
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskPage(
          sections: sections,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final selectedSectionId = result['sectionId'];
      final newTask = result['task'];
      final dueDate = result['dueDate'];

      final index = sections.indexWhere((s) => s.id == selectedSectionId);
      if (index != -1) {
        sections[index].tasks.add({
          'id': const Uuid().v4(),
          'text': newTask, 
          'dueDate': dueDate,
          'completed': false,
        });
        sectionBox.put('list', sections.map((s) => s.toMap()).toList());
        setState(() {});
      }
    }
  }

  List<Widget> _buildTaskGroups(List<Section> sections) {
  if (currentFilter == 'Color') {
    return [
      for (int i = 0; i < sections.length; i++)
        TodoGroup(
          id: sections[i].id,
          title: sections[i].name,
          color: sections[i].color,
          items: sections[i].tasks,
          showItems: _expanded[sections[i].id] ?? true,
          trailingCount: sections[i].tasks.length,
          onToggle: () => toggleExpand(sections[i].id),
          isLast: i == sections.length - 1,
        ),
    ];
  } else {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    final tasksByDate = <String, List<Map<String, dynamic>>>{};
    final sectionColors = <String, Color>{}; // Store color for each task
    
    for (final section in sections) {
      for (final task in section.tasks) {
        if (task['dueDate'] != null) {
          final dueDate = DateTime.parse(task['dueDate']);
          if (dueDate.isBefore(today)) continue;
          
          String category;
          if (dueDate.isBefore(tomorrow)) {
            category = 'Today';
          } else if (dueDate.isBefore(tomorrow.add(const Duration(days: 1)))) {
            category = 'Tomorrow';
          } else if (dueDate.year == now.year && dueDate.month == now.month) {
            category = DateFormat('d MMMM y').format(dueDate);
          } else {
            category = DateFormat('MMMM y').format(dueDate);
          }
          
          tasksByDate.putIfAbsent(category, () => []);
          // Add the section color to the task map
          final taskWithColor = Map<String, dynamic>.from(task);
          taskWithColor['sectionColor'] = section.color.value;
          tasksByDate[category]!.add(taskWithColor);
        }
      }
    }
    
    final sortedCategories = tasksByDate.keys.toList()
      ..sort((a, b) {
        if (a == 'Today') return -1;
        if (b == 'Today') return 1;
        if (a == 'Tomorrow') return -1;
        if (b == 'Tomorrow') return 1;
        
        try {
          final dateA = DateFormat('d MMMM y').parse(a);
          final dateB = DateFormat('d MMMM y').parse(b);
          return dateA.compareTo(dateB);
        } catch (e) {
          try {
            final dateA = DateFormat('MMMM y').parse(a);
            final dateB = DateFormat('MMMM y').parse(b);
            return dateA.compareTo(dateB);
          } catch (e) {
            return a.compareTo(b);
          }
        }
      });
    
    // Initialize expanded state for date groups if not already set
    for (final category in sortedCategories) {
      final groupId = 'date_$category';
      _expanded.putIfAbsent(groupId, () => true);
    }
    
    return [
      for (int i = 0; i < sortedCategories.length; i++)
        TodoGroup(
          id: 'date_${sortedCategories[i]}',
          title: sortedCategories[i],
          color: Colors.white, // Use white background for date groups
          items: tasksByDate[sortedCategories[i]]!,
          showItems: _expanded['date_${sortedCategories[i]}'] ?? true,
          trailingCount: tasksByDate[sortedCategories[i]]!.length,
          onToggle: () => toggleExpand('date_${sortedCategories[i]}'),
          isLast: i == sortedCategories.length - 1,
          isDateGroup: true,
        ),
    ];
  }
}

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: sectionBox.listenable(),
      builder: (context, Box box, _) {
        final sections = getAllSections();
        bool shouldShowEmptyState = sections.length == 1 && 
                                sections[0].name == "Complete" || sections.every((section) => section.tasks.isEmpty);
        if (shouldShowEmptyState) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Column(
              children: [
                const _Header(),
                Expanded(  // This will push content to center
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/notasks.png',
                        width: 154,
                        height: 154,
                      ),
                      const SizedBox(height: 20), 
                      Text(
                  'No Tasks Created Yet',
                  style: AppTextStyles.header.copyWith(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Start adding tasks here to list them.',
                  style: AppTextStyles.taskItem.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                    ],
                  ),
                ),
              ),
                

                _AddTaskButton(onPressed: _navigateToAddTask),
                
              ],
            ),
          ),
        );
      }
      final groups = _buildTaskGroups(sections);

        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Column(
              children: [
                const _Header(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OverlappingTaskList(taskGroups: groups),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                  child: _FiltersBar(
                    selectedFilters: {currentFilter},
                    onFilterToggle: (filter) {
                      setState(() {
                        currentFilter = filter;
                      });
                    },
                    onExpandAll: () => expandAll(sections),
                    allExpanded: _allExpanded,
                  ),
                ),
                const SizedBox(height: 16),
                _AddTaskButton(onPressed: _navigateToAddTask),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OverlappingTaskList extends StatelessWidget {
  final List<Widget> taskGroups;
  const OverlappingTaskList({Key? key, required this.taskGroups}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < taskGroups.length; i++)
          Transform.translate(
            offset: Offset(0, -25.0 * i),
            child: taskGroups[i],
          ),
      ],
    );
  }
}

class TodoGroup extends StatelessWidget {
  final String id;
  final String title;
  final Color color;
  final List<Map<String, dynamic>> items;
  final int? trailingCount;
  final bool showItems;
  final VoidCallback? onToggle;
  final bool isLast;
  final bool isDateGroup;

  const TodoGroup({
    Key? key,
    required this.id,
    required this.title,
    required this.color,
    required this.items,
    this.trailingCount,
    this.showItems = true,
    this.onToggle,
    this.isLast = false,
    this.isDateGroup = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final count = trailingCount ?? items.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isDateGroup ? Colors.white : color,
        borderRadius: BorderRadius.circular(16),
        border: isDateGroup ? Border.all(color: Colors.grey.shade300) : null,
      ),
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.only(top: 8),
      constraints: BoxConstraints(minHeight: showItems ? 0 : 60),
      child: Column(
        children: [
          SizedBox(
            height: isLast ? 56 : 71,
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              onTap: onToggle,
              title: Text(
                title,
                style: isDateGroup
                  ? AppTextStyles.groupTitle.copyWith(color: Colors.black)
                  : AppTextStyles.groupTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '$count',
                style: isDateGroup
                  ? AppTextStyles.groupTitle.copyWith(color: Colors.black)
                  : AppTextStyles.groupTitle,
              ),
            ),
          ),
          if (showItems)
            ...items.map((task) {
              return Transform.translate(
                offset: Offset(0, isLast ? -15 : -25),
                child: _TodoItem(
                  text: task['text'] ?? '',
                  isDateGroup: isDateGroup,
                  dueDate: task['dueDate'],
                  taskColor: task['sectionColor'] != null 
                  ? Color(task['sectionColor']) 
                  : null, 
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class _TodoItem extends StatefulWidget {
  final String text;
  final bool isDateGroup;
  final String? dueDate;
  final Color? taskColor;

  const _TodoItem({
    Key? key,
    required this.text,
    this.isDateGroup = false,
    this.dueDate,
    this.taskColor,
  }) : super(key: key);

  @override
  State<_TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<_TodoItem> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    final itemHeight = widget.dueDate != null ? 64.0 : 48.0;
    final circleSize = 24.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: itemHeight,
            decoration: BoxDecoration(
              color: widget.isDateGroup
                  ? Colors.grey.shade100
                  : AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: circleSize / 2 + 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ✅ Checkbox with toggle logic
                CustomCheckbox(
                isChecked: isChecked,
                isDateGroup: widget.isDateGroup,

                onTap: () {
                  setState(() {
                    isChecked = !isChecked;
                  });
                },
              ),





                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.text,
                          style: widget.isDateGroup
                              ? AppTextStyles.taskItem
                                  .copyWith(color: Colors.black)
                              : AppTextStyles.taskItem,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // if (widget.dueDate != null)
                        //   Padding(
                        //     padding: const EdgeInsets.only(top: 2),
                        //     child: Text(
                        //       _formatDueDate(widget.dueDate!),
                        //       style: AppTextStyles.taskItem.copyWith(
                        //         color: widget.isDateGroup
                        //             ? Colors.grey.shade600
                        //             : AppColors.white.withOpacity(0.8),
                        //         fontSize: 10,
                        //       ),
                        //     ),
                        //   ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Left color marker
          if (widget.isDateGroup && widget.taskColor != null)
            Positioned(
              left: 0,
              top: itemHeight / 2 - circleSize / 2,
              child: Container(
                width: circleSize / 2,
                height: circleSize,
                decoration: BoxDecoration(
                  color: widget.taskColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(circleSize / 2),
                    bottomRight: Radius.circular(circleSize / 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDueDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM d, h:mm a').format(date);
  }
}


class _Header extends StatelessWidget {
  const _Header({Key? key}) : super(key: key);

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '👋🏻 ${getGreeting()}',
              style: AppTextStyles.header,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatefulWidget {
  final VoidCallback? onExpandAll;
  final bool allExpanded;
  final Set<String> selectedFilters;
  final void Function(String) onFilterToggle;
  
  const _FiltersBar({
    Key? key,
    required this.selectedFilters, 
    required this.onFilterToggle, 
    this.onExpandAll, 
    this.allExpanded = false,
  }) : super(key: key);

  @override
  State<_FiltersBar> createState() => __FiltersBarState();
}

class __FiltersBarState extends State<_FiltersBar> {
  int selectedIndex = 0;
  final List<String> labels = ['Color', 'Due Date'];
  final List<IconData> icons = [Icons.color_lens_outlined, Icons.date_range_outlined];

  @override
  Widget build(BuildContext context) {
      final isSmallScreen = MediaQuery.of(context).size.width < 340;

    if (isSmallScreen) {
      // 👉 Stack vertically on narrow screens
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggleSegment(), // toggle chips
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: _buildExpandChip(), // "Expand All" button
            ),
          ],
        ),
      );
    } else {
      // 👉 Normal horizontal layout for wider screens
      return Padding(
        padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
        child: Row(
          children: [
            _buildToggleSegment(),
            const Spacer(),
            _buildExpandChip(),
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
    final label = widget.allExpanded ? 'Collapse All' : 'Expand All';

    return InkWell(
      onTap: widget.onExpandAll,
      child: SizedBox(
        width:112,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 0.5), // 🔲 black border
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16, // fixed space for icon
              child: Icon(widget.allExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: Colors.black),
            ),
            const SizedBox(width: 4),
             Expanded(
              child: Text(
                label,
                style: AppTextStyles.chipText.copyWith(color: Colors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      )
    );
  }

}

class _AddTaskButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddTaskButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          ),
          onPressed: onPressed,
          icon: const Icon(Icons.add, color: AppColors.white),
          label: Text('Add Task', style: AppTextStyles.buttonText),
        ),
      ),
    );
  }
}

class CustomCheckbox extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onTap;
  final bool isDateGroup;

  const CustomCheckbox({
    Key? key,
    required this.isChecked,
    required this.onTap,
    required this.isDateGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderColor = isDateGroup ? Colors.grey : AppColors.white;
    final checkColor = isDateGroup ? Colors.black : AppColors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isChecked ? Colors.transparent : Colors.white,
          border: isChecked
              ? Border.all(color: borderColor, width: 1.6)
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: isChecked
            ? Icon(Icons.check, size: 16, color: checkColor)
            : null,
      ),
    );
  }
}