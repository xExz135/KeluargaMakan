// Dapur Saya root (KIT-01, flows/03). Shell placeholder: no kitchen list yet.

import 'package:flutter/material.dart';

import '../../app/widgets/section_scaffold.dart';
import '../../l10n/generated/app_localizations.dart';

class DapurSayaScreen extends StatelessWidget {
  const DapurSayaScreen({super.key});

  @override
  Widget build(BuildContext context) => SectionScaffold(
    title: AppLocalizations.of(context).kitchenTitle,
    body: const SizedBox.expand(),
  );
}
