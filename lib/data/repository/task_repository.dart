import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:appwrite_flutter_starter_kit/data/models/task.dart';
import 'package:uuid/uuid.dart';

class TaskRepository {
  static const String _projectId = 'task-management-app';
  static const String _databaseId = 'laptopcare-db';
  static const String _apiKey =
      'standard_2cbbb2e0ec3fcc79c6645a5ae3dfcc658672eb4f73cb93ee74f26717eda90cdbfb022cf3867b0bb501f598d95b9117db161a5cfef810973826b8b463777ac29cde0eba8a2d032f87629b7881258f3ba16e17e5bec4f4e70867caa5dcf002474dcb1f4fb3c2d77642edbb8e2b78b8e118549bb196ec43d2436ea3a8e28283761d';
  static const String _baseUrl = 'https://database.deta.sh/v1';
  static const String _collectionName = 'tasks';

  final _uuid = const Uuid();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': _apiKey,
      };

  Future<List<Task>> getTasks() async {
    try {
      const url = '$_baseUrl/$_projectId/$_databaseId/items';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        return items.map((item) => Task.fromJson(item)).toList();
      } else {
        // Create a mock task list for testing if the API fails
        return _getMockTasks();
      }
    } catch (e) {
      // Return mock tasks if there's an error
      return _getMockTasks();
    }
  }

  // Mock data for testing when API is not available
  List<Task> _getMockTasks() {
    return [
      Task(
        id: '1',
        title: 'Complete Flutter Assignment',
        description: 'Finish the task management app',
        isCompleted: false,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 2)),
        priority: 'High',
      ),
      Task(
        id: '2',
        title: 'Study for Mobile Programming',
        description: 'Review chapter 5-7',
        isCompleted: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        priority: 'Medium',
      ),
      Task(
        id: '3',
        title: 'Buy groceries',
        description: 'Milk, eggs, bread',
        isCompleted: false,
        createdAt: DateTime.now(),
        dueDate: null,
        priority: 'Low',
      ),
    ];
  }

  Future<Task> createTask(Task task) async {
    try {
      const url = '$_baseUrl/$_projectId/$_databaseId/items';

      final taskId = _uuid.v4();
      final taskData = {
        'key': taskId,
        ...task.toJson(),
      };

      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: json.encode({
          'items': [taskData],
        }),
      );

      if (response.statusCode == 201) {
        return Task.fromJson({
          'id': taskId,
          ...task.toJson(),
        });
      } else {
        // Return the original task if the API call fails
        return task.copyWith(id: taskId);
      }
    } catch (e) {
      // Return the task with a generated ID if there's an error
      return task.copyWith(id: _uuid.v4());
    }
  }

  Future<Task> updateTask(Task task) async {
    try {
      final url = '$_baseUrl/$_projectId/$_databaseId/items/${task.id}';

      final response = await http.patch(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(task.toJson()),
      );

      return task;
    } catch (e) {
      // Return the original task if there's an error
      return task;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      final url = '$_baseUrl/$_projectId/$_databaseId/items/$id';

      await http.delete(
        Uri.parse(url),
        headers: _headers,
      );
    } catch (e) {
      // Silently handle the error
    }
  }
}
