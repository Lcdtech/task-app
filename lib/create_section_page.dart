import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/section.dart';
import 'styles.dart';

class CreateSectionModal extends StatefulWidget {
  final Function(Section) onSectionCreated;
  final String? errorText;
  final void Function(String)? onError;

  const CreateSectionModal({
    super.key,
    required this.onSectionCreated,
    this.errorText,
    this.onError,
  });

  @override
  State<CreateSectionModal> createState() => _CreateSectionModalState();
}

class _CreateSectionModalState extends State<CreateSectionModal> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = Colors.red;
  String? _errorMessage;
  bool _isButtonEnabled = false;

  void _createSection() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a section name.";
      });
      widget.onError?.call(_errorMessage!);
      return;
    }

    final newSection = Section(
      id: Uuid().v4(),
      name: name,
      color: _selectedColor,
      isFixed: false,
      tasks: [],
    );

    widget.onSectionCreated(newSection);
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final isNotEmpty = _nameController.text.trim().isNotEmpty;
      if (_isButtonEnabled != isNotEmpty) {
        setState(() {
          _isButtonEnabled = isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Create New Section",
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
            enableShadesSelection: true,
            showColorCode: false,
            wheelDiameter: 220,
            wheelWidth: 40,
            wheelSquareBorderRadius: 50,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Type Section title here...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              errorText: widget.errorText ?? _errorMessage,
              filled: true,
              fillColor: _selectedColor.withOpacity(1),
            ),
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
              widget.onError?.call('');
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isButtonEnabled ? _createSection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child:  Text("Create", style: _isButtonEnabled  ? TextStyle(color: Colors.white) : TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}

