import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'styles.dart';
import 'setting.dart';
import 'add_task_page.dart';
import '../models/section.dart';
import 'overlapping_task_list.dart';
import 'package:flutter/cupertino.dart';

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({Key? key}) : super(key: key);

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  int? completedIndex;
  late Box sectionBox;
  final Map<String, bool> _expanded = {};
  bool _allExpanded = false;
  String currentFilter = 'Color';
  String? _editingSectionId;

  @override
  void initState() {
    super.initState();
    sectionBox = Hive.box('sections');
  }

  List<Section> getAllSections() {
    final rawList = sectionBox.get('list');
    if (rawList == null || rawList is! List) return [];

    final sections = rawList.whereType<Map>().map((e) {
      final map = Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
      return Section(
        id: map['id'] ?? const Uuid().v4(),
        name: map['name'] ?? '',
        color: Color(map['color'] ?? Colors.grey.value),
        isFixed: map['isFixed'] ?? false,
        tasks: List<Map<String, dynamic>>.from(
          (map['tasks'] ?? [])
              .map((task) => Map<String, dynamic>.from(task as Map))
              .toList(),
        ),
      );
    }).toList();

    // Find and move "Completed" section to the end if it exists
    completedIndex = sections.indexWhere((s) => s.name == 'Completed');
    if (completedIndex != -1) {
      final completedSection = sections.removeAt(completedIndex!);
      sections.add(completedSection);
      completedIndex = sections.length - 1;
    }
    
    return sections;
  }

  bool _shouldShowCompletedSection(List<Section> sections) {
    if (completedIndex == null || completedIndex == -1) return false;
    return sections[completedIndex!].isFixed;
  }

  void toggleExpand(String id) {
    setState(() {
      _expanded[id] = !(_expanded[id] ?? false);
      _editingSectionId = null;
    });
  }

  void expandAll(List<Section> sections) {
  setState(() {
    _allExpanded = !_allExpanded;

    if (currentFilter == 'Color') {
      for (var section in sections) {
        if (section.name == 'Completed' && !_shouldShowCompletedSection(sections)) {
          continue;
        }
        _expanded[section.id] = _allExpanded;
      }
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final dateCategories = <String>{};
      
      // Always include "Overdue" if there are any overdue tasks
      bool hasOverdue = false;
      
      for (final section in sections) {
        if (section.name == 'Completed' && !_shouldShowCompletedSection(sections)) {
          continue;
        }
        
        for (final task in section.tasks) {
          if (task['completed'] == true) continue;
          
          if (task['dueDate'] != null) {
            final dueDate = DateTime.parse(task['dueDate']);
            if (dueDate.isBefore(today)) {
              hasOverdue = true;
              continue; // Skip adding to other categories
            }

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

      // Add "Overdue" category if there are overdue tasks
      if (hasOverdue) {
        dateCategories.add('Overdue Tasks');
      }

      for (final category in dateCategories) {
        _expanded['date_$category'] = _allExpanded;
      }
    }
  });
}

  void _collapseAllExcept(String sectionId) {
    setState(() {
      // Collapse all sections
      _expanded.forEach((key, value) {
        _expanded[key] = false;
      });
      
      // Expand the specified section
      _expanded[sectionId] = true;
      _allExpanded = false;
    });
  }

  void _collapseAllExceptDateGroup(String groupId) {
  setState(() {
    // Collapse all date groups
    _expanded.forEach((key, value) {
      if (key.startsWith('date_')) {
        _expanded[key] = false;
      }
    });
    
    // Expand the specified date group
    _expanded[groupId] = true;
    _allExpanded = false;
  });
}

  void _collapseAll() {
  setState(() {
    _expanded.updateAll((key, value) => false);
    _allExpanded = false;
  });
}

  void _handleReorder(int oldIndex, int newIndex, String sectionId) {
    final sections = getAllSections();
    final sectionIndex = sections.indexWhere((s) => s.id == sectionId);
    
    if (sectionIndex != -1) {
      final tasks = sections[sectionIndex].tasks;
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final task = tasks.removeAt(oldIndex);
      tasks.insert(newIndex, task);
      sectionBox.put('list', sections.map((s) => s.toMap()).toList());
      HapticFeedback.selectionClick();
    }
  }

  // Move task between sections (drag & drop)
  void _moveTaskToSection({
  required String fromSectionId,
  required String toSectionId,
  required String taskId,
}) {
  final sections = getAllSections();
  final fromIndex = sections.indexWhere((s) => s.id == fromSectionId);
  final toIndex = sections.indexWhere((s) => s.id == toSectionId);
  if (fromIndex == -1 || toIndex == -1) return;

  final taskIdx = sections[fromIndex].tasks.indexWhere((t) => t['id'] == taskId);
  if (taskIdx == -1) return;

  final task = Map<String, dynamic>.from(sections[fromIndex].tasks[taskIdx]);

  // Remove from old section
  sections[fromIndex].tasks.removeAt(taskIdx);

  // Set completed property and insert in correct position
  if (sections[toIndex].name == 'Completed') {
    task['completed'] = true;
    sections[toIndex].tasks.insert(0, task); // insert at top
  } else {
    task['completed'] = false;
    sections[toIndex].tasks.add(task); // add at bottom
  }

  // Save to Hive
  sectionBox.put('list', sections.map((s) => s.toMap()).toList());

  // UI update
  setState(() {
    _collapseAllExcept(toSectionId);
  });
}

  void _navigateToAddTask() async {
  late List<Section> sections = getAllSections();

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddTaskPage(
        sections: sections,
        onSectionCreated: (newSection) {
          setState(() {
            sections.add(newSection);
            sectionBox.put('list', sections.map((s) => s.toMap()).toList());
          });
        },
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
      
      // Handle collapse based on current filter
      if (currentFilter == 'Color') {
        _collapseAllExcept(selectedSectionId);
      } else if (dueDate != null) {
        final date = DateTime.parse(dueDate);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        
        String category;
        if (date.isBefore(tomorrow)) {
          category = 'Today';
        } else if (date.isBefore(tomorrow.add(const Duration(days: 1)))) {
          category = 'Tomorrow';
        } else if (date.year == now.year && date.month == now.month) {
          category = DateFormat('d MMMM y').format(date);
        } else {
          category = DateFormat('MMMM y').format(date);
        }
        
        _collapseAllExceptDateGroup('date_$category');
      }
    }
  }
}

  void _deleteTask(String sectionId, String taskId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.only(left: 8,right:8, top: 16,bottom:0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.only(left: 0,right:0, top: 0,bottom:0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/delete.png',
                    width: 154,
                    height: 154,
                  ),
                  const Text(
                    'Delete this task?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal:20),
                    child: Text(
                      "Once deleted, you'll no longer see this task in your task list",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.black12, width: 1),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(vertical:10),
                      child: TextButton(
                        onPressed: () {
                          final sections = getAllSections();
                          final sectionIndex = sections.indexWhere((s) => s.id == sectionId);

                          if (sectionIndex != -1) {
                            setState(() {
                              sections[sectionIndex].tasks.removeWhere((task) => task['id'] == taskId);
                              sectionBox.put('list', sections.map((s) => s.toMap()).toList());
                              _collapseAllExcept(sectionId);
                            });
                          }
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
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.white,
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _deleteTaskFromEdit(String sectionId, String taskId) {
     final sections = getAllSections();
                          final sectionIndex = sections.indexWhere((s) => s.id == sectionId);

                          if (sectionIndex != -1) {
                            setState(() {
                              sections[sectionIndex].tasks.removeWhere((task) => task['id'] == taskId);
                              sectionBox.put('list', sections.map((s) => s.toMap()).toList());
                               _collapseAllExcept(sectionId);
                            });
                          }
  }

 void _editTask(String sectionId, String taskId, String currentText,
  DateTime currentDate) async {
  late List<Section> sections = getAllSections();

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddTaskPage(
        sections: sections,
        existingTask: currentText,
        existingDate: currentDate,
        existingSectionId: sectionId,
        onDelete: () => _deleteTaskFromEdit(sectionId, taskId),
        onSectionCreated: (newSection) {
          setState(() {
            sections.add(newSection);
            sectionBox.put('list', sections.map((s) => s.toMap()).toList());
          });
        },
      ),
    ),
  );

  if (result != null && result is Map<String, dynamic>) {
    final selectedSectionId = result['sectionId'];
    final newTask = result['task'];
    final dueDate = result['dueDate'];

    // Find the original task index before removing it
    final oldSectionIndex = sections.indexWhere((s) => s.id == sectionId);
    int? originalIndex;
    
    if (oldSectionIndex != -1) {
      originalIndex = sections[oldSectionIndex].tasks.indexWhere((task) => task['id'] == taskId);
      sections[oldSectionIndex].tasks.removeWhere((task) => task['id'] == taskId);
    }

    final newSectionIndex = sections.indexWhere((s) => s.id == selectedSectionId);
    if (newSectionIndex != -1) {
      final newTaskData = {
        'id': taskId,
        'text': newTask,
        'dueDate': dueDate,
        'completed': false,
      };

      // If moving within the same section, insert at original position
      if (sectionId == selectedSectionId && originalIndex != null && originalIndex != -1) {
        sections[newSectionIndex].tasks.insert(originalIndex, newTaskData);
      } 
      // If moving to a different section, add to the end
      else {
        sections[newSectionIndex].tasks.add(newTaskData);
      }

      sectionBox.put('list', sections.map((s) => s.toMap()).toList());
      
      // Handle collapse based on current filter
      if (currentFilter == 'Color') {
        _collapseAllExcept(selectedSectionId);
      } else if (dueDate != null) {
        final date = DateTime.parse(dueDate);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        
        String category;
        if (date.isBefore(tomorrow)) {
          category = 'Today';
        } else if (date.isBefore(tomorrow.add(const Duration(days: 1)))) {
          category = 'Tomorrow';
        } else if (date.year == now.year && date.month == now.month) {
          category = DateFormat('d MMMM y').format(date);
        } else {
          category = DateFormat('MMMM y').format(date);
        }
        
        _collapseAllExceptDateGroup('date_$category');
      }
    }
  }
}

  Section _getOrCreateCompletedSection(List<Section> sections) {
    try {
      final completedSection = sections.firstWhere((section) => section.name == 'Completed');
      if (sections.last != completedSection) {
        sections.remove(completedSection);
        sections.add(completedSection);
      }
      return completedSection;
    } catch (e) {
      final completedSection = Section(
        id: const Uuid().v4(),
        name: 'Completed',
        color: Colors.grey,
        isFixed: true,
        tasks: [],
      );
      sections.add(completedSection);
      sectionBox.put('list', sections.map((s) => s.toMap()).toList());
      return completedSection;
    }
  }

  void _toggleTaskCompletion(String sectionId, String taskId, bool isCompleted) {
    final sections = getAllSections();
    final currentSectionIndex = sections.indexWhere((s) => s.id == sectionId);

    if (currentSectionIndex != -1) {
      final taskIndex = sections[currentSectionIndex].tasks.indexWhere(
        (task) => task['id'] == taskId,
      );

      if (taskIndex != -1) {
        final taskToMove = Map<String, dynamic>.from(sections[currentSectionIndex].tasks[taskIndex]);

        setState(() {
          taskToMove['completed'] = isCompleted;

          if (isCompleted) {
            sections[currentSectionIndex].tasks.removeAt(taskIndex);
            final completedSection = _getOrCreateCompletedSection(sections);
            if (!completedSection.tasks.any((task) => task['id'] == taskToMove['id'])) {
              completedSection.tasks.insert(0, taskToMove);
            }
            _collapseAllExcept(completedSection.id);

          } else {
            final completedSectionIndex = sections.indexWhere((s) => s.name == 'Completed');
            if (completedSectionIndex != -1) {
              final completedTaskIndex = sections[completedSectionIndex].tasks.indexWhere(
                (task) => task['id'] == taskId,
              );
              if (completedTaskIndex != -1) {
                sections[completedSectionIndex].tasks[completedTaskIndex]['completed'] = isCompleted;
              }
            } else {
              sections[currentSectionIndex].tasks[taskIndex]['completed'] = isCompleted;
            }
          }
          sectionBox.put('list', sections.map((s) => s.toMap()).toList());
          //_collapseAllExcept(completedSection);
        });
      }
    }
  }

  void _toggleSectionEditMode(String sectionId) {
    setState(() {
      if (_editingSectionId == sectionId) {
        _editingSectionId = null;
      } else {
        _editingSectionId = sectionId;
      }
    });
  }

  void _exitEditMode() {
    setState(() {
      _editingSectionId = null;
    });
  }

  List<Widget> _buildTaskGroups(List<Section> sections) {
  final visibleSections = sections.where((section) {
    return !(section.name == 'Completed' && !_shouldShowCompletedSection(sections));
  }).toList();

  if (currentFilter == 'Color') {
    return [
      for (int i = 0; i < visibleSections.length; i++)
        ColorFilterGroup(
          key: ValueKey(visibleSections[i].id),
          id: visibleSections[i].id,
          title: visibleSections[i].name,
          color: visibleSections[i].color,
          items: visibleSections[i].tasks,
          showItems: _expanded[visibleSections[i].id] ?? true,
          trailingCount: visibleSections[i].tasks.length,
          onToggle: () => toggleExpand(visibleSections[i].id),
          isLast: i == visibleSections.length - 1,
          sectionId: visibleSections[i].id,
          onDeleteTask: _deleteTask,
          onEditTask: _editTask,
          isEditing: _editingSectionId == visibleSections[i].id,
          onLongPress: () => _toggleSectionEditMode(visibleSections[i].id),
          onToggleComplete: (taskId, isCompleted) {
            _toggleTaskCompletion(visibleSections[i].id, taskId, isCompleted);
          },
          onReorder: (oldIndex, newIndex) {
            _handleReorder(oldIndex, newIndex, visibleSections[i].id);
          },
          onMoveTask: (fromSectionId, toSectionId, taskId) {
            _moveTaskToSection(fromSectionId: fromSectionId, toSectionId: toSectionId, taskId: taskId);
          },
        ),
    ];
  } else {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final tasksByDate = <String, List<Map<String, dynamic>>>{};
    bool hasTasks = false;

    // Add a category for past-dated tasks
    final pastTasks = <Map<String, dynamic>>[];

    for (final section in sections) {
      if (section.name == 'Completed' && !_shouldShowCompletedSection(sections)) {
        continue;
      }
      
      for (final task in section.tasks) {
        if (task['completed'] == true) continue;
        
        if (task['dueDate'] != null) {
          final dueDate = DateTime.parse(task['dueDate']);
          final taskWithColor = Map<String, dynamic>.from(task);
          taskWithColor['sectionColor'] = section.color.value;
          taskWithColor['sectionId'] = section.id;
          taskWithColor['completed'] = task['completed'] ?? false;

          if (dueDate.isBefore(today)) {
            // Add to past tasks
            pastTasks.add(taskWithColor);
            hasTasks = true;
          } else {
            // Categorize future tasks as before
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
            tasksByDate[category]!.add(taskWithColor);
            hasTasks = true;
          }
        }
      }
    }

    // Add past tasks category if there are any
    if (pastTasks.isNotEmpty) {
      tasksByDate['Overdue Tasks'] = pastTasks;
    }

    // If no tasks found, return a centered message
    if (!hasTasks) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Your All Tasks are completed',
                  style: AppTextStyles.header.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Great job! You have no pending tasks.',
                  style: AppTextStyles.taskItem.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final sortedCategories = tasksByDate.keys.toList()
      ..sort((a, b) {
        // Overdue should always come first
        if (a == 'Overdue Tasks') return -1;
        if (b == 'Overdue Tasks') return 1;
        
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

    for (final category in sortedCategories) {
      final groupId = 'date_$category';
      _expanded.putIfAbsent(groupId, () => true);
    }

    return [
      for (int i = 0; i < sortedCategories.length; i++)
        DateFilterGroup(
          key: ValueKey('date_${sortedCategories[i]}'),
          id: 'date_${sortedCategories[i]}',
          title: sortedCategories[i],
          items: tasksByDate[sortedCategories[i]]!,
          showItems: _expanded['date_${sortedCategories[i]}'] ?? true,
          trailingCount: tasksByDate[sortedCategories[i]]!.length,
          onToggle: () => toggleExpand('date_${sortedCategories[i]}'),
          isLast: i == sortedCategories.length - 1,
          sectionId: '',
          onDeleteTask: _deleteTask,
          onEditTask: _editTask,
          onToggleComplete: (taskId, isCompleted) {
            final task = tasksByDate[sortedCategories[i]]!.firstWhere(
              (element) => element['id'] == taskId,
            );
            _toggleTaskCompletion(task['sectionId'], taskId, isCompleted);
          },
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
        final visibleSections = sections.where((section) {
          return !(section.name == 'Completed' && !_shouldShowCompletedSection(sections));
        }).toList();

        bool shouldShowEmptyState = visibleSections.isEmpty ||
            visibleSections.every((section) => section.tasks.isEmpty);

        if (shouldShowEmptyState) {
          return Scaffold(
            backgroundColor: AppColors.white,
            body: SafeArea(
              child: Column(
                children: [
                  const _Header(),
                  Expanded(
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
                  child: GestureDetector(
                    onTap: _exitEditMode,
                    behavior: HitTestBehavior.opaque,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: OverlappingTaskList(taskGroups: groups),
                    ),
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

class ColorFilterGroup extends StatelessWidget {
  final String id;
  final String title;
  final Color color;
  final List<Map<String, dynamic>> items;
  final int? trailingCount;
  final bool showItems;
  final VoidCallback? onToggle;
  final bool isLast;
  final String sectionId;
  final Function(String, String) onDeleteTask;
  final Function(String, String, String, DateTime) onEditTask;
  final Function(String taskId, bool isCompleted) onToggleComplete;
  final bool isEditing;
  final VoidCallback? onLongPress;
  final Function(int oldIndex, int newIndex)? onReorder;
  final Function(String fromSectionId, String toSectionId, String taskId)? onMoveTask;

  const ColorFilterGroup({
    Key? key,
    required this.id,
    required this.title,
    required this.color,
    required this.items,
    this.trailingCount,
    this.showItems = true,
    this.onToggle,
    this.isLast = false,
    required this.sectionId,
    required this.onDeleteTask,
    required this.onEditTask,
    required this.onToggleComplete,
    this.isEditing = false,
    this.onLongPress,
    this.onReorder,
    this.onMoveTask,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final count = trailingCount ?? items.length;

    // Determine text color based on background color brightness
    final isLight = color.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black : Colors.white;

    return DragTarget<Map<String, String>>(
      onWillAccept: (data) {
        return data != null && data['fromSectionId'] != sectionId;
      },
      onAccept: (data) {
        if (onMoveTask != null && data['fromSectionId'] != null && data['taskId'] != null) {
          onMoveTask!(data['fromSectionId']!, sectionId, data['taskId']!);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: candidateData.isNotEmpty ? Border.all(color: Colors.deepPurple, width: 2) : null,
            ),
            margin: const EdgeInsets.only(bottom: 0),
            padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 8),
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
                      style: AppTextStyles.groupTitle.copyWith(color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '$count',
                      style: AppTextStyles.groupTitle.copyWith(
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                if (showItems && isEditing)
                  Transform.translate(
                    offset: Offset(0, isLast ? -15 : -25),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      buildDefaultDragHandles: false,
                      onReorder: (oldIndex, newIndex) {
                        if (onReorder != null) {
                          onReorder!(oldIndex, newIndex);
                        }
                      },
                      proxyDecorator: (Widget child, int index, Animation<double> animation) {
                        return Material(
                          elevation: 0,
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final task = items[index];
                        return ReorderableDragStartListener(
                          key: Key(task['id']),
                          index: index,
                          child: ColorFilterTaskItem(
                            text: task['text'] ?? '',
                            isLastTask: index == items.length - 1,
                            dueDate: task['dueDate'],
                            taskId: task['id'] ?? '',
                            sectionId: sectionId,
                            taskItemColor:textColor,
                            sectionName: title,
                            onDelete: () => onDeleteTask(sectionId, task['id'] ?? ''),
                            onEdit: () {
                              final dueDate = task['dueDate'] != null
                                  ? DateTime.parse(task['dueDate'])
                                  : DateTime.now();
                              onEditTask(
                                sectionId,
                                task['id'] ?? '',
                                task['text'] ?? '',
                                dueDate,
                              );
                            },
                            onToggleComplete: (isCompleted) {
                              onToggleComplete(task['id'], isCompleted);
                            },
                            completed: task['completed'] ?? false,
                            isEditing: isEditing,
                            isDraggable: true,
                          ),
                        );
                      },
                    ),
                  ),
                if (showItems && !isEditing)
                  Transform.translate(
                    offset: Offset(0, isLast ? -15 : -25),
                    child: Column(
                      children: items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final task = entry.value;
                        return Draggable<Map<String, String>>(
                          data: {
                            'fromSectionId': sectionId,
                            'taskId': task['id'] ?? '',
                          },
                          feedback: Material(
                            elevation: 6,
                            color: Colors.transparent,
                            child: Container(
                              width: MediaQuery.of(context).size.width - 32,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ColorFilterTaskItem(
                                text: task['text'] ?? '',
                                isLastTask: index == items.length - 1,
                                dueDate: task['dueDate'],
                                taskId: task['id'] ?? '',
                                sectionId: sectionId,
                                taskItemColor: textColor,
                                sectionName: title,
                                onDelete: () {}, // No delete during drag
                                onEdit: () {}, // No edit during drag
                                onToggleComplete: (_) {}, // No toggle during drag
                                completed: task['completed'] ?? false,
                                isEditing: false,
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.5,
                            child: ColorFilterTaskItem(
                              text: task['text'] ?? '',
                              isLastTask: index == items.length - 1,
                              dueDate: task['dueDate'],
                              taskId: task['id'] ?? '',
                              sectionId: sectionId,
                              taskItemColor: textColor,
                              sectionName: title,
                              onDelete: () => onDeleteTask(sectionId, task['id'] ?? ''),
                              onEdit: () {
                                final dueDate = task['dueDate'] != null
                                    ? DateTime.parse(task['dueDate'])
                                    : DateTime.now();
                                onEditTask(
                                  sectionId,
                                  task['id'] ?? '',
                                  task['text'] ?? '',
                                  dueDate,
                                );
                              },
                              onToggleComplete: (isCompleted) {
                                onToggleComplete(task['id'], isCompleted);
                              },
                              completed: task['completed'] ?? false,
                              isEditing: isEditing,
                            ),
                          ),
                          child: ColorFilterTaskItem(
                            key: Key(task['id']),
                            text: task['text'] ?? '',
                            isLastTask: index == items.length - 1,
                            dueDate: task['dueDate'],
                            taskId: task['id'] ?? '',
                            sectionId: sectionId,
                            taskItemColor: textColor,
                            sectionName: title,
                            onDelete: () => onDeleteTask(sectionId, task['id'] ?? ''),
                            onEdit: () {
                              final dueDate = task['dueDate'] != null
                                  ? DateTime.parse(task['dueDate'])
                                  : DateTime.now();
                              onEditTask(
                                sectionId,
                                task['id'] ?? '',
                                task['text'] ?? '',
                                dueDate,
                              );
                            },
                            onToggleComplete: (isCompleted) {
                              onToggleComplete(task['id'], isCompleted);
                            },
                            completed: task['completed'] ?? false,
                            isEditing: isEditing,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DateFilterGroup extends StatelessWidget {
  final String id;
  final String title;
  final List<Map<String, dynamic>> items;
  final int? trailingCount;
  final bool showItems;
  final VoidCallback? onToggle;
  final bool isLast;
  final String sectionId;
  final Function(String, String) onDeleteTask;
  final Function(String, String, String, DateTime) onEditTask;
  final Function(String taskId, bool isCompleted) onToggleComplete;

  const DateFilterGroup({
    Key? key,
    required this.id,
    required this.title,
    required this.items,
    this.trailingCount,
    this.showItems = true,
    this.onToggle,
    this.isLast = false,
    required this.sectionId,
    required this.onDeleteTask,
    required this.onEditTask,
    required this.onToggleComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final count = trailingCount ?? items.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      margin: const EdgeInsets.only(bottom: 0),
      padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 8),
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
                style: AppTextStyles.groupTitle.copyWith(color: Colors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '$count',
                style: AppTextStyles.groupTitle.copyWith(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (showItems)
            ...items.map((task) {
              return Transform.translate(
                key: Key(task['id']),
                offset: Offset(0, isLast ? -15 : -25),
                child: DateFilterTaskItem(
                  text: task['text'] ?? '',
                  isLastTask: items.last == task,
                  dueDate: task['dueDate'],
                  taskColor: task['sectionColor'] != null
                      ? Color(task['sectionColor'])
                      : null,
                  taskId: task['id'] ?? '',
                  sectionId: task['sectionId'] ?? sectionId,
                  sectionName: title, 
                  onDelete: () => onDeleteTask(
                      task['sectionId'] ?? sectionId, task['id'] ?? ''),
                  onEdit: () {
                    final dueDate = task['dueDate'] != null
                        ? DateTime.parse(task['dueDate'])
                        : DateTime.now();
                    onEditTask(
                      task['sectionId'] ?? sectionId,
                      task['id'] ?? '',
                      task['text'] ?? '',
                      dueDate,
                    );
                    // Call the specific date group collapse function
                    if (context.mounted) {
                      final state = context.findAncestorStateOfType<_TodoHomePageState>();
                      state?._collapseAllExceptDateGroup('date_$title');
                    }
                  },
                  onToggleComplete: (isCompleted) {
                    onToggleComplete(task['id'], isCompleted);
                  },
                  completed: task['completed'] ?? false,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class ColorFilterTaskItem extends StatelessWidget {
  final String text;
  final String? dueDate;
  final String taskId;
  final String sectionId;
  final String sectionName;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleComplete;
  final bool completed;
  final bool isEditing;
  final bool isDraggable;
  final bool isLastTask;
  final Color taskItemColor;

  const ColorFilterTaskItem({
    Key? key,
    required this.text,
    this.dueDate,
    required this.taskId,
    required this.taskItemColor,
    required this.sectionId,
    required this.sectionName,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleComplete,
    required this.completed,
    required this.isEditing,
    this.isDraggable = false,
    this.isLastTask = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: GestureDetector(
        onTap: isEditing || sectionName == "Completed" ? null : onEdit,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: isEditing ? 36 : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isEditing)
                      isDraggable 
                      ? ReorderableDragStartListener(
                          index: 0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.drag_indicator,
                                color: taskItemColor,
                                size: 20,
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.drag_indicator,
                              color: taskItemColor,
                              size: 20,
                            ),
                          ),
                        )
                    else if (!completed)
                      CustomCheckbox(
                        isChecked: sectionName == "Completed" ? true : completed,
                        isDateGroup: false,
                        checkBoxColor:taskItemColor!,
                        onTap: () {
                          onToggleComplete(!completed);
                        },
                      )
                    else
                      IgnorePointer(
                        child: Opacity(
                          opacity: 1,
                          child: CustomCheckbox(
                            isChecked: true,
                            isDateGroup: false,
                            checkBoxColor:taskItemColor!,
                            onTap: () {},
                          ),
                        ),
                      ),
                    
                    SizedBox(width: isEditing ? 2 : 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: AppTextStyles.taskItem.copyWith(
                              color: taskItemColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              decorationColor: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (isEditing)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon:  Icon(
                        CupertinoIcons.delete,
                        size: 16, // You can adjust the size
                        color: taskItemColor, // Change color as needed
                      ),
                    onPressed: onDelete,
                  ),
                ),
              ),

            if (!isLastTask)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    height: 0.2,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DateFilterTaskItem extends StatelessWidget {
  final String text;
  final String? dueDate;
  final Color? taskColor;
  final String taskId;
  final String sectionId;
  final String sectionName;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleComplete;
  final bool completed;
  final bool isLastTask;

  const DateFilterTaskItem({
    Key? key,
    required this.text,
    this.dueDate,
    this.taskColor,
    required this.taskId,
    required this.sectionId,
    required this.sectionName,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleComplete,
    required this.completed,
    this.isLastTask = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical:4),
      child: Stack(
      clipBehavior: Clip.none,
      children: [
        if (taskColor != null)
          Positioned.fill(
            child: Row(
              children: [
                Container(
                  width: 6.0,
                  color: taskColor,
                ),
                Expanded(
                  flex: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          taskColor!.withOpacity(0.6),
                          taskColor!.withOpacity(0.2),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                
              ],
            ),
          ),

        Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomCheckbox(
                  isChecked: completed,
                  isDateGroup: true,
                  checkBoxColor:null,
                  onTap: () {
                    onToggleComplete(!completed);
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                child: GestureDetector(
                  onTap: onEdit,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: AppTextStyles.taskItem.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          decorationColor: Colors.black,
                          decoration: completed ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        
        ),
      ]
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey, width: 0.3),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              ),
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
  final List<IconData> icons = [
    CupertinoIcons.paintbrush, // for "Color"
    CupertinoIcons.calendar,   // for "Due Date"
  ];

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 340;

    if (isSmallScreen) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggleSegment(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: _buildExpandChip(),
            ),
          ],
        ),
      );
    } else {
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
            border: Border.all(color: Colors.black, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                child: Transform.rotate(
                angle: 1.5708, // 180 degrees in radians (pi)
                child: Icon(
                  CupertinoIcons.arrow_up_left_arrow_down_right,
                  size: 12,
                  color: Colors.black,
                ),
              ),
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
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          ),
          onPressed: onPressed,
          icon: const Icon(Icons.add,size:20, color: AppColors.white),
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
  final Color? checkBoxColor;

  const CustomCheckbox({
    Key? key,
    required this.isChecked,
    required this.onTap,
    required this.isDateGroup,
    required this.checkBoxColor
  }) : super(key: key);

  bool _colorsEqual(Color? color1, Color color2) {
    if (color1 == null) return false;
    return color1.value == color2.value;
  }

  @override
  Widget build(BuildContext context) {
    final isBlack = _colorsEqual(checkBoxColor, Color(0xff000000));
    final borderColor = isDateGroup || isBlack  ? Colors.transparent : Colors.white;
    final checkColor = isDateGroup || isBlack  ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: isChecked 
              ?  Colors.transparent
              : (isDateGroup || isBlack ? Colors.grey[400] : Colors.white),
          border: Border.all(
            color: borderColor,
            width: 1.6,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: isChecked
            ? Icon(Icons.check, size: 14, color: checkColor)
            : null,
      ),
    );
  }
}