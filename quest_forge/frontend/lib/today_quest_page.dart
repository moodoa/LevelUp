
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TodayQuestPage extends StatefulWidget {
  const TodayQuestPage({super.key});

  @override
  State<TodayQuestPage> createState() => _TodayQuestPageState();
}

class _TodayQuestPageState extends State<TodayQuestPage> {
  List<dynamic> _todayQuests = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchTodayQuests();
  }

  Future<void> _fetchTodayQuests() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await http.get(Uri.parse('http://192.168.1.101:8000/quests/'));
      print('Response status: ${response.statusCode}');
      print('Response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        setState(() {
          _todayQuests = json.decode(utf8.decode(response.bodyBytes));
          print('Parsed quests: $_todayQuests');
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

  Future<void> _completeQuest(int questId) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.101:8000/quests/$questId/complete'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _todayQuests.removeWhere((quest) => quest['id'] == questId);
        });

        dynamic responseData;
        try {
          responseData = json.decode(utf8.decode(response.bodyBytes));
        } catch (e) {
          responseData = null;
        }

        final message = responseData?['message'] ?? '任務已完成！';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete quest: ${response.statusCode}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error.isNotEmpty) {
      return Center(child: Text('Error: $_error'));
    } else if (_todayQuests.isEmpty) {
      return const Center(child: Text('今天沒有任務！'));
    } else {
      return ListView.builder(
        itemCount: _todayQuests.length,
        itemBuilder: (context, index) {
          final quest = _todayQuests[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(quest['description']),
                        const SizedBox(height: 8),
                        Text('經驗值: ${quest['exp_value']}'),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _completeQuest(quest['id']);
                    },
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
