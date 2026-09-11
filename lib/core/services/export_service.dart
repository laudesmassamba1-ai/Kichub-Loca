import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:kichub_loca/core/models/visit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<void> exportVisitsAsCsv(List<Visit> visits) async {
    final rows = <List<dynamic>>[
      ['commerce', 'statut', 'date_visite', 'date_rappel', 'notes'],
    ];

    for (final visit in visits) {
      rows.add([
        visit.commerceName ?? 'Commerce',
        visit.statut,
        visit.dateVisite.toIso8601String(),
        visit.dateRappel?.toIso8601String() ?? '',
        visit.notes ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      final bytes = utf8.encode(csv);
      await SharePlus.instance.share(
        ShareParams(
          text: 'Export Kichub Loca',
          files: [
            XFile.fromData(
              bytes,
              name: 'kichub_visites_export.csv',
              mimeType: 'text/csv',
            ),
          ],
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/kichub_visites_export.csv');
    await file.writeAsString(csv);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Export Kichub Loca',
        files: [XFile(file.path, mimeType: 'text/csv')],
      ),
    );
  }
}
