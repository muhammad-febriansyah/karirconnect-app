/// Asset paths. The two logo files keep the upload hashes they arrived with,
/// so they are only ever referenced through these constants.
class AppAssets {
  AppAssets._();

  static const String logoMark =
      'assets/DAZPh3gmm0r0jpflN9948J7dY2KQHYMikCuyR32o.png';
  static const String logoFull =
      'assets/oB7U4no2AbQOA1qYv7Cu3GK6k7CFngApIrbcwNtM.png';

  /// Onboarding slides. Headline, subheadline and the page dots are already
  /// baked into the artwork, so the views must not draw their own copy —
  /// only the top skip control and the bottom action row.
  static const List<String> onboarding = [
    'assets/1.png',
    'assets/2.png',
    'assets/3.png',
  ];
}
