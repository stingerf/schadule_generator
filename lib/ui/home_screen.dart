import 'package:flutter/material.dart';
import 'package:schadule_generator/services/gemini_service.dart';
import 'schedule_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> tasks = [];
  final TextEditingController taskController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  DateTime? deadline;
  String? priority;
  String? category;
  bool isLoading = false;
  bool isDarkMode = false;

  void _addTask() {
    if (taskController.text.isNotEmpty &&
        durationController.text.isNotEmpty &&
        priority != null &&
        category != null) {
      setState(() {
        tasks.add({
          "name": taskController.text,
          "priority": priority!,
          "category": category!,
          "duration": int.tryParse(durationController.text) ?? 30,
          "deadline": deadline != null
              ? "${deadline!.day}/${deadline!.month}/${deadline!.year}"
              : "Tidak Ada",
          "completed": false,
        });
      });
      taskController.clear();
      durationController.clear();
      deadline = null;
    }
  }

  void _clearTasks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus Semua Tugas?"),
        content: Text("Tindakan ini tidak bisa dibatalkan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal")),
          TextButton(
            onPressed: () {
              setState(() => tasks.clear());
              Navigator.pop(context);
            },
            child: Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editTask(int index) {
    taskController.text = tasks[index]["name"];
    durationController.text = tasks[index]["duration"].toString();
    priority = tasks[index]["priority"];
    category = tasks[index]["category"];
    deadline = null;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Tugas"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: taskController, decoration: InputDecoration(labelText: "Nama Tugas")),
            TextField(controller: durationController, decoration: InputDecoration(labelText: "Durasi"), keyboardType: TextInputType.number),
            DropdownButton<String>(
              value: priority,
              hint: Text("Pilih Prioritas"),
              onChanged: (value) => setState(() => priority = value),
              items: ["Tinggi", "Sedang", "Rendah"].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal")),
          TextButton(
            onPressed: () {
              setState(() {
                tasks[index]["name"] = taskController.text;
                tasks[index]["duration"] = int.tryParse(durationController.text) ?? 30;
                tasks[index]["priority"] = priority!;
              });
              Navigator.pop(context);
            },
            child: Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _toggleTaskCompletion(int index) {
    setState(() {
      tasks[index]["completed"] = !tasks[index]["completed"];
    });
  }

  Future<void> _selectDeadline() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        deadline = pickedDate;
      });
    }
  }

  int _calculateTotalDuration() {
    return tasks.fold(0, (sum, task) => sum + (task["duration"] as int));
  }

  Future<void> _generateSchedule() async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠ Harap tambahkan tugas terlebih dahulu!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String schedule = await GeminiService.generateSchedule(tasks);
      await Future.delayed(Duration(seconds: 1));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScheduleResultScreen(scheduleResult: schedule),
        ),
      ).then((_) {
        setState(() => isLoading = false);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghasilkan jadwal: $e")),
      );
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Buku To-Do List"),
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
              onPressed: () => setState(() => isDarkMode = !isDarkMode),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Input Form
              TextField(controller: taskController, decoration: InputDecoration(labelText: "Nama Tugas")),
              TextField(controller: durationController, decoration: InputDecoration(labelText: "Durasi (menit)"), keyboardType: TextInputType.number),
              DropdownButton<String>(
                value: priority,
                hint: Text("Pilih Prioritas"),
                onChanged: (value) => setState(() => priority = value),
                items: ["Tinggi", "Sedang", "Rendah", "Waktu Kosong"].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              ),
              const SizedBox(height: 20,),
              DropdownButton<String>(
                value: category,
                hint: Text("Pilih Kategori"),
                onChanged: (value) => setState(() => category = value),
                items: ["Pekerjaan", "Pribadi", "Pendidikan"].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              ),
              const SizedBox(height: 20),
              Text("Total Durasi: ${_calculateTotalDuration()} menit"),
              const SizedBox(height: 20,),
              ElevatedButton(onPressed: _addTask, child: Text("Tambahkan")),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      title: Text("${task['name']}"),
                      subtitle: Text("Prioritas: ${task['priority']} | Durasi: ${task['duration']} menit"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: Icon(Icons.edit), onPressed: () => _editTask(index)),
                          IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _clearTasks()),
                        ],
                      ),
                    );
                  },
                ),
              ),
              isLoading ? CircularProgressIndicator() : ElevatedButton(onPressed: _generateSchedule, child: Text("Generate Schedule")),
            ],
          ),
        ),
      ),
    );
  }
}
