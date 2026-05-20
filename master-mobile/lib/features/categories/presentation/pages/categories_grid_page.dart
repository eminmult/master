import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/i18n/category_helpers.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/categories/data/categories_repository.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

final _categoriesProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(categoriesRepositoryProvider).list(onlyWithMasters: true);
});

class CategoriesGridPage extends ConsumerWidget {
  const CategoriesGridPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final asyncCats = ref.watch(_categoriesProvider);
    return Scaffold(
      backgroundColor: HmColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(children: [
                HmIconButton(icon: Icons.arrow_back_ios_new_rounded, small: true, flat: true,
                    onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
                Expanded(child: Center(child: Text(loc.cat_all_categories,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 32),
              ]),
            ),
            Expanded(
              child: asyncCats.when(
                data: (cats) => GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.95,
                  ),
                  itemCount: cats.length,
                  itemBuilder: (_, i) {
                    final c = cats[i];
                    final name = localizedCategoryName(loc, c);
                    return InkWell(
                      borderRadius: BorderRadius.circular(HmRadius.cardLarge),
                      onTap: () => context.push('/list/${c.slug}', extra: name),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: HmColors.surface,
                          borderRadius: BorderRadius.circular(HmRadius.cardLarge),
                          border: Border.all(color: HmColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: HmColors.accentSoft),
                              child: Icon(iconForCategorySlug(c.slug), color: HmColors.accent, size: 22),
                            ),
                            Text(name, textAlign: TextAlign.center, maxLines: 2,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            Text(loc.cat_n_masters(c.mastersCount),
                                style: const TextStyle(fontSize: 10, color: HmColors.text5)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: HmColors.accent)),
                error: (_, __) => Center(child: Text(loc.auth_failed_to_load,
                    style: const TextStyle(color: HmColors.danger))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
