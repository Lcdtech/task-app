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
    _errorMessage = widget.errorText;
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
void didUpdateWidget(covariant CreateSectionModal oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.errorText != oldWidget.errorText) {
    setState(() {
      _errorMessage = widget.errorText;
    });
  }
}

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
     final isLight = _selectedColor.computeLuminance() > 0.5;
     final textColor = isLight ? Colors.black : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
          children: [
            const Text(
              "Create New Category",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                  // Handle close action here
                   Navigator.pop(context);
                },
                child:Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 0.3),
              ),
              child:  const Padding(
                  padding: EdgeInsets.all(8.0), // Adjust padding for better icon fit
                  child: Icon(
                    Icons.close,
                    size: 20, // Adjust icon size as needed
                    color: Colors.black, // Change color if needed
                  ),
                ),
              
            )
            ),
          ],
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
          Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _selectedColor.withOpacity(1),
            border: Border.all(color: _selectedColor.withOpacity(1)),
          ),
          child: Center(
            child: TextField(
            controller: _nameController,
            style:  TextStyle(color: textColor),
            maxLines: 1,
            decoration:  InputDecoration(
              hintText: 'Type Category title here...',
              hintStyle: TextStyle(color: textColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (text) {
              // Capitalize first character if needed
              if (text.isNotEmpty && text[0] != text[0].toUpperCase()) {
                final capitalized = text[0].toUpperCase() + text.substring(1);
                final cursorPos = _nameController.selection;

                _nameController.value = TextEditingValue(
                  text: capitalized,
                  selection: cursorPos,
                );
              }

              // Clear error message if any
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
              widget.onError?.call('');
            },
          ),
          ),
        ),
        if (_errorMessage != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 13,
            ),
          ),
        ),
          const SizedBox(height: 16),
          // SizedBox(
          //   width: double.infinity,
          //   height: 50,
          //   child: ElevatedButton(
          //     onPressed: _isButtonEnabled ? _createSection : null,
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.black,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(32),
          //       ),
          //     ),
          //     child:  Text("Create", style: _isButtonEnabled  ? TextStyle(color: Colors.white) : TextStyle(color: Colors.black)),
          //   ),
          // ),
          SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.grey.shade400; // custom disabled background
                        }
                        return AppColors.black; // enabled background
                      },
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.white70; // custom disabled text/icon color
                        }
                        return AppColors.white; // enabled text/icon color
                      },
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                  onPressed: _isButtonEnabled ? _createSection : null,
                  label: Text("Create", style: _isButtonEnabled  ? TextStyle(color: Colors.white) : TextStyle(color: Colors.black)),
                ),

                ),
        ],
      ),
    );
  }
}

