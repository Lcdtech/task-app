import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/section.dart';
import 'custom_datetime_picker.dart';
import 'styles.dart'; // Assuming AppColors and AppTextStyles are defined here
import 'create_section_page.dart';

// Assuming Section and other necessary imports/files are correctly linked

class AddTaskPage extends StatefulWidget {
  final List<Section> sections;
  final String? existingTask;
  final DateTime? existingDate;
  final String? existingSectionId;
  final String? existingTaskId;
  final VoidCallback? onDelete;
  final Function(Section)? onSectionCreated;

  const AddTaskPage({
    Key? key,
    required this.sections,
    this.existingTask,
    this.existingDate,
    this.existingSectionId,
    this.existingTaskId,
    this.onDelete,
    this.onSectionCreated,
  }) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _controller = TextEditingController();
  late List<Section> _sections;
  String? selectedSectionId;
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    _sections = List.from(widget.sections); // Use List.from to make it mutable if you plan to add to it directly
    _controller.text = widget.existingTask ?? '';
    selectedDateTime = widget.existingDate;

    // Initialize selectedSectionId only if there are existing sections
    if (widget.existingSectionId != null && _sections.any((s) => s.id == widget.existingSectionId)) {
      selectedSectionId = widget.existingSectionId;
    } else if (_sections.isNotEmpty) {
      selectedSectionId = _sections.first.id;
    } else {
      selectedSectionId = null; // Ensure it's null if no sections exist
    }
  }

  bool get isFormValid =>
      selectedSectionId != null &&
      selectedDateTime != null &&
      _controller.text.trim().isNotEmpty;

  bool get isEditing => widget.existingTask != null;

  Future<void> _pickDueDate() async {
    final picked = await showCustomDateTimePicker(context);
    if (picked != null) {
      setState(() => selectedDateTime = picked);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                  final exists = _sections.any((s) =>
                      s.name.trim().toLowerCase() ==
                      newSection.name.trim().toLowerCase());

                  if (exists) {
                    modalSetState(() {
                      errorText = "Section with this name already exists";
                    });
                    return;
                  }

                  setState(() {
                    // Find the correct insert index to keep 'Completed' at the end
                    final hasCompleted = _sections.any((s) => s.name == 'Completed');
                    if (hasCompleted) {
                      final insertIndex = _sections.indexWhere((s) => s.name == 'Completed');
                      _sections.insert(insertIndex, newSection);
                    } else {
                      _sections.add(newSection);
                    }
                    selectedSectionId = newSection.id;
                  });

                  widget.onSectionCreated?.call(newSection);
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _handleAddOrEdit() {
    final task = _controller.text.trim();
    if (!isFormValid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Missing Information'),
          content:
              const Text('Please enter a task, select a section, and due date.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'sectionId': selectedSectionId!,
      'task': task,
      'dueDate': selectedDateTime!.toIso8601String(),
      'taskId': widget.existingTaskId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateText = selectedDateTime != null
        ? DateFormat.yMMMMd().add_jm().format(selectedDateTime!)
        : 'Select Due Date & Time';

    // Determine the background color based on selected section or a default if none
    Color backgroundColor = Colors.white; // Default neutral background
    if (selectedSectionId != null) {
      final selectedSection = _sections.firstWhereOrNull((s) => s.id == selectedSectionId);
      if (selectedSection != null) {
        backgroundColor = selectedSection.color;
      }
    } else if (_sections.isNotEmpty) {
      // Fallback to the color of the first section if a section isn't explicitly selected
      // but sections exist (e.g., if existingSectionId was invalid and we defaulted to first)
      backgroundColor = _sections.first.color;
    }


    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              backgroundColor.withOpacity(1.0),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              if (_sections.isNotEmpty)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing
                        ? (_sections.firstWhereOrNull((s) => s.id == selectedSectionId)?.name ?? 'Edit Task')
                        : 'Add Task',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: _confirmDelete,
                    ),
                ],
              )
              else
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Task',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  
                 
                ],
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      maxLines: null,
                      minLines: 6,
                      keyboardType: TextInputType.multiline,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Type Your Task Title Here..',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    // Conditionally render SectionSelector or a placeholder
                    Expanded(
                      child: Row(
                        children: [
                          if (_sections.isNotEmpty)
                            Expanded(
                            child: SectionSelector(
                              selectedSectionId: selectedSectionId,
                              sections: _sections,
                              onSectionSelected: (id) {
                                setState(() => selectedSectionId = id);
                              },
                              onAddSection: _showCreateSectionModal, // ✅ Hooked up here
                            ),
                          )
                          else
                            Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey, width: 0.5),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add),
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              onPressed: _showCreateSectionModal,
                            ),
                          ),
                       
                          
                        ],
                      ),
                    ),

                    
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDueDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          dateText,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.event),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFormValid ? AppColors.black : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    onPressed: isFormValid ? _handleAddOrEdit : null, // Disable button if form is not valid
                    icon: Icon(
                      isEditing ? Icons.edit : Icons.add,
                      color: AppColors.white,
                    ),
                    label: Text(
                      isEditing ? 'Update Task' : 'Add Task',
                      style: AppTextStyles.buttonText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionSelector extends StatefulWidget {
  final String? selectedSectionId;
  final List<Section> sections;
  final ValueChanged<String> onSectionSelected;
  final VoidCallback onAddSection; // ✅ New: add section callback

  const SectionSelector({
    super.key,
    required this.selectedSectionId,
    required this.sections,
    required this.onSectionSelected,
    required this.onAddSection,
  });

  @override
  State<SectionSelector> createState() => _SectionSelectorState();
}

class _SectionSelectorState extends State<SectionSelector> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double itemHeight = 40.0;

    String truncateToWords(String text, int wordLimit) {
      final words = text.trim().split(RegExp(r'\s+'));
      if (words.length <= wordLimit) return text;
      return '${words.take(wordLimit).join(' ')}...';
    }

    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: widget.sections.length + 1, // ✅ +1 for the add button
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          // ✅ Last item: Add Section button
          if (index == widget.sections.length) {
            return Container(
              width: itemHeight,
              height: itemHeight,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 0.5),
              ),
              child: IconButton(
                icon: const Icon(Icons.add),
                padding: EdgeInsets.zero,
                iconSize: 20,
                onPressed: widget.onAddSection,
              ),
            );
          }

          final section = widget.sections[index];
          final isSelected = section.id == widget.selectedSectionId;

          return GestureDetector(
            onTap: () => widget.onSectionSelected(section.id),
            child: isSelected
                ? Container(
                    height: itemHeight,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: section.color,
                      borderRadius: BorderRadius.circular(itemHeight / 2),
                      border: Border.all(
                        color: section.color,
                        width: 1,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            truncateToWords(section.name, 2),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    width: itemHeight,
                    height: itemHeight,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: section.color,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

// Add this extension for convenience (you might have it elsewhere)
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
