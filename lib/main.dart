import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'styles.dart';
import 'setting.dart';
import 'add_task_page.dart';
import '../models/section.dart';

void main() async {
  await Hive.initFlutter();

  var sectionBox = await Hive.openBox('sections');
  if (sectionBox.isEmpty) {
    const uuid = Uuid();
    await sectionBox.put('list', [
      {
        'id': uuid.v4(),
        'name': 'Most Urgent',
        'color': Colors.red.value,
        'isFixed': false,
        'tasks': <Map<String, dynamic>>[],
      },
      {
        'id': uuid.v4(),
        'name': 'Important',
        'color': Colors.orange.value,
        'isFixed': false,
        'tasks': [],
      },
      {
        'id': uuid.v4(),
        'name': 'Do this Later',
        'color': Colors.blue.value,
        'isFixed': false,
        'tasks': [],
      },
      {
        'id': uuid.v4(),
        'name': 'Kind of Important',
        'color': Colors.purple.value,
        'isFixed': false,
        'tasks': [],
      },
      {
        'id': uuid.v4(),
        'name': 'Complete',
        'color': Colors.green.value,
        'isFixed': true,
        'tasks': [],
      },
    ]);
  }

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TodoHomePage(),
  ));
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({Key? key}) : super(key: key);

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final Box sectionBox = Hive.box('sections');
  final Map<String, bool> _expanded = {};
  bool _allExpanded = false;
  Set<String> selectedFilters = {};

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

  List<Map<String, dynamic>> getTasks(String category) {
    final sectionData = sectionBox.get('list', defaultValue: []);
    final sections = sectionData.map((e) {
      final map = Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
      return Section(
        id: map['id'],
        name: map['name'],
        color: Color(map['color']),
        isFixed: map['isFixed'],
        tasks: List<Map<String, dynamic>>.from(
          (map['tasks'] ?? []).map((task) => Map<String, dynamic>.from(task as Map)).toList(),
        ),
      );
    }).toList();

    return sections.firstWhere((s) => s.name == category).tasks;
  }

  void toggleExpand(String id) {
  setState(() {
    _expanded[id] = !(_expanded[id] ?? false);
  });
  }

  void expandAll(List<Section> sections) {
    setState(() {
      _allExpanded = !_allExpanded;
      for (var section in sections) {
        _expanded[section.id] = _allExpanded;
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
        'id': const Uuid().v4(),  // Add unique ID for each task
        'text': newTask, 
        'dueDate': dueDate,
        'completed': false,
      });
      sectionBox.put('list', sections.map((s) => s.toMap()).toList());
      setState(() {});
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: sectionBox.listenable(),
      builder: (context, Box box, _) {
        final sections = getAllSections();
        final groups = [
          for (int i = 0; i < sections.length; i++)
            TodoGroup(
              id:sections[i].id,
              title: sections[i].name,
              color: sections[i].color,
              items: getTasks(sections[i].name),
              showItems: _expanded[sections[i].id] ?? true,
              trailingCount: getTasks(sections[i].name).length,
              onToggle: () => toggleExpand(sections[i].id),
              isLast: i == sections.length - 1,
            ),
        ];

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
                  padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                  child: _FiltersBar(
                    selectedFilters: selectedFilters,
                    onFilterToggle: (filter) {
                      setState(() {
                        if (selectedFilters.contains(filter)) {
                          selectedFilters.remove(filter);
                        } else {
                          selectedFilters.add(filter);
                        }
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

// Reusable Widgets

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final count = trailingCount ?? items.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
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
              title: Text(title, style: AppTextStyles.groupTitle,maxLines: 1,
               overflow: TextOverflow.ellipsis,),
              trailing: Text('$count', style: AppTextStyles.groupTitle),
            ),
          ),
          if (showItems)
            ...items.map((task) {
              return Transform.translate(
                offset: Offset(0, isLast ? -15 : -25),
                child: _TodoItem(text: task['text'] ?? ''),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class _TodoItem extends StatelessWidget {
  final String text;
  const _TodoItem({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Checkbox(
              value: false,
              onChanged: (_) {},
              side: const BorderSide(color: AppColors.white, width: 1.6),
              checkColor: AppColors.white,
              activeColor: AppColors.white,
            ),
            title: Text(text, style: AppTextStyles.taskItem,maxLines: 1,
            overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '👋 Good Morning',
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
    final isSmallScreen = MediaQuery.of(context).size.width < 370;

    if (isSmallScreen) {
      // 👉 Stack vertically on narrow screens
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
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
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (index) {
            final isSelected = index == selectedIndex;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
                widget.onFilterToggle(labels[index]);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))]
                      : [],
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
