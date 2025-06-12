import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/section.dart';

class AddTaskPage extends StatefulWidget {
  final List<Section> sections;

  const AddTaskPage({Key? key, required this.sections}) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _controller = TextEditingController();
  String? selectedSectionId;
  DateTime? selectedDate;

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = selectedDate != null
        ? DateFormat.yMMMMd().format(selectedDate!)
        : 'Select Due Date';

    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
           DropdownButtonFormField<String>(
              isExpanded: true,
              value: selectedSectionId,
              hint: const Text('Select Section'),
              items: widget.sections.map((section) {
                return DropdownMenuItem(
                  value: section.id,
                  child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: section.color,
                          radius: 6,
                        ),
                        const SizedBox(width: 8),
                        Text(section.name),
                      ],
                    ),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedSectionId = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Task',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              onTap: _pickDueDate,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: Colors.grey[200],
              title: Text(dateText),
              trailing: const Icon(Icons.calendar_today_outlined),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                final task = _controller.text.trim();
                if (selectedSectionId != null && task.isNotEmpty) {
                  Navigator.pop(context, {
                    'sectionId': selectedSectionId!,
                    'task': task,
                    'dueDate': selectedDate?.toIso8601String(),
                  });
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Save Task'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}
