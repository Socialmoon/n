const Duration indiaTimeOffset = Duration(hours: 5, minutes: 30);

DateTime toIst(DateTime value) {
  return value.toUtc().add(indiaTimeOffset);
}

DateTime istNow() {
  return toIst(DateTime.now());
}

DateTime istDateOnly(DateTime value) {
  final ist = toIst(value);
  return DateTime(ist.year, ist.month, ist.day);
}

String formatIstDateTime(DateTime value) {
  final ist = toIst(value);
  final day = ist.day.toString().padLeft(2, '0');
  final month = ist.month.toString().padLeft(2, '0');
  final year = ist.year;
  final hour = ist.hour.toString().padLeft(2, '0');
  final minute = ist.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

String formatIstDate(DateTime value) {
  final ist = toIst(value);
  final day = ist.day.toString().padLeft(2, '0');
  final month = ist.month.toString().padLeft(2, '0');
  final year = ist.year;
  return '$day/$month/$year';
}

String formatIstRelativeDateTime(DateTime value, {DateTime? now}) {
  final ist = toIst(value);
  final dateOnly = DateTime(ist.year, ist.month, ist.day);
  final nowIst = toIst(now ?? DateTime.now());
  final today = DateTime(nowIst.year, nowIst.month, nowIst.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final time = '${ist.hour.toString().padLeft(2, '0')}:${ist.minute.toString().padLeft(2, '0')}';

  if (dateOnly == today) {
    return 'Today, $time';
  }
  if (dateOnly == yesterday) {
    return 'Yesterday, $time';
  }
  return formatIstDateTime(value);
}

DateTime parseServerDateTime(
  dynamic raw, {
  bool assumeIstWhenTimezoneMissing = true,
}) {
  if (raw is DateTime) {
    return raw.toUtc();
  }

  final text = (raw ?? '').toString().trim();
  if (text.isEmpty) {
    return DateTime.now().toUtc();
  }

  final hasTimezone = RegExp(r'(Z|[+-][0-9]{2}:[0-9]{2})$').hasMatch(text);
  if (hasTimezone) {
    return DateTime.parse(text).toUtc();
  }

  final parsed = DateTime.parse(text);
  if (!assumeIstWhenTimezoneMissing) {
    return parsed.toUtc();
  }

  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  ).subtract(indiaTimeOffset);
}