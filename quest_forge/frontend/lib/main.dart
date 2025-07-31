import 'package:flutter/material.dart';
import 'package:frontend/today_quest_page.dart';
import 'package:frontend/completion_history_page.dart';
import 'package:frontend/quest_library_page.dart';
import 'package:frontend/history_page.dart'; // Import the new page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LevelUp',
      debugShowCheckedModeBanner: false, // Remove the debug banner
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark, // 深色主題
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // Create a GlobalKey for the QuestLibraryPage
  final GlobalKey<QuestLibraryPageState> _questLibraryKey = GlobalKey();

  // Initialize the list directly
  late final List<Widget> _widgetOptions = <Widget>[
    const TodayQuestPage(), // Tab 1: 今日任務
    const CompletionHistoryPage(), // Tab 2: 完成度
    QuestLibraryPage(key: _questLibraryKey), // Tab 3: 任務庫
    const HistoryPage(), // Tab 4: 歷史紀錄
  ];

  void _onItemTapped(int index) {
    print('Tapped on item with index: $index'); // Debugging line
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LevelUp'),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
              onPressed: () => _questLibraryKey.currentState?.showAddQuestDialog(),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: Material(
        elevation: 8.0,
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.today),
              label: '今日任務',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              label: '完成度',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              label: '任務庫',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: '歷史紀錄',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // Ensure consistent behavior
          backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        ),
      ),
    );
  }
}