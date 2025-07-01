import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../models/section.dart';
import 'styles.dart';

class EditSectionModal extends StatefulWidget {
  final Section section;
  final Function(Section) onSectionUpdated;
  final String? errorText;
  final void Function(String)? onError;

  const EditSectionModal({
    super.key,
    required this.section,
    required this.onSectionUpdated,
    this.errorText,
    this.onError,
  });

  @override
  State<EditSectionModal> createState() => _EditSectionModalState();
}

class _EditSectionModalState extends State<EditSectionModal> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  String? _errorMessage;
  bool _isButtonEnabled = false;
  bool _isCompletedSection = false;

  @override
  void initState() {
    super.initState();
    _isCompletedSection = widget.section.name == 'Completed';
    _nameController = TextEditingController(text: widget.section.name);
    _selectedColor = widget.section.color;
    _errorMessage = widget.errorText;
    _isButtonEnabled = _nameController.text.trim().isNotEmpty;
    
    if (!_isCompletedSection) {
      _nameController.addListener(() {
        final isNotEmpty = _nameController.text.trim().isNotEmpty;
        if (_isButtonEnabled != isNotEmpty) {
          setState(() {
            _isButtonEnabled = isNotEmpty;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant EditSectionModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != oldWidget.errorText) {
      setState(() {
        _errorMessage = widget.errorText;
      });
    }
  }

  void _updateSection() {
    final name = _nameController.text.trim();

    if (!_isCompletedSection && name.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a section name.";
      });
      widget.onError?.call(_errorMessage!);
      return;
    }

    final updatedSection = Section(
      id: widget.section.id,
      name: _isCompletedSection ? 'Completed' : name,
      color: _selectedColor,
      isFixed: widget.section.isFixed,
      tasks: widget.section.tasks,
    );

    widget.onSectionUpdated(updatedSection);
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
              Text(
                _isCompletedSection ? "Edit Completed List Color" : "Edit Category",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 0.3),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
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
              child: _isCompletedSection 
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Completed List',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : TextField(
                      controller: _nameController,
                      style: TextStyle(color: textColor),
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type Category title here...',
                        hintStyle: TextStyle(color: textColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (text) {
                        if (text.isNotEmpty && text[0] != text[0].toUpperCase()) {
                          final capitalized = text[0].toUpperCase() + text.substring(1);
                          final cursorPos = _nameController.selection;
                          _nameController.value = TextEditingValue(
                            text: capitalized,
                            selection: cursorPos,
                          );
                        }

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
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled) && !_isCompletedSection) {
                      return Colors.grey.shade400;
                    }
                    return AppColors.black;
                  },
                ),
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled) && !_isCompletedSection) {
                      return Colors.white70;
                    }
                    return AppColors.white;
                  },
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
              onPressed: _isCompletedSection || _isButtonEnabled ? _updateSection : null,
              label: Text(
                _isCompletedSection ? "Update Color" : "Update", 
                style: TextStyle(
                  color: (_isCompletedSection || _isButtonEnabled) ? Colors.white : Colors.black
                ),
              ),
              icon: Icon(
                Icons.edit,
                color: (_isCompletedSection || _isButtonEnabled) ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}