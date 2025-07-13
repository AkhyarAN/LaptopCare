import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AppwriteAutoSetup {
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = 'project-fra-task-management-app';
  static const String databaseId = 'laptopcare-db';

  // This API key needs to have Database permissions
  static const String apiKey =
      'standard_c52dd8249abbdf7bcea18eb04ab265e87472b32826e09998817fdd1c8e775229cb4a941279026b7d6dbfc4172c0516d0bad59c66bf129640026ed9d9bfce251312ee453bdc8fdc02de5620e3fb8db65efc87d83220605b9ed76f70a53c8a1ff84b62ac3be8b4eea808d6057467c250f42ab160ee6a46c02a650db0ee0a3bebeb';

  static Future<Map<String, dynamic>>
      setupGuidesCollectionAutomatically() async {
    try {
      debugPrint('AppwriteAutoSetup: Starting automatic setup...');

      // Step 1: Check if collection exists
      bool collectionExists = await _checkCollectionExists();

      if (!collectionExists) {
        // Step 2: Create collection
        await _createGuidesCollection();
        debugPrint('AppwriteAutoSetup: Collection created successfully');

        // Step 3: Create attributes
        await _createCollectionAttributes();
        debugPrint('AppwriteAutoSetup: Attributes created successfully');

        // Step 4: Set permissions
        await _setCollectionPermissions();
        debugPrint('AppwriteAutoSetup: Permissions set successfully');

        // Wait a bit for collection to be ready
        await Future.delayed(const Duration(seconds: 2));
      } else {
        debugPrint('AppwriteAutoSetup: Collection already exists');

        // Check and fix permissions if needed
        await _setCollectionPermissions();
        debugPrint('AppwriteAutoSetup: Permissions updated');
      }

      return {
        'success': true,
        'message': 'Guides collection setup completed successfully!',
        'collectionExists': collectionExists,
      };
    } catch (e) {
      debugPrint('AppwriteAutoSetup: Error during setup: $e');
      return {
        'success': false,
        'message': 'Setup failed: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  static Future<bool> _checkCollectionExists() async {
    try {
      final response = await http.get(
        Uri.parse('$endpoint/databases/$databaseId/collections/guides'),
        headers: {
          'X-Appwrite-Project': projectId,
          'X-Appwrite-Key': apiKey,
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _createGuidesCollection() async {
    final response = await http.post(
      Uri.parse('$endpoint/databases/$databaseId/collections'),
      headers: {
        'X-Appwrite-Project': projectId,
        'X-Appwrite-Key': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        '\$id': 'guides',
        'name': 'Guides',
        'permissions': [
          'read("any")',
          'create("any")',
          'update("any")',
          'delete("any")',
        ],
        'documentSecurity': false,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create collection: ${response.body}');
    }
  }

  static Future<void> _createCollectionAttributes() async {
    final attributes = [
      {
        'key': 'guide_id',
        'type': 'string',
        'size': 255,
        'required': true,
      },
      {
        'key': 'category',
        'type': 'string',
        'size': 100,
        'required': true,
      },
      {
        'key': 'title',
        'type': 'string',
        'size': 255,
        'required': true,
      },
      {
        'key': 'content',
        'type': 'string',
        'size': 10000,
        'required': true,
      },
      {
        'key': 'difficulty',
        'type': 'string',
        'size': 50,
        'required': true,
      },
      {
        'key': 'estimated_time',
        'type': 'integer',
        'required': true,
      },
      {
        'key': 'is_premium',
        'type': 'boolean',
        'required': true,
        'default': false,
      },
      {
        'key': 'created_at',
        'type': 'datetime',
        'required': true,
      },
      {
        'key': 'updated_at',
        'type': 'datetime',
        'required': true,
      },
    ];

    for (final attr in attributes) {
      await _createAttribute(attr);
      // Wait between requests to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  static Future<void> _createAttribute(Map<String, dynamic> attr) async {
    String endpoint_url;
    Map<String, dynamic> body;

    switch (attr['type']) {
      case 'string':
        endpoint_url =
            '$endpoint/databases/$databaseId/collections/guides/attributes/string';
        body = {
          'key': attr['key'],
          'size': attr['size'],
          'required': attr['required'],
        };
        break;
      case 'integer':
        endpoint_url =
            '$endpoint/databases/$databaseId/collections/guides/attributes/integer';
        body = {
          'key': attr['key'],
          'required': attr['required'],
        };
        break;
      case 'boolean':
        endpoint_url =
            '$endpoint/databases/$databaseId/collections/guides/attributes/boolean';
        body = {
          'key': attr['key'],
          'required': attr['required'],
          'default': attr['default'],
        };
        break;
      case 'datetime':
        endpoint_url =
            '$endpoint/databases/$databaseId/collections/guides/attributes/datetime';
        body = {
          'key': attr['key'],
          'required': attr['required'],
        };
        break;
      default:
        throw Exception('Unsupported attribute type: ${attr['type']}');
    }

    final response = await http.post(
      Uri.parse(endpoint_url),
      headers: {
        'X-Appwrite-Project': projectId,
        'X-Appwrite-Key': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201 && response.statusCode != 409) {
      debugPrint('Failed to create attribute ${attr['key']}: ${response.body}');
      // Don't throw for attribute creation errors, just log them
    } else {
      debugPrint('Created attribute: ${attr['key']}');
    }
  }

  static Future<void> _setCollectionPermissions() async {
    final response = await http.put(
      Uri.parse('$endpoint/databases/$databaseId/collections/guides'),
      headers: {
        'X-Appwrite-Project': projectId,
        'X-Appwrite-Key': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': 'Guides',
        'permissions': [
          'read("any")',
          'create("any")',
          'update("any")',
          'delete("any")',
        ],
        'documentSecurity': false,
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('Failed to update permissions: ${response.body}');
      // Don't throw, just log
    }
  }

  static Future<Map<String, dynamic>>
      addMissingAttributesToExistingCollection() async {
    try {
      debugPrint(
          'AppwriteAutoSetup: Adding missing attributes to existing collection...');

      // Check which attributes are missing
      List<String> missingAttributes = await _checkMissingAttributes();

      if (missingAttributes.isEmpty) {
        return {
          'success': true,
          'message': 'All attributes already exist!',
          'addedAttributes': [],
        };
      }

      debugPrint('AppwriteAutoSetup: Missing attributes: $missingAttributes');

      // Add missing attributes
      List<String> addedAttributes = [];
      for (String attributeKey in missingAttributes) {
        bool success = await _addMissingAttribute(attributeKey);
        if (success) {
          addedAttributes.add(attributeKey);
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Update permissions to make sure they're correct
      await _setCollectionPermissions();

      return {
        'success': true,
        'message':
            'Successfully added ${addedAttributes.length} missing attributes!',
        'addedAttributes': addedAttributes,
      };
    } catch (e) {
      debugPrint('AppwriteAutoSetup: Error adding missing attributes: $e');
      return {
        'success': false,
        'message': 'Failed to add attributes: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  static Future<List<String>> _checkMissingAttributes() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$endpoint/databases/$databaseId/collections/guides/attributes'),
        headers: {
          'X-Appwrite-Project': projectId,
          'X-Appwrite-Key': apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> existingAttributes = [];

        for (var attr in data['attributes']) {
          existingAttributes.add(attr['key']);
        }

        debugPrint(
            'AppwriteAutoSetup: Existing attributes: $existingAttributes');

        // Required attributes
        List<String> requiredAttributes = [
          'guide_id',
          'category',
          'title',
          'content',
          'difficulty',
          'estimated_time',
          'is_premium', // This is the missing one!
          'created_at',
          'updated_at',
        ];

        List<String> missingAttributes = [];
        for (String required in requiredAttributes) {
          if (!existingAttributes.contains(required)) {
            missingAttributes.add(required);
          }
        }

        return missingAttributes;
      }

      return [];
    } catch (e) {
      debugPrint('AppwriteAutoSetup: Error checking attributes: $e');
      return [];
    }
  }

  static Future<bool> _addMissingAttribute(String attributeKey) async {
    try {
      Map<String, dynamic> attributeConfig;
      String endpoint_url;

      switch (attributeKey) {
        case 'guide_id':
        case 'category':
        case 'title':
        case 'content':
        case 'difficulty':
          endpoint_url =
              '$endpoint/databases/$databaseId/collections/guides/attributes/string';
          attributeConfig = {
            'key': attributeKey,
            'size': attributeKey == 'content'
                ? 10000
                : (attributeKey == 'title' ? 255 : 100),
            'required': true,
          };
          break;
        case 'estimated_time':
          endpoint_url =
              '$endpoint/databases/$databaseId/collections/guides/attributes/integer';
          attributeConfig = {
            'key': attributeKey,
            'required': true,
          };
          break;
        case 'is_premium':
          endpoint_url =
              '$endpoint/databases/$databaseId/collections/guides/attributes/boolean';
          attributeConfig = {
            'key': attributeKey,
            'required': false, // Make it not required so we can use default
            'default': false, // Default to false (free guides)
          };
          break;
        case 'created_at':
        case 'updated_at':
          endpoint_url =
              '$endpoint/databases/$databaseId/collections/guides/attributes/datetime';
          attributeConfig = {
            'key': attributeKey,
            'required': true,
          };
          break;
        default:
          debugPrint(
              'AppwriteAutoSetup: Unknown attribute type for $attributeKey');
          return false;
      }

      final response = await http.post(
        Uri.parse(endpoint_url),
        headers: {
          'X-Appwrite-Project': projectId,
          'X-Appwrite-Key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(attributeConfig),
      );

      if (response.statusCode == 201) {
        debugPrint(
            'AppwriteAutoSetup: Successfully added attribute: $attributeKey');
        return true;
      } else {
        debugPrint(
            'AppwriteAutoSetup: Failed to add attribute $attributeKey: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('AppwriteAutoSetup: Error adding attribute $attributeKey: $e');
      return false;
    }
  }
}
