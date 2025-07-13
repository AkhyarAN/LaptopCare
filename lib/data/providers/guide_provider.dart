import 'package:flutter/foundation.dart';
import '../models/guide.dart';
import '../models/maintenance_task.dart';
import '../services/appwrite_service.dart';

class GuideProvider with ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();

  List<Guide> _guides = [];
  bool _isLoading = false;
  String? _error;
  TaskCategory? _selectedCategory;
  GuideDifficulty? _selectedDifficulty;
  bool _showPremiumOnly = false;

  List<Guide> get guides => _guides;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TaskCategory? get selectedCategory => _selectedCategory;
  GuideDifficulty? get selectedDifficulty => _selectedDifficulty;
  bool get showPremiumOnly => _showPremiumOnly;

  List<Guide> get filteredGuides {
    List<Guide> filtered = _guides;

    if (_selectedCategory != null) {
      filtered = filtered
          .where((guide) => guide.category == _selectedCategory)
          .toList();
    }

    if (_selectedDifficulty != null) {
      filtered = filtered
          .where((guide) => guide.difficulty == _selectedDifficulty)
          .toList();
    }

    if (_showPremiumOnly) {
      filtered = filtered.where((guide) => guide.isPremium).toList();
    }

    return filtered;
  }

  List<Guide> getGuidesByCategory(TaskCategory category) {
    return _guides.where((guide) => guide.category == category).toList();
  }

  Future<void> fetchGuides() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('GuideProvider: Fetching guides...');
      _guides = await _appwriteService.getGuides();
      debugPrint('GuideProvider: Fetched ${_guides.length} guides');

      // Sort guides by category and difficulty
      _guides.sort((a, b) {
        int categoryCompare = a.category.name.compareTo(b.category.name);
        if (categoryCompare != 0) return categoryCompare;
        return a.difficulty.name.compareTo(b.difficulty.name);
      });
    } catch (e) {
      debugPrint('GuideProvider: Error fetching guides - $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Guide?> getGuideById(String guideId) async {
    try {
      return await _appwriteService.getGuide(guideId);
    } catch (e) {
      debugPrint('GuideProvider: Error fetching guide $guideId - $e');
      return null;
    }
  }

  void setFilter({
    TaskCategory? category,
    GuideDifficulty? difficulty,
    bool? showPremiumOnly,
  }) {
    _selectedCategory = category;
    _selectedDifficulty = difficulty;
    _showPremiumOnly = showPremiumOnly ?? _showPremiumOnly;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedDifficulty = null;
    _showPremiumOnly = false;
    notifyListeners();
  }

  void clearData() {
    _guides.clear();
    _isLoading = false;
    _error = null;
    _selectedCategory = null;
    _selectedDifficulty = null;
    _showPremiumOnly = false;
    notifyListeners();
  }
}
