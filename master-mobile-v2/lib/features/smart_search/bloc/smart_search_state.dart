part of 'smart_search_bloc.dart';

sealed class SmartSearchState {
  const SmartSearchState();
}

class SmartSearchIdle extends SmartSearchState {
  const SmartSearchIdle();
}

class SmartSearchAnalyzing extends SmartSearchState {
  const SmartSearchAnalyzing(this.description);
  final String description;
}

class SmartSearchSuggested extends SmartSearchState {
  const SmartSearchSuggested({
    required this.description,
    required this.suggestedCategory,
    required this.confidence,
    required this.masters,
    this.title,
  });

  final String description;
  final CategoryModel? suggestedCategory;
  final double confidence;
  final List<MasterListItem> masters;

  /// Заголовок, который придумал Gemini ("сломан кран" → "Замена смесителя").
  /// Используется как initialSearch при переходе в MastersList.
  final String? title;
}

class SmartSearchFailed extends SmartSearchState {
  const SmartSearchFailed(this.message);
  final String message;
}
