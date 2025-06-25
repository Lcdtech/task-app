import 'package:flutter/material.dart';

class OverlappingTaskList extends StatelessWidget {
  final List<Widget> taskGroups;
  const OverlappingTaskList({Key? key, required this.taskGroups})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < taskGroups.length; i++)
          Transform.translate(
            offset: Offset(0, -25.0 * i),
            child: taskGroups[i],
          ),
      ],
    );
  }
}