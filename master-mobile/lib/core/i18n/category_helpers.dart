import 'package:flutter/material.dart';
import 'package:master_mobile/features/categories/data/categories_repository.dart';
import 'package:master_mobile/l10n/generated/app_localizations.dart';

/// API serves category names in Azerbaijani only. Map known slugs to ARB keys
/// so any UI surface (home tile row, grid, master detail) reflects the
/// active locale; fall back to the API name for slugs we don't translate yet.
String localizedCategoryName(AppLocalizations loc, ServiceCategory c) {
  switch (c.slug) {
    case 'santexnik':    return loc.cat_santexnik;
    case 'elektrik':     return loc.cat_elektrik;
    case 'qaynaqci':     return loc.cat_qaynaqci;
    case 'usta-saati':   return loc.cat_usta_saati;
    case 'mebel-yigimi': return loc.cat_mebel_yigimi;
    case 'rengleme':     return loc.cat_rengleme;
    case 'kondisioner':  return loc.cat_kondisioner;
    case 'cilinger':     return loc.cat_cilinger;
    default:             return c.name;
  }
}

/// Backend stores `ph:*` Phosphor identifiers; we don't render those here.
/// Hand-pick a Material equivalent for the slugs that surface in the home
/// row and grid headers, fall back to a generic build icon for the rest.
IconData iconForCategorySlug(String? slug) {
  switch (slug) {
    case 'santexnik':    return Icons.water_drop_rounded;
    case 'elektrik':     return Icons.bolt_rounded;
    case 'qaynaqci':     return Icons.local_fire_department_rounded;
    case 'usta-saati':   return Icons.handyman_rounded;
    case 'mebel-yigimi': return Icons.chair_rounded;
    case 'rengleme':     return Icons.format_paint_rounded;
    case 'kondisioner':  return Icons.ac_unit_rounded;
    case 'cilinger':     return Icons.lock_rounded;
    case 'temizlik':     return Icons.cleaning_services_rounded;
    case 'baxici':       return Icons.eco_rounded;
    default:             return Icons.build_rounded;
  }
}
