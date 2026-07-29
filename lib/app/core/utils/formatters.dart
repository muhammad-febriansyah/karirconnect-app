/// Ports of the display helpers the web landing page uses, so a job card reads
/// identically on both surfaces.
///
/// Sources:
///  - `formatRupiahShort` / `formatRelative` in `resources/js/pages/welcome.tsx`
///  - `formatStatus` in `resources/js/lib/format-status.ts`
class Formatters {
  Formatters._();

  /// Thousands-grouped count, Indonesian style: `1240` -> `1.240`.
  static String count(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }

  /// Compact rupiah label, e.g. `Rp 5 jt` / `Rp 800rb`.
  static String rupiahShort(int? value) {
    if (value == null || value == 0) return '';

    if (value >= 1000000) {
      final millions = value / 1000000;
      return 'Rp ${millions.toStringAsFixed(value % 1000000 == 0 ? 0 : 1)} jt';
    }

    if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    }

    return 'Rp $value';
  }

  /// Salary range as the job card renders it, falling back to `Negotiable`
  /// when the employer hid it.
  static String salaryRange({
    required bool isVisible,
    int? min,
    int? max,
  }) {
    if (!isVisible || min == null || min == 0) return 'Negotiable';

    if (max != null && max != 0 && max != min) {
      return '${rupiahShort(min)} – ${rupiahShort(max)}';
    }

    return rupiahShort(min);
  }

  static const List<String> _monthsId = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// Short relative label: `Baru saja`, `12 menit lalu`, `3j lalu`, `5h lalu`,
  /// then an absolute `dd MMM` date past 30 days.
  static String relative(String? iso) {
    if (iso == null || iso.isEmpty) return '';

    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '';

    final minutes = DateTime.now().difference(parsed.toLocal()).inMinutes;

    if (minutes < 1) return 'Baru saja';
    if (minutes < 60) return '$minutes menit lalu';

    final hours = minutes ~/ 60;
    if (hours < 24) return '${hours}j lalu';

    final days = hours ~/ 24;
    if (days < 30) return '${days}h lalu';

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    return '$day ${_monthsId[local.month - 1]}';
  }

  /// Absolute date, `23 Jun 2026`. Use this for anything forward-looking — a
  /// deadline rendered through [relative] would read "5h lalu".
  ///
  /// Returns the raw string when it will not parse, so a server format this
  /// does not expect still shows something rather than an empty cell.
  static String date(String? iso) {
    if (iso == null || iso.isEmpty) return '';

    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;

    final local = parsed.toLocal();
    return '${local.day} ${_monthsId[local.month - 1]} ${local.year}';
  }

  /// Whole days from now until [iso], negative once it has passed. Null when
  /// the value is absent or unparseable.
  static int? daysUntil(String? iso) {
    if (iso == null || iso.isEmpty) return null;

    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;

    final now = DateTime.now();
    final target = parsed.toLocal();

    return DateTime(target.year, target.month, target.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  /// Enum value to Indonesian label. Only the enums the job card renders are
  /// mapped; anything else falls back to a humanised form of the raw value.
  static const Map<String, String> _statusLabels = {
    // EmploymentType
    'full_time': 'Full-time',
    'part_time': 'Part-time',
    'contract': 'Kontrak',
    'internship': 'Magang',
    'freelance': 'Freelance',

    // WorkArrangement
    'onsite': 'Onsite',
    'remote': 'Remote',
    'hybrid': 'Hybrid',

    // ApplicationStatus — the API sends `status_label` alongside the value on
    // an application itself, but the status *logs* carry only the raw value.
    'submitted': 'Dikirim',
    'reviewed': 'Ditinjau',
    'shortlisted': 'Shortlist',
    'interview': 'Interview',
    'offered': 'Ditawari',
    'hired': 'Diterima',
    'rejected': 'Ditolak',
    'withdrawn': 'Dibatalkan',

    // ExperienceLevel
    'entry': 'Entry',
    'junior': 'Junior',
    'mid': 'Mid',
    'senior': 'Senior',
    'lead': 'Lead',
    'executive': 'Eksekutif',

    // EducationLevel — ported from `App\Enums\EducationLevel::label()`. The
    // resource sends only `min_education->value`, so without these the
    // fallback humaniser renders `sma` as "Sma".
    'sma': 'SMA / SMK',
    'd3': 'Diploma 3',
    'd4': 'Diploma 4',
    's1': 'Sarjana (S1)',
    's2': 'Magister (S2)',
    's3': 'Doktor (S3)',
    'other': 'Lainnya',
  };

  static String status(String? value) {
    if (value == null || value.isEmpty) return '-';

    final mapped = _statusLabels[value];
    if (mapped != null) return mapped;

    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Up to two initials, used when a company has no logo.
  static String initials(String? value) {
    final source = (value ?? '').trim();
    if (source.isEmpty) return '?';

    final words = source.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);

    return words
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
  }

  /// Rich text from the web editors arrives as a mix of HTML and markdown.
  /// Rendering it raw shows tags and `**` markers, and pulling in an HTML
  /// widget for a handful of fields is not worth it — so tags are stripped,
  /// list items become bullets, and markdown emphasis is unwrapped.
  static String richTextToPlain(String? html) {
    if (html == null || html.isEmpty) return '';

    return html
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(
          RegExp(r'</(p|div|li|h[1-6])>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAllMapped(
          RegExp(r'\*\*(.+?)\*\*', dotAll: true),
          (match) => match.group(1)!,
        )
        .replaceAllMapped(
          RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)', dotAll: true),
          (match) => match.group(1)!,
        )
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
