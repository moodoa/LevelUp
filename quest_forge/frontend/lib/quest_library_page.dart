import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'completion_history_page.dart'; // Assuming Quest model is in here

class QuestLibraryPage extends StatefulWidget {
  const QuestLibraryPage({super.key});

  @override
  // The state class is now public
  QuestLibraryPageState createState() => QuestLibraryPageState();
}

// The state class is now public
class QuestLibraryPageState extends State<QuestLibraryPage> {
  List<Quest> _quests = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedQuestType = 'daily'; // Default to daily

  @override
  void initState() {
    super.initState();
    _fetchAllQuests();
  }

  Future<void> _fetchAllQuests() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await http.get(Uri.parse('http://192.168.1.101:8000/quests/all'));
      if (response.statusCode == 200) {
        var questList = json.decode(utf8.decode(response.bodyBytes)) as List;
        setState(() {
          _quests = questList.map((i) => Quest.fromJson(i)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load quests: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching quests: $e';
        _isLoading = false;
      });
    }
  }

  // This method is now public
  void showAddQuestDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _expController = TextEditingController();
    String currentSelectedQuestType = _selectedQuestType; // Use a local variable for dialog

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新增任務'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '任務名稱'),
                  validator: (value) => value!.isEmpty ? '請輸入名稱' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: '任務描述'),
                ),
                TextFormField(
                  controller: _expController,
                  decoration: const InputDecoration(labelText: '經驗值'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? '請輸入經驗值' : null,
                ),
                DropdownButtonFormField<String>(
                  value: currentSelectedQuestType,
                  decoration: const InputDecoration(labelText: '任務類型'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('每日任務')),
                    DropdownMenuItem(value: 'random', child: Text('隨機任務')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      currentSelectedQuestType = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _addQuest(
                    _nameController.text,
                    _descriptionController.text,
                    int.parse(_expController.text),
                    currentSelectedQuestType,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('新增'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addQuest(String name, String description, int exp, String questType) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.101:8000/quests/'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'name': name,
          'description': description,
          'exp_value': exp,
          'quest_type': questType,
        }),
      );
      if (response.statusCode == 200) {
        _fetchAllQuests(); // Refresh the list
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildQuestList();
  }

  Widget _buildQuestList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error.isNotEmpty) {
      return Center(child: Text('Error: $_error'));
    } else if (_quests.isEmpty) {
      return const Center(child: Text('任務庫是空的。'));
    } else {
      return ListView.builder(
        itemCount: _quests.length,
        itemBuilder: (context, index) {
          final quest = _quests[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              title: Text(quest.name),
              subtitle: Text(quest.description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${quest.expValue} EXP'),
                  IconButton(
                    icon: const Icon(Icons.add_task),
                    onPressed: () => _assignQuestManually(quest.id),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _assignQuestManually(int questId) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.101:8000/quests/$questId/assign_manually'),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message']),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign quest: ${response.statusCode}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning quest: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}