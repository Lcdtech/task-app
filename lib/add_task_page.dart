import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/section.dart';
import 'custom_datetime_picker.dart';
import 'styles.dart';

class AddTaskPage extends StatefulWidget {
  final List<Section> sections;

  const AddTaskPage({Key? key, required this.sections}) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _controller = TextEditingController();
  String? selectedSectionId;
  DateTime? selectedDateTime;

  Future<void> _pickDueDate() async {
  final picked = await showCustomDateTimePicker(context);
  if (picked != null) {
    setState(() {
      selectedDateTime = picked;
    });
  }
}



  @override
  Widget build(BuildContext context) {
    final dateText = selectedDateTime != null
      ? DateFormat.yMMMMd().add_jm().format(selectedDateTime!)
      : 'Select Due Date & Time';

    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
           
            TextField(
            controller: _controller,
            maxLines: null,
            minLines: 6,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: '| Type Your Task Title Here..',
              hintStyle: TextStyle(color: Colors.grey),
             border: OutlineInputBorder(), 
              isCollapsed: true,        // 👈 Reduces vertical padding
              contentPadding: EdgeInsets.all(16), // Optional: removes padding
            ),
            style: const TextStyle(fontSize: 16), // Optional: your custom style
          ),


            const SizedBox(height: 16),
            Expanded(
              child: SectionSelector(
                selectedSectionId: selectedSectionId,
                sections: widget.sections,
                onSectionSelected: (id) {
                  setState(() => selectedSectionId = id);
                },
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              onTap: _pickDueDate,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: Colors.grey[200],
              title: Text(dateText),
              trailing: const Icon(Icons.event),
            ),
            const SizedBox(height: 16),
            
            Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                onPressed: () {
                      final task = _controller.text.trim();
                      if (selectedSectionId != null && task.isNotEmpty && selectedDateTime != null) {
                        Navigator.pop(context, {
                          'sectionId': selectedSectionId!,
                          'task': task,
                          'dueDate': selectedDateTime!.toIso8601String(), // Single full DateTime
                        });
                      }
                    },
                icon: const Icon(Icons.add, color: AppColors.white),
                label: Text('Add Task', style: AppTextStyles.buttonText),
              ),
            ),
          )
            
          ],
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
    _scrollController.dispose(); // Clean up
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.sections.length,
        itemBuilder: (context, index) {
          final section = widget.sections[index];
          final isSelected = section.id == widget.selectedSectionId;

          return GestureDetector(
            onTap: () => widget.onSectionSelected(section.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: section.color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check, size: 20, color: Colors.white),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


