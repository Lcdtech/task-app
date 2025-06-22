import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // For core Hive functionality
import 'package:hive_flutter/hive_flutter.dart'; // For Flutter-specific initialization
import 'package:uuid/uuid.dart';
import 'todo_home_page.dart';
import '../models/section.dart';
import 'styles.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
   List<Section> sections = [];
   late Box sectionBox;
   final uuid = Uuid(); 
  // if (sectionBox.isEmpty) {
  //   const uuid = Uuid();
  //   await sectionBox.put('list', [
  //     {
  //       'id': uuid.v4(),
  //       'name': 'Most Urgent',
  //       'color': Colors.red.value,
  //       'isFixed': false,
  //       'tasks': <Map<String, dynamic>>[],
  //     },
  //     {
  //       'id': uuid.v4(),
  //       'name': 'Important',
  //       'color': Colors.orange.value,
  //       'isFixed': false,
  //       'tasks': [],
  //     },
  //     {
  //       'id': uuid.v4(),
  //       'name': 'Do this Later',
  //       'color': Colors.blue.value,
  //       'isFixed': false,
  //       'tasks': [],
  //     },
  //     {
  //       'id': uuid.v4(),
  //       'name': 'Kind of Important',
  //       'color': Colors.purple.value,
  //       'isFixed': false,
  //       'tasks': [],
  //     },
  //     {
  //       'id': uuid.v4(),
  //       'name': 'Complete',
  //       'color': Colors.green.value,
  //       'isFixed': true,
  //       'tasks': [],
  //     },
  //   ]);
  // }
  await Hive.initFlutter();
  await Hive.deleteBoxFromDisk('sections');
  //await Hive.openBox('sections');
  sectionBox = await Hive.openBox('sections');
   final stored = sectionBox.get('list') ?? [];
    sections = (stored as List)
        .map((e) => Section.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    // Ensure the "Complete" section is always present and at the end
    if (sections.where((s) => s.name == 'Completed').isEmpty) {
      sections.add(Section(
        id: uuid.v4(),
        name: 'Completed',
        color: AppColors.complete,
        isFixed: true,
      ));
      sectionBox.put('list', sections.map((s) => s.toMap()).toList());
    } else {
      // Ensure 'Complete' is always the last fixed item if it exists
      final completeSectionIndex =
          sections.indexWhere((s) => s.name == 'Completed');
      if (completeSectionIndex != -1 &&
          completeSectionIndex != sections.length - 1) {
        final completeSection = sections.removeAt(completeSectionIndex);
        sections.add(completeSection);
        sectionBox.put('list', sections.map((s) => s.toMap()).toList());
      }
    }

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TodoHomePage(),
  ));
}


