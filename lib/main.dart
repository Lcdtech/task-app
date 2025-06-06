import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  var box = await Hive.openBox('tasks');

  // Dummy data
  box.put('Most Urgent', ['Pay electricity bill', 'Respond to client email']);
  box.put('Important', ['Prepare presentation', 'Weekly team sync']);
  box.put('Do this Later', ['Organize bookshelf', 'Buy new pens']);
  box.put('Kind of Important', ['Update LinkedIn profile', 'Review budget sheet']);
  box.put('Complete', ['Submit tax forms', 'Renew gym membership']);

  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: TodoHomePage()));
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({Key? key}) : super(key: key);

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final Map<String, bool> _expanded = {
    'Most Urgent': true,
    'Important': false,
    'Do this Later': false,
    'Kind of Important': false,
    'Complete': false,
  };

  final Box taskBox = Hive.box('tasks');

  List<String> getTasks(String category) {
    return (taskBox.get(category) as List?)?.cast<String>() ?? [];
  }

  void toggleExpand(String title) {
    setState(() {
      _expanded[title] = !(_expanded[title] ?? false);
    });
  }

  void expandAll() {
    setState(() {
      for (var key in _expanded.keys) {
        _expanded[key] = true;
      }
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: [
          const _Header(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ..._expanded.keys.map((title) => TodoGroup(
                      title: title,
                      color: _getColor(title),
                      items: getTasks(title),
                      showItems: _expanded[title] ?? true,
                      trailingCount: getTasks(title).length,
                      onToggle: () => toggleExpand(title),
                    )),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // FiltersBar fixed above the AddTask button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FiltersBar(onExpandAll: expandAll),
          ),

          const SizedBox(height: 16),

          const _AddTaskButton(),
        ],
      ),
    ),
  );
}

  Color _getColor(String title) {
    switch (title) {
      case 'Most Urgent':
        return const Color(0xFFFF7043);
      case 'Important':
        return const Color(0xFF5C6BC0);
      case 'Do this Later':
        return const Color(0xFF64B5F6);
      case 'Kind of Important':
        return const Color(0xFFBA68C8);
      case 'Complete':
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👋 Good', style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w600)),
              Text('Morning', style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
    );
  }
}

class TodoGroup extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> items;
  final int? trailingCount;
  final bool showItems;
  final VoidCallback? onToggle;

  const TodoGroup({
    Key? key,
    required this.title,
    required this.color,
    required this.items,
    this.trailingCount,
    this.showItems = true,
    this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final count = trailingCount ?? items.length;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        children: [
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            onTap: onToggle,
            title: Text(title, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600)),
            trailing: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              child: Text('$count', style: GoogleFonts.montserrat(color: color.darken(), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          if (showItems)
            ...items.map((task) => _TodoItem(text: task)).toList(),
        ],
      ),
    );
  }
}

class _TodoItem extends StatelessWidget {
  final String text;
  const _TodoItem({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Checkbox(
            value: false,
            onChanged: (_) {},
            side: const BorderSide(color: Colors.white, width: 1.6),
            checkColor: Colors.white,
            activeColor: Colors.white,
          ),
          title: Text(text, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12)),
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final VoidCallback? onExpandAll;
  const _FiltersBar({Key? key, this.onExpandAll}) : super(key: key);

  Widget _buildChip(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.montserrat(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip(Icons.color_lens_outlined, 'Color'),
        const SizedBox(width: 8),
        _buildChip(Icons.date_range_outlined, 'Due Date'),
        const Spacer(),
        _buildChip(Icons.unfold_more, 'Expand All', onTap: onExpandAll),
      ],
    );
  }
}

class _AddTaskButton extends StatelessWidget {
  const _AddTaskButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          ),
          onPressed: () {},
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('Add Task', style: GoogleFonts.montserrat(color: Colors.white)),
        ),
      ),
    );
  }
}

extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}