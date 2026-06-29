part of 'categories_bloc.dart';

sealed class CategoriesEvent {
  const CategoriesEvent();
}

class CategoriesRequested extends CategoriesEvent {
  const CategoriesRequested({
    this.includeSubcategories = false,
    this.onlyWithMasters = true,
  });
  final bool includeSubcategories;
  final bool onlyWithMasters;
}

class CategoriesRefreshed extends CategoriesEvent {
  const CategoriesRefreshed();
}
