import 'package:intl/intl.dart';

String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

DateTime parseDay(String key) => DateTime.parse(key);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime today() => dateOnly(DateTime.now());

/// Soma dias pelo calendário (evita problemas com horário de verão).
DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "sexta-feira, 2 de outubro"
String longDate(DateTime d) => capitalize(DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(d));

/// "2 out"
String shortDate(DateTime d) => DateFormat("d MMM", 'pt_BR').format(d).replaceAll('.', '');

String formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
