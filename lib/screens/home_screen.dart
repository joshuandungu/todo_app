import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../database/database_helper.dart';
import 'add_todo_screen.dart';
import 'todo_detail_screen.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  String _searchQuery = '';
  int _currentIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    List<Todo> todos = await _dbHelper.getTodos();
    setState(() {
      _todos = todos;
      _filteredTodos = todos;
    });
  }

  void _searchTodos(String query) {
    setState(() {
      _searchQuery = query;
      _filteredTodos = _todos
          .where(
              (todo) => todo.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _sortByDate() {
    setState(() {
      _sortAscending = !_sortAscending;
      _filteredTodos.sort((a, b) => _sortAscending
          ? a.createdDate.compareTo(b.createdDate)
          : b.createdDate.compareTo(a.createdDate));
    });
  }

  Future<void> _deleteTodo(int id) async {
    await _dbHelper.deleteTodo(id);
    _loadTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ APP BAR ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
      appBar: AppBar(
        title: const Text('Todo List'),
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearchDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _sortByDate,
          ),
        ],
      ),

      // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ DRAWER ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
      drawer: _buildStylishDrawer(),

      // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ BOTTOM NAV BAR ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
      bottomNavigationBar: _buildStyledBottomNav(),

      // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ BOTTOM FOOTER ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
      bottomSheet: BottomAppBar(
        elevation: 10,
        color: Colors.white,
        child: SizedBox(
          height: 45,
          child: Center(
            child: Text(
              '© 2024 Todo App',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTodoScreen()),
          );
          _loadTodos();
        },
        child: const Icon(Icons.add),
      ),

      // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ BACKGROUND + LIST ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/notebook.webp'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: _filteredTodos.isEmpty
            ? const Center(
                child: Text(
                  'No todos yet. Add one!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 100),
                itemCount: _filteredTodos.length,
                itemBuilder: (context, index) {
                  Todo todo = _filteredTodos[index];
                  return Card(
                    elevation: 5,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(todo.title),
                      subtitle: Text(
                        'Created: ${todo.createdDate.toLocal().toString().split(' ')[0]}',
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TodoDetailScreen(todo: todo),
                          ),
                        );
                        _loadTodos();
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTodo(todo.id!),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ▬▬▬▬▬▬▬▬▬ SEARCH DIALOG ▬▬▬▬▬▬▬▬▬
  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Search Todos"),
        content: TextField(
          decoration: const InputDecoration(
            labelText: "Search by title",
            border: OutlineInputBorder(),
          ),
          onChanged: _searchTodos,
        ),
      ),
    );
  }

  // ▬▬▬▬▬▬▬▬▬ STYLED DRAWER ▬▬▬▬▬▬▬▬▬
  Drawer _buildStylishDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.check, size: 40, color: Colors.blue),
                ),
                SizedBox(height: 15),
                Text(
                  "Todo App",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "Manage your daily tasks",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          // HOME
          ListTile(
            leading: const Icon(Icons.home, color: Colors.blue),
            title: const Text("Home"),
            onTap: () => Navigator.pop(context),
          ),

          // SETTINGS (Main tile)
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.blue),
            title: const Text("Settings"),
            onTap: () {},
          ),

          // DARK MODE SWITCH
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return SwitchListTile(
                secondary: const Icon(Icons.dark_mode, color: Colors.blue),
                title: Text(
                  themeProvider.isDark ? "Dark Mode" : "Light Mode",
                  style: const TextStyle(fontSize: 16),
                ),
                value: themeProvider.isDark,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),

          // ABOUT
          ListTile(
            leading: const Icon(Icons.info, color: Colors.blue),
            title: const Text("About"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Todo App',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.check_box),
                children: [
                  const Text('A simple todo app built with Flutter.'),
                ],
              );
            },
          ),

          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("Version 1.0.0"),
          )
        ],
      ),
    );
  }

  // ▬▬▬▬▬▬▬▬▬ CUSTOM BOTTOM NAVIGATION ▬▬▬▬▬▬▬▬▬
  Widget _buildStyledBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      backgroundColor: Colors.white,
      elevation: 12,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() => _currentIndex = index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: "Todos",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: "Settings",
        ),
      ],
    );
  }
}
