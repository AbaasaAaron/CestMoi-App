import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const CestMoiApp());
}

class Task {
  String name;
  bool isCompleted;
  Task({required this.name, this.isCompleted = false});

  Map<String, dynamic> toJson() => {'name': name, 'isCompleted': isCompleted};
  factory Task.fromJson(Map<String, dynamic> json) => Task(name: json['name'], isCompleted: json['isCompleted']);
}

class CestMoiApp extends StatelessWidget {
  const CestMoiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "C'est moi",
      // THEME: Dark, professional Teal & Grey
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008080), // Teal
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
      ),
      home: const CalendarScreen(),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<Task>> taskDatabase = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(
      taskDatabase.map((key, value) => MapEntry(key, value.map((t) => t.toJson()).toList())),
    );
    await prefs.setString('user_tasks', encodedData);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('user_tasks');
    if (savedData != null) {
      Map<String, dynamic> decodedData = jsonDecode(savedData);
      setState(() {
        taskDatabase = decodedData.map((key, value) => MapEntry(
              key,
              (value as List).map((t) => Task.fromJson(t)).toList(),
            ));
      });
    }
  }

  void _showChecklist(DateTime selectedDate) {
    String dateKey = selectedDate.toIso8601String().split('T')[0];
    if (taskDatabase[dateKey] == null) taskDatabase[dateKey] = [];
    List<Task> todaysTasks = taskDatabase[dateKey]!;
    TextEditingController taskController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Logic to calculate progress
            int completedCount = todaysTasks.where((t) => t.isCompleted).length;
            int totalCount = todaysTasks.length;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Checklist", style: TextStyle(fontSize: 14, color: Colors.teal.shade700, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Text(dateKey, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    
                    // PROGRESS INDICATOR
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        totalCount == 0 ? "No tasks yet" : "$completedCount of $totalCount tasks completed",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ),
                    const Divider(height: 30),
                    
                    Expanded(
                      child: todaysTasks.isEmpty
                          ? const Center(child: Icon(Icons.playlist_add, size: 60, color: Colors.black12))
                          : ListView.builder(
                              itemCount: todaysTasks.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: todaysTasks[index].isCompleted ? Colors.transparent : Colors.teal.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    leading: Checkbox(
                                      value: todaysTasks[index].isCompleted,
                                      activeColor: Colors.teal,
                                      onChanged: (bool? val) {
                                        setModalState(() => todaysTasks[index].isCompleted = val ?? false);
                                        _saveTasks();
                                        setState(() {}); // Updates main screen if needed
                                      },
                                    ),
                                    title: Text(
                                      todaysTasks[index].name,
                                      style: TextStyle(
                                        decoration: todaysTasks[index].isCompleted ? TextDecoration.lineThrough : null,
                                        color: todaysTasks[index].isCompleted ? Colors.grey : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                                      onPressed: () {
                                        setModalState(() => todaysTasks.removeAt(index));
                                        _saveTasks();
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    
                    // INPUT FIELD
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: TextField(
                        controller: taskController,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: "What needs to be done?",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add_task, color: Colors.teal),
                            onPressed: () {
                              if (taskController.text.isNotEmpty) {
                                setModalState(() => todaysTasks.add(Task(name: taskController.text)));
                                taskController.clear();
                                _saveTasks();
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("C'EST MOI", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: Colors.teal.shade200, shape: BoxShape.circle),
            selectedDecoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
            markerDecoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
            _showChecklist(selectedDay);
          },
        ),
      ),
    );
  }
}