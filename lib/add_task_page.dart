import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/section.dart';
import 'custom_datetime_picker.dart';
import 'styles.dart'; // Assuming AppColors and AppTextStyles are defined here
import 'create_section_page.dart';
import 'package:flutter/cupertino.dart';

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
      _sections = widget.sections.where((section) => section.name != 'Completed').toList();// Use List.from to make it mutable if you plan to add to it directly
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
      _controller.text.trim().isNotEmpty;

  bool get isEditing => widget.existingTask != null;

  Future<void> _pickDueDate() async {
    final picked = await showCustomDateTimePicker(context);
    if (picked != null) {
      setState(() => selectedDateTime = picked);
    }
  }

 void _confirmDelete() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.only(left: 8,right:8, top: 16,bottom:0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // White Modal Card with content
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.only(left: 0,right:0, top: 0,bottom:0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Image.asset(
                            'assets/images/delete.png',
                            width: 154,
                            height: 154,
                          ),

                

                // Title
                const Text(
                  'Delete this task?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Padding(
                padding: EdgeInsets.symmetric(horizontal:20), // You can adjust this value
                child: Text(
                  'Once deleted, you’ll no longer see this task in your task list',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

                const SizedBox(height: 24),

              
               // Yes, Delete Button (flat with black top border)
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.black12, width: 1), // ✅ thin top border
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical:10),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDelete?.call();
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

          // Cancel button below with transparent background between
                    SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.white, // ✅ Force background color here
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



          const SizedBox(height: 8), // Space from bottom
        ],
      ),
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
                      errorText = "Category with this name already exists.";
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
            const Text('Please enter a task and select a section.'),
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

  // Use selectedDateTime if available, otherwise use current date/time
  final dueDate = selectedDateTime ?? DateTime.now();

  Navigator.pop(context, {
    'sectionId': selectedSectionId!,
    'task': task,
    'dueDate': dueDate.toIso8601String(),
    'taskId': widget.existingTaskId,
  });
}

  @override
  Widget build(BuildContext context) {
    final dateText = selectedDateTime != null
        ? DateFormat.yMMMMd().add_jm().format(selectedDateTime!)
        : 'Set Due Date & Time';

    // Determine the background color based on selected section or a default if none
    Color backgroundColor = Colors.white; // Default neutral background
    late Color textColor;
    if (selectedSectionId != null) {
      final selectedSection = _sections.firstWhereOrNull((s) => s.id == selectedSectionId);
      if (selectedSection != null) {
        backgroundColor = selectedSection.color;
        final isLight = backgroundColor.computeLuminance() > 0.5;
        textColor = isLight ? Colors.black : Colors.white;
      }
    } else if (_sections.isNotEmpty) {
      // Fallback to the color of the first section if a section isn't explicitly selected
      // but sections exist (e.g., if existingSectionId was invalid and we defaulted to first)
      backgroundColor = _sections.first.color;
    }


    return Scaffold(
      body:  SafeArea (child:Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical:8),
          child: Column(
            children: [
              
              if (_sections.isNotEmpty)
              Row(
                children: [
                 
                  Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: textColor, width: 0.3),
                  ),
                  child: IconButton(
                        //  icon: const Icon(Icons.arrow_back, color: Colors.white),
                          icon:  Icon(CupertinoIcons.back, color: textColor), 
                          onPressed: () => Navigator.pop(context),
                        ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing
                        ? (_sections.firstWhereOrNull((s) => s.id == selectedSectionId)?.name ?? 'Edit Task')
                        : 'Add New Task',
                    style:  TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  if (isEditing)
                    // IconButton(
                    //   icon: const Icon(Icons.delete, color: Colors.white),
                    //   onPressed: _confirmDelete,
                    // ),


                   GestureDetector(
                    onTap: _confirmDelete,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: textColor, width: 0.3),
                      ),
                      padding: const EdgeInsets.all(10), // Add some padding to make it more visually balanced
                      child:  Icon(
                        CupertinoIcons.delete,
                        size: 16, // You can adjust the size
                        color: textColor, // Change color as needed
                      ),
                    ),
                  ),
                  
                    
                   
                ],
              )
              else
              Row(
                children: [
                  Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 0.3),
                  ),
                  child: IconButton(
                        //  icon: const Icon(Icons.arrow_back, color: Colors.white),
                          icon: const Icon(CupertinoIcons.back, color: Colors.black), 
                          onPressed: () => Navigator.pop(context),
                        ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add New Task',
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
                    onChanged: (text) {
                      if (text.isNotEmpty && text[0] != text[0].toUpperCase()) {
                        final newText = text[0].toUpperCase() + text.substring(1);
                        final cursorPos = _controller.selection;

                        _controller.value = TextEditingValue(
                          text: newText,
                          selection: cursorPos,
                        );
                      }
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      hintText: 'Type Your Task Title Here...',
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
                  onPressed: isFormValid ? _handleAddOrEdit : null,
                  icon: Icon(
                    isEditing ? Icons.edit : Icons.add,
                    size: isEditing ? 15 : 20,
                    color: isFormValid ? Colors.white:Colors.black,
                  ),
                  label: Text(
                    isEditing ? 'Update Task' : 'Add Task',
                    style: isFormValid ?AppTextStyles.buttonText :AppTextStyles.buttonText.copyWith(color:Colors.black),
                  ),
                ),

                ),
              ),
            ],
          ),
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
          final isLight = section.color.computeLuminance() > 0.5;
          final textColor = isLight ? Colors.black : Colors.white;
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
                           Icon(
                            Icons.check,
                            size: 20,
                            color: textColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            truncateToWords(section.name, 2),
                            style:  TextStyle(
                              fontSize: 16,
                              color: textColor,
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
