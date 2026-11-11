// Resep root: library browse and search (LIB-08, navigation.md 5). Shell placeholder:
// no recipes are listed until they come from the API with their Cek Aman
// result.

import 'package:flutter/material.dart';

import '../../app/widgets/section_scaffold.dart';
import '../../l10n/generated/app_localizations.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) => SectionScaffold(
    title: AppLocalizations.of(context).navRecipes,
    body: const SizedBox.expand(),
  );
}
