part of 'smart_search_bloc.dart';

sealed class SmartSearchEvent {
  const SmartSearchEvent();
}

class SmartSearchSubmitted extends SmartSearchEvent {
  const SmartSearchSubmitted({
    required this.description,
    this.photos = const [],
    this.imageMime,
  });
  final String description;

  /// Base64-encoded bytes (без `data:` префикса).
  final List<String> photos;
  final String? imageMime;
}

class SmartSearchReset extends SmartSearchEvent {
  const SmartSearchReset();
}
