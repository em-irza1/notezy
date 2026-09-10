import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeeklyPlannerScreen extends StatefulWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  State<WeeklyPlannerScreen> createState() => _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends State<WeeklyPlannerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final List<String> _days = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _timeSlots = const ['Morning', 'Afternoon', 'Evening'];
  final Map<String, List<String>> _plans = {};
  final Map<String, List<String>> _timetable = {};
  final List<_Reminder> _reminders = [];
  Timer? _reminderTimer;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAll();
    _reminderTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _checkReminders(),
    );
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    for (final day in _days) {
      _plans[day] = prefs.getStringList('notesy_plan_$day') ?? <String>[];
      for (final slot in _timeSlots) {
        final key = '$day • $slot';
        _timetable[key] =
            prefs.getStringList('notesy_timetable_$key') ?? <String>[];
      }
    }

    final saved = prefs.getStringList('notesy_reminders') ?? <String>[];
    _reminders.clear();
    for (final raw in saved) {
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          final when = DateTime.tryParse(data['when']?.toString() ?? '');
          if (when != null) {
            _reminders.add(
              _Reminder(
                title: data['title']?.toString() ?? 'Notesy reminder',
                when: when,
                body: data['body']?.toString() ?? '',
              ),
            );
          }
        }
      } catch (_) {
        // Ignore old/corrupt reminder entries instead of breaking the screen.
      }
    }

    if (mounted) {
      setState(() => _loaded = true);
      _checkReminders();
    }
  }

  Future<void> _saveList(String key, List<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, List<String>.from(values));
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'notesy_reminders',
      _reminders
          .map(
            (r) => jsonEncode({
              'title': r.title,
              'when': r.when.toIso8601String(),
              'body': r.body,
            }),
          )
          .toList(),
    );
  }

  Future<void> _addPlanItem(String day) async {
    final controller = TextEditingController();
    final value = await _showTextDialog(
      title: 'Add to $day',
      hint: 'e.g. Finish assignment',
      controller: controller,
    );
    controller.dispose();

    if (value == null || value.isEmpty) return;
    final list = _plans.putIfAbsent(day, () => <String>[]);
    setState(() => list.add(value));
    await _saveList('notesy_plan_$day', list);
  }

  Future<void> _editPlanItem(String day, int index) async {
    final list = _plans[day] ?? <String>[];
    if (index >= list.length) return;

    final controller = TextEditingController(text: list[index]);
    final value = await _showTextDialog(
      title: 'Edit plan',
      hint: 'Update your plan',
      controller: controller,
    );
    controller.dispose();

    if (value == null || value.isEmpty) return;
    setState(() => list[index] = value);
    await _saveList('notesy_plan_$day', list);
  }

  Future<void> _deletePlanItem(String day, int index) async {
    final list = _plans[day] ?? <String>[];
    if (index >= list.length) return;
    setState(() => list.removeAt(index));
    await _saveList('notesy_plan_$day', list);
  }

  Future<void> _addTimetableItem(String day, String slot) async {
    final key = '$day • $slot';
    final controller = TextEditingController();
    final value = await _showTextDialog(
      title: 'Add to $slot',
      hint: 'e.g. Flutter class',
      controller: controller,
    );
    controller.dispose();

    if (value == null || value.isEmpty) return;
    final list = _timetable.putIfAbsent(key, () => <String>[]);
    setState(() => list.add(value));
    await _saveList('notesy_timetable_$key', list);
  }

  Future<void> _editTimetableItem(String day, String slot, int index) async {
    final key = '$day • $slot';
    final list = _timetable[key] ?? <String>[];
    if (index >= list.length) return;

    final controller = TextEditingController(text: list[index]);
    final value = await _showTextDialog(
      title: 'Edit timetable item',
      hint: 'Update this slot',
      controller: controller,
    );
    controller.dispose();

    if (value == null || value.isEmpty) return;
    setState(() => list[index] = value);
    await _saveList('notesy_timetable_$key', list);
  }

  Future<void> _deleteTimetableItem(String day, String slot, int index) async {
    final key = '$day • $slot';
    final list = _timetable[key] ?? <String>[];
    if (index >= list.length) return;
    setState(() => list.removeAt(index));
    await _saveList('notesy_timetable_$key', list);
  }

  Future<String?> _showTextDialog({
    required String title,
    required String hint,
    required TextEditingController controller,
  }) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => _CuteDialog(
        title: title,
        child: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addReminder({String? suggestedTitle}) async {
    final titleController = TextEditingController(text: suggestedTitle ?? '');
    final bodyController = TextEditingController();
    DateTime selected = DateTime.now().add(const Duration(minutes: 5));

    final result = await showDialog<_ReminderDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => _CuteDialog(
          title: 'Set a reminder',
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Reminder title',
                    hintText: 'Study, meeting, task...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    hintText: 'What should Notesy remind you about?',
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('Reminder time'),
                  subtitle: Text(_formatDateTime(selected)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: selected,
                    );
                    if (date == null || !dialogContext.mounted) return;
                    final time = await showTimePicker(
                      context: dialogContext,
                      initialTime: TimeOfDay.fromDateTime(selected),
                    );
                    if (time == null) return;
                    setDialogState(() {
                      selected = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'You can choose AM or PM from the time picker.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty || !selected.isAfter(DateTime.now())) return;
                Navigator.pop(
                  dialogContext,
                  _ReminderDraft(
                    title: title,
                    body: bodyController.text.trim().isEmpty
                        ? 'Your Notesy reminder is due.'
                        : bodyController.text.trim(),
                    when: selected,
                  ),
                );
              },
              child: const Text('Set reminder'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    bodyController.dispose();

    if (result == null) return;

    setState(() {
      _reminders.add(
        _Reminder(title: result.title, when: result.when, body: result.body),
      );
      _reminders.sort((a, b) => a.when.compareTo(b.when));
    });
    await _saveReminders();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set for ${_formatDateTime(result.when)}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _checkReminders() {
    if (!mounted || !_loaded) return;

    final now = DateTime.now();
    final due = <_Reminder>[];

    for (final reminder in _reminders) {
      if (!reminder.fired && !reminder.when.isAfter(now)) {
        reminder.fired = true;
        due.add(reminder);
      }
    }

    if (due.isEmpty) return;

    // The timer can fire in the middle of a Flutter frame. Showing a SnackBar
    // immediately from context at that moment can trigger Flutter's
    // `_dependents.isEmpty` assertion while the inherited tree is changing.
    // Wait until the current frame is finished before touching the Scaffold.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      for (final reminder in due) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('${reminder.title}\n${reminder.body}')),
              ],
            ),
          ),
        );
      }

      if (mounted) setState(() {});
    });
  }

  Future<void> _deleteReminder(_Reminder reminder) async {
    setState(() => _reminders.remove(reminder));
    await _saveReminders();
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF292226) : const Color(0xFFFFFCF5);
    final ink = dark ? const Color(0xFFFFE8EF) : const Color(0xFF66515A);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text(
          'Weekly Planner',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: ink),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFFB85C7A),
          unselectedLabelColor: dark ? Colors.white54 : const Color(0xFF9A858E),
          indicatorColor: const Color(0xFFB85C7A),
          tabs: const [
            Tab(icon: Icon(Icons.calendar_view_week_rounded), text: 'Planner'),
            Tab(icon: Icon(Icons.table_chart_rounded), text: 'Timetable'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_plannerTab(dark, ink), _timetableTab(dark, ink)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFDCE8),
        foregroundColor: const Color(0xFF806572),
        icon: const Icon(Icons.notifications_active_rounded),
        label: const Text('Reminder'),
        onPressed: _addReminder,
      ),
    );
  }

  Widget _plannerTab(bool dark, Color ink) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      children: [
        _decorHeader(
          'Plan your week',
          'Add tasks, goals and little plans for each day.',
          Icons.auto_awesome_rounded,
          dark,
          ink,
        ),
        const SizedBox(height: 14),
        for (final day in _days) _dayCard(day, dark, ink),
        const SizedBox(height: 8),
        _reminderCard(dark, ink),
      ],
    );
  }

  Widget _timetableTab(bool dark, Color ink) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      children: [
        _decorHeader(
          'My Timetable',
          'Organize what happens in the morning, afternoon and evening.',
          Icons.schedule_rounded,
          dark,
          ink,
        ),
        const SizedBox(height: 14),
        for (final day in _days) _timetableDay(day, dark, ink),
      ],
    );
  }

  Widget _dayCard(String day, bool dark, Color ink) {
    final items = _plans[day] ?? <String>[];
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: dark ? const Color(0xFF292226) : const Color(0xFFFFFCF5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: dark ? Colors.white10 : const Color(0xFFF0D7DF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Column(
          children: [
            Row(
              children: [
                _dayIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    day,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add plan',
                  icon: const Icon(
                    Icons.add_circle_rounded,
                    color: Color(0xFFB85C7A),
                  ),
                  onPressed: () => _addPlanItem(day),
                ),
                IconButton(
                  tooltip: 'Add reminder',
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFFB85C7A),
                  ),
                  onPressed: () =>
                      _addReminder(suggestedTitle: '$day reminder'),
                ),
              ],
            ),
            if (items.isNotEmpty)
              for (int i = 0; i < items.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 54),
                  leading: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                    color: Color(0xFFB85C7A),
                  ),
                  title: Text(items[i], style: GoogleFonts.nunito(color: ink)),
                  onTap: () => _editPlanItem(day, i),
                  trailing: IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => _deletePlanItem(day, i),
                  ),
                )
            else
              Padding(
                padding: const EdgeInsets.only(left: 54, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nothing planned yet.',
                    style: GoogleFonts.nunito(
                      color: dark ? Colors.white54 : const Color(0xFF9A858E),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _timetableDay(String day, bool dark, Color ink) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: dark ? const Color(0xFF292226) : const Color(0xFFFFFCF5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dark ? Colors.white10 : const Color(0xFFF0D7DF),
        ),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.event_note_rounded, color: Color(0xFFB85C7A)),
        title: Text(
          day,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: ink),
        ),
        children: [
          for (final slot in _timeSlots) _timeSlot(day, slot, dark, ink),
        ],
      ),
    );
  }

  Widget _timeSlot(String day, String slot, bool dark, Color ink) {
    final key = '$day • $slot';
    final items = _timetable[key] ?? <String>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 8, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF332A2F) : const Color(0xFFFFF3E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: Color(0xFFB85C7A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slot,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add timetable item',
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFFB85C7A),
                  ),
                  onPressed: () => _addTimetableItem(day, slot),
                ),
                IconButton(
                  tooltip: 'Add reminder',
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFFB85C7A),
                  ),
                  onPressed: () => _addReminder(suggestedTitle: '$slot - $day'),
                ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 28, right: 8, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No timetable item yet.',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: dark ? Colors.white54 : const Color(0xFF9A858E),
                    ),
                  ),
                ),
              )
            else
              for (int i = 0; i < items.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 28),
                  leading: const Icon(
                    Icons.circle,
                    size: 8,
                    color: Color(0xFFB85C7A),
                  ),
                  title: Text(items[i], style: GoogleFonts.nunito(color: ink)),
                  onTap: () => _editTimetableItem(day, slot, i),
                  trailing: IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => _deleteTimetableItem(day, slot, i),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _reminderCard(bool dark, Color ink) {
    return Card(
      elevation: 0,
      color: dark ? const Color(0xFF292226) : const Color(0xFFFFFCF5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: dark ? Colors.white10 : const Color(0xFFF0D7DF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFB85C7A),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reminders',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                TextButton(onPressed: _addReminder, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 8),
            if (_reminders.isEmpty)
              Text(
                'No reminders yet. Tap Add or the pink Reminder button.',
                style: GoogleFonts.nunito(
                  color: dark ? Colors.white54 : const Color(0xFF9A858E),
                ),
              )
            else
              for (final r in List<_Reminder>.from(_reminders))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.favorite_border_rounded,
                    color: Color(0xFFB85C7A),
                  ),
                  title: Text(
                    r.title,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  subtitle: Text(
                    '${_formatDateTime(r.when)}\n${r.body}',
                    style: GoogleFonts.nunito(
                      color: dark ? Colors.white60 : const Color(0xFF9A858E),
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete reminder',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _deleteReminder(r),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _dayIcon() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE3EC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.favorite_rounded, color: Color(0xFFB85C7A)),
    );
  }

  Widget _decorHeader(
    String title,
    String subtitle,
    IconData icon,
    bool dark,
    Color ink,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF292226) : const Color(0xFFFFF3E9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: dark ? Colors.white10 : const Color(0xFFF0D7DF),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -12,
            right: 8,
            child: Text(
              '♥',
              style: TextStyle(
                fontSize: 28,
                color: const Color(0xFFF0C9CE).withValues(alpha: .75),
              ),
            ),
          ),
          Positioned(
            bottom: -12,
            left: 24,
            child: Text(
              '♥',
              style: TextStyle(
                fontSize: 20,
                color: const Color(0xFFE3A9B4).withValues(alpha: .75),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE3EC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFFB85C7A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        color: dark ? Colors.white60 : const Color(0xFF9A858E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderDraft {
  final String title;
  final DateTime when;
  final String body;

  const _ReminderDraft({
    required this.title,
    required this.when,
    required this.body,
  });
}

class _Reminder {
  final String title;
  final DateTime when;
  final String body;
  bool fired = false;

  _Reminder({required this.title, required this.when, required this.body});
}

class _CuteDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;

  const _CuteDialog({
    required this.title,
    required this.child,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: dark ? const Color(0xFF292226) : const Color(0xFFFFFCF5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
      ),
      content: child,
      actions: actions,
    );
  }
}

String _formatDateTime(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.day}/${value.month}/${value.year} • $hour:$minute $period';
}
