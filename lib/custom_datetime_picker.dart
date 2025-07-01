import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

Future<DateTime?> showCustomDateTimePicker(BuildContext context) async {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String _formatTimeAMPM(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
  }

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: StatefulBuilder(builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
                focusedDay: selectedDate,
                selectedDayPredicate: (day) =>
                    day.year == selectedDate.year &&
                    day.month == selectedDate.month &&
                    day.day == selectedDate.day,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    selectedDate = selectedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  todayDecoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
              onPressed: () async {
                final picked = await showCustomTimePicker(context, selectedTime);
                if (picked != null) {
                  setState(() {
                    selectedTime = picked;
                  });
                }
              },
              icon: const Icon(Icons.access_time, color: Colors.black),
              label: Text(
                'Pick Time (${_formatTimeAMPM(selectedTime)})', // 👈 AM/PM format
                style: const TextStyle(color: Colors.black),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final fullDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    Navigator.pop(context, fullDateTime);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          );
        }),
      );
    },
  );
}

Future<TimeOfDay?> showCustomTimePicker(BuildContext context, TimeOfDay initialTime) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    initialEntryMode: TimePickerEntryMode.dial,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            hourMinuteColor: Colors.black,
            hourMinuteTextColor: Colors.white,
            dayPeriodColor: MaterialStateColor.resolveWith((states) =>
                states.contains(MaterialState.selected) ? Colors.black : Colors.grey[200]!),
            dayPeriodTextColor: MaterialStateColor.resolveWith((states) =>
                states.contains(MaterialState.selected) ? Colors.white : Colors.black),
            dialHandColor: Colors.black,
            dialBackgroundColor: Colors.grey[200],
            dialTextColor: MaterialStateColor.resolveWith((states) =>
                states.contains(MaterialState.selected) ? Colors.white : Colors.black),
            entryModeIconColor: Colors.black,
            helpTextStyle: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        ),
      );
    },
  );
}





