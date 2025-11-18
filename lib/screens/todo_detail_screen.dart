import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../database/database_helper.dart';

class TodoDetailScreen extends StatefulWidget {
  final Todo todo;

  const TodoDetailScreen({super.key, required this.todo});

  @override
  _TodoDetailScreenState createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _contentController = TextEditingController(text: widget.todo.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    Todo updatedTodo = Todo(
      id: widget.todo.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdDate: widget.todo.createdDate,
    );

    await _dbHelper.updateTodo(updatedTodo);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Todo updated successfully!"),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Todo Details'),
        backgroundColor: Colors.blue.withOpacity(0.7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async => await _saveChanges(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShadowedField(
                controller: _titleController,
                label: "Title",
                maxLines: 1,
              ),
              const SizedBox(height: 20),

              _buildShadowedField(
                controller: _contentController,
                label: "Content",
                maxLines: 10,
              ),
              const SizedBox(height: 20),

              Center(
                child: Text(
                  "Created on: ${widget.todo.createdDate.toLocal().toString().split(' ')[0]}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Save button (full width, rounded)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.check),
                  label: const Text("Save Changes"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────── Custom Shadowed TextField Widget ─────────
  Widget _buildShadowedField({
    required TextEditingController controller,
    required String label,
    required int maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          labelStyle: TextStyle(color: Colors.grey.shade700),
        ),
      ),
    );
  }
}
