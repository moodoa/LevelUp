import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'completion_history_page.dart'; // Assuming Quest model is in here

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> _history = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await http.get(Uri.parse('http://192.168.1.101:8000/user/history'));
      if (response.statusCode == 200) {
        setState(() {
          _history = json.decode(utf8.decode(response.bodyBytes));
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load history: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching history: $e';
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
    } else if (_history.isEmpty) {
      return const Center(child: Text('沒有任何歷史紀錄。'));
    } else {
      return ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final record = _history[index];
          final quest = record['quest'];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              title: Text(quest['name']),
              subtitle: Text("完成於: ${record['completion_date']}"),
              trailing: Text('+${quest['exp_value']}'),
            ),
          );
        },
      );
    }
  }
}
