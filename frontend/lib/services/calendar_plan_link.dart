class CalendarPlanLink {
  const CalendarPlanLink();

  Uri build({
    required DateTime date,
    required String title,
    required String details,
    required String location,
    required String timezone,
  }) {
    final nextDay = date.add(const Duration(days: 1));
    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${_compactDate(date)}/${_compactDate(nextDay)}',
      'details': details,
      'location': location,
      'ctz': timezone,
    });
  }

  String _compactDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}'
      '${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}';
}
