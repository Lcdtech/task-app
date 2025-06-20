import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // For core Hive functionality
import 'package:hive_flutter/hive_flutter.dart'; // For Flutter-specific initialization
import 'todo_home_page.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
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
  //await Hive.deleteBoxFromDisk('sections');
  await Hive.openBox('sections');

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TodoHomePage(),
  ));
}


