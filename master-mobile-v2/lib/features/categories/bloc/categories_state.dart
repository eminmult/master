part of 'categories_bloc.dart';

sealed class CategoriesState {
  const CategoriesState();
}

class CategoriesInitial extends CategoriesState {
  const CategoriesInitial();
}

class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

class CategoriesLoaded extends CategoriesState {
  const CategoriesLoaded(this.items);
  final List<CategoryModel> items;
}

class CategoriesFailed extends CategoriesState {
  const CategoriesFailed(this.message);
  final String message;
}
