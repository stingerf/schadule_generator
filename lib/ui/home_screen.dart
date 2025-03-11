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
  bool isLoading = false;

  void _addTask() {
    if (taskController.text.isNotEmpty &&
        durationController.text.isNotEmpty &&
        priority != null) {
      setState(() {
        tasks.add({
          "name": taskController.text,
          "priority": priority!,
          "duration": int.tryParse(durationController.text) ?? 30,
          "deadline": deadline != null
              ? "${deadline!.day}/${deadline!.month}/${deadline!.year}"
              : "Tidak Ada",
          "completed": false, // Menambahkan status selesai
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
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

  void _toggleTaskCompletion(int index) {
    setState(() {
      tasks[index]["completed"] = !tasks[index]["completed"];
    });
  }

  void _deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
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
    return Scaffold(
      backgroundColor: Colors.brown[100],
      appBar: AppBar(
        title: Text(
          "Buku To-Do List",
          style: TextStyle(fontFamily: 'IndieFlower', fontSize: 24),
        ),
        backgroundColor: Colors.brown[300],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input Form
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: taskController,
                    decoration: InputDecoration(
                      labelText: "Nama Tugas",
                      border: InputBorder.none,
                    ),
                  ),
                  Divider(),
                  TextField(
                    controller: durationController,
                    decoration: InputDecoration(
                      labelText: "Durasi (menit)",
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  Divider(),
                  DropdownButton<String>(
                    value: priority,
                    hint: Text("Pilih Prioritas"),
                    onChanged: (value) => setState(() => priority = value),
                    items: ["Tinggi", "Sedang", "Rendah"]
                        .map((priorityMember) => DropdownMenuItem(
                            value: priorityMember, child: Text(priorityMember)))
                        .toList(),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(deadline == null
                          ? "Deadline: Tidak Ada"
                          : "Deadline: ${deadline!.day}/${deadline!.month}/${deadline!.year}"),
                      TextButton(
                        onPressed: _selectDeadline,
                        child: Text("Pilih Deadline"),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _addTask,
                        child: Text("Tambahkan"),
                      ),
                      ElevatedButton(
                        onPressed: _clearTasks,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child:
                            Text("Hapus Semua", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Task List
            Expanded(
              child: tasks.isEmpty
                  ? Center(child: Text("Belum ada tugas, tambahkan yuk!"))
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Card(
                          color: task["completed"]
                              ? Colors.green[100]
                              : Colors.white,
                          margin: EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: IconButton(
                              icon: Icon(
                                task["completed"]
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: task["completed"]
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              onPressed: () => _toggleTaskCompletion(index),
                            ),
                            title: Text("${task['name']}"),
                            subtitle: Text(
                                "Prioritas: ${task['priority']} | Durasi: ${task['duration']} menit\nDeadline: ${task['deadline']}"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTask(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 10),
            // Generate Schedule Button
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _generateSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[400],
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      "Sarankan jadwal dari Gemini ✨",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
