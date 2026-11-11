// Keluarga Saya root (PRF-01, flows/02). Shell placeholder: profiles come with
// T-028.

import 'package:flutter/material.dart';

import '../../app/widgets/section_scaffold.dart';
import '../../l10n/generated/app_localizations.dart';

class KeluargaSayaScreen extends StatelessWidget {
  const KeluargaSayaScreen({super.key});

  @override
  Widget build(BuildContext context) => SectionScaffold(
    title: AppLocalizations.of(context).familyTitle,
    body: const SizedBox.expand(),
  );
}
