// Rencana Mingguan root. V2 attach point (navigation.md 1): reachable only
// when nav.planTabEnabled is on, which it is not in V1.

import 'package:flutter/material.dart';

import '../../app/widgets/section_scaffold.dart';
import '../../l10n/generated/app_localizations.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) => SectionScaffold(
    title: AppLocalizations.of(context).navPlan,
    body: const SizedBox.expand(),
  );
}
