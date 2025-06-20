import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/section.dart';
import 'custom_datetime_picker.dart';
import 'styles.dart';
import 'create_section_page.dart';

class AddTaskPage extends StatefulWidget {
  final List<Section> sections;
  final String? existingTask;
  final DateTime? existingDate;
  final String? existingSectionId;
  final String? existingTaskId;
  final VoidCallback? onDelete;
  final Function(Section)? onSectionCreated; // Add callback for section creation

  const AddTaskPage({
    Key? key,
    required this.sections,
    this.existingTask,
    this.existingDate,
    this.existingSectionId,
    this.existingTaskId,
    this.onDelete,
    this.onSectionCreated, // Add this parameter
  }) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _controller = TextEditingController();
  String? selectedSectionId;
  DateTime? selectedDateTime;

  bool get isFormValid =>
      selectedSectionId != null &&
      selectedDateTime != null &&
      _controller.text.trim().isNotEmpty;

  bool get isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.existingTask ?? '';
    selectedDateTime = widget.existingDate;
    selectedSectionId = widget.existingSectionId ??
        (widget.sections.isNotEmpty ? widget.sections.first.id : null);
  }

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
      builder: (context) => CreateSectionModal(
        onSectionCreated: (newSection) {
          // Call the parent's callback if provided
          widget.onSectionCreated?.call(newSection);
          
          // Update the local state to select the new section
          setState(() {
            selectedSectionId = newSection.id;
          });
          
          Navigator.pop(context); // Close the modal
        },
      ),
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

    final selectedColor = widget.sections
        .firstWhere(
          (s) => s.id == selectedSectionId,
          orElse: () => widget.sections.isNotEmpty 
              ? widget.sections.first 
              : Section(id: 'default', name: 'Default', color: Colors.grey, isFixed: false, tasks: []),
        )
        .color;

    return Scaffold(
  body: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          selectedColor.withOpacity(1.0),
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
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? widget.sections.firstWhere((s) => s.id == selectedSectionId, orElse: () => widget.sections.first).name : 'Add Task',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (isEditing)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _confirmDelete,
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
                Expanded(
                  child: SectionSelector(
                    selectedSectionId: selectedSectionId,
                    sections: widget.sections,
                    onSectionSelected: (id) {
                      setState(() => selectedSectionId = id);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showCreateSectionModal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDueDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                onPressed: _handleAddOrEdit,
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

  const SectionSelector({
    super.key,
    required this.selectedSectionId,
    required this.sections,
    required this.onSectionSelected,
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
    return SizedBox(
      height: 64,
      child: widget.sections.isEmpty
          ? const Center(child: Text('No sections available'))
          : ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: widget.sections.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final section = widget.sections[index];
                final isSelected = section.id == widget.selectedSectionId;

                return GestureDetector(
                  onTap: () => widget.onSectionSelected(section.id),
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                section.color.withOpacity(0.9),
                                section.color.withOpacity(0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: section.color,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.white54, Colors.transparent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, size: 20, color: Colors.white),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}