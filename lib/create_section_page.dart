import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/section.dart';
import 'styles.dart';

class CreateSectionModal extends StatefulWidget {
  final Function(Section) onSectionCreated;

  const CreateSectionModal({super.key, required this.onSectionCreated});

  @override
  State<CreateSectionModal> createState() => _CreateSectionModalState();
}

class _CreateSectionModalState extends State<CreateSectionModal> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = Colors.red;
  final uuid = Uuid();

  void _createSection() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final section = Section(
        id: uuid.v4(),
        name: name,
        color: _selectedColor,
      );
      widget.onSectionCreated(section);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Pick Section Color",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ColorPicker(
              color: _selectedColor,
              onColorChanged: (color) => setState(() => _selectedColor = color),
              pickersEnabled: const {
                ColorPickerType.wheel: true,
                ColorPickerType.primary: false,
                ColorPickerType.accent: false,
              },
              enableTonalPalette: false,
              enableShadesSelection: false,
              showColorCode: false,
              wheelDiameter: 220,
              wheelWidth: 40,
              wheelSquareBorderRadius: 50,
            ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Type Section title here...',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(backgroundColor: _selectedColor, radius: 12),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _createSection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: const Text("Create", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
