
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Data Models
class Quest {
  final int id;
  final String name;
  final String description;
  final int expValue;

  Quest({
    required this.id,
    required this.name,
    required this.description,
    required this.expValue,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      expValue: json['exp_value'],
    );
  }
}

class UserStatus {
  final int id;
  final int level;
  final int exp;
  final int expToNextLevel;
  final int totalExp;
  final int completedQuestsCount;
  final List<Quest> completedQuests;

  UserStatus({
    required this.id,
    required this.level,
    required this.exp,
    required this.expToNextLevel,
    required this.totalExp,
    required this.completedQuestsCount,
    required this.completedQuests,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    var questList = json['completed_quests'] as List;
    List<Quest> quests = questList.map((i) => Quest.fromJson(i)).toList();
    return UserStatus(
      id: json['id'],
      level: json['level'],
      exp: json['exp'],
      expToNextLevel: json['exp_to_next_level'],
      totalExp: json['total_exp'],
      completedQuestsCount: json['completed_quests_count'],
      completedQuests: quests,
    );
  }
}

class CompletionHistoryPage extends StatefulWidget {
  const CompletionHistoryPage({super.key});

  @override
  State<CompletionHistoryPage> createState() => _CompletionHistoryPageState();
}

class _CompletionHistoryPageState extends State<CompletionHistoryPage> {
  UserStatus? _userStatus;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchUserStatus();
  }

  Future<void> _fetchUserStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await http.get(Uri.parse('http://192.168.1.101:8000/user/status'));
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _userStatus = UserStatus.fromJson(json.decode(utf8.decode(response.bodyBytes)));
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = 'Failed to load user status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error fetching user status: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error.isNotEmpty) {
      return Center(child: Text('Error: $_error'));
    } else if (_userStatus == null) {
      return const Center(child: Text('無法載入使用者狀態！'));
    } else {
      double expPercentage = _userStatus!.exp / _userStatus!.expToNextLevel;

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('等級: ${_userStatus!.level}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: expPercentage,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${_userStatus!.exp} / ${_userStatus!.expToNextLevel} EXP'),
              ],
            ),
            const SizedBox(height: 24),
            Text('今日完成任務 (${_userStatus!.completedQuestsCount})', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _userStatus!.completedQuests.length,
                itemBuilder: (context, index) {
                  final quest = _userStatus!.completedQuests[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text(quest.name),
                      subtitle: Text(quest.description),
                      trailing: Text('+${quest.expValue} EXP'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  }
}
