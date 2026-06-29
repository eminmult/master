import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/core/utils/json_parse.dart';
import 'package:itez_mobile/features/categories/models/category_model.dart';
import 'package:itez_mobile/features/categories/repositories/category_repository.dart';
import 'package:itez_mobile/features/masters/models/master_list_item.dart';
import 'package:itez_mobile/features/masters/repositories/master_repository.dart';

part 'smart_search_event.dart';
part 'smart_search_state.dart';

/// SmartSearch — Gemini-классификатор `/api/v1/smart-search`.
///
/// Primary: POST на backend с описанием + base64 фото; backend возвращает
/// `{category_id, category_name, title, description, confidence}`.
/// Fallback: если endpoint вернул 404 или другая ошибка — heuristic-пересечение
/// токенов описания со словами в имени категории.
///
/// Дальше с результатом разрешаем категорию через CategoryRepository
/// и загружаем мастеров отфильтрованных по id.
class SmartSearchBloc extends Bloc<SmartSearchEvent, SmartSearchState> {
  SmartSearchBloc({
    required ApiClient client,
    required CategoryRepository categories,
    required MasterRepository masters,
  })  : _client = client,
        _categories = categories,
        _masters = masters,
        super(const SmartSearchIdle()) {
    on<SmartSearchSubmitted>(_onSubmit);
    on<SmartSearchReset>((_, emit) => emit(const SmartSearchIdle()));
  }

  final ApiClient _client;
  final CategoryRepository _categories;
  final MasterRepository _masters;

  Future<void> _onSubmit(
    SmartSearchSubmitted event,
    Emitter<SmartSearchState> emit,
  ) async {
    final desc = event.description.trim();
    if (desc.isEmpty && event.photos.isEmpty) {
      emit(const SmartSearchFailed('Опишите задачу или приложите фото'));
      return;
    }
    emit(SmartSearchAnalyzing(desc));

    try {
      final cats = await _categories.list(onlyWithMasters: true);
      CategoryModel? matched;
      double confidence = 0;
      String? title;

      // ─── Primary: REST `/smart-search` ───
      try {
        final body = <String, dynamic>{
          'description': desc,
          if (event.photos.isNotEmpty) ...{
            'image': event.photos.first,
            'image_mime': event.imageMime ?? 'image/jpeg',
          },
        };
        final json = await _client.postJson(Urls.smartSearch, body: body);
        final catId = parseIntOrNull(json['category_id']);
        confidence = parseDouble(json['confidence']);
        title = json['title']?.toString();
        if (catId != null) {
          for (final c in cats) {
            if (c.id == catId) {
              matched = c;
              break;
            }
          }
        }
      } on AppException {
        // 404 / 500 / network — на heuristic.
      } catch (_) {/* парсинг или прочее */}

      // ─── Fallback: token-пересечение ───
      if (matched == null) {
        final h = _heuristic(desc, cats);
        if (h != null) {
          matched = h.category;
          confidence = h.confidence;
        }
      }

      final list = await _masters.list(
        MasterListFilter(
          categoryId: matched?.id,
          sort: 'rating',
        ),
      );

      emit(SmartSearchSuggested(
        description: desc,
        suggestedCategory: matched,
        confidence: confidence,
        title: title,
        masters: list,
      ));
    } on AppException catch (e) {
      emit(SmartSearchFailed(e.message ?? 'Не удалось обработать запрос'));
    } catch (e) {
      emit(SmartSearchFailed('Не удалось обработать запрос: $e'));
    }
  }

  _Match? _heuristic(String desc, List<CategoryModel> cats) {
    if (cats.isEmpty) return null;
    final tokens = desc
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((t) => t.length > 2)
        .toSet();
    if (tokens.isEmpty) return null;

    _Match? best;
    for (final c in cats) {
      final nameTokens = '${c.name} ${c.nameAz} ${c.slug}'
          .toLowerCase()
          .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
          .where((t) => t.length > 2)
          .toSet();
      if (nameTokens.isEmpty) continue;
      final hit = nameTokens.intersection(tokens).length;
      if (hit == 0) continue;
      final conf = hit / nameTokens.length;
      if (best == null || conf > best.confidence) {
        best = _Match(c, conf);
      }
    }
    return best;
  }
}

class _Match {
  const _Match(this.category, this.confidence);
  final CategoryModel category;
  final double confidence;
}
