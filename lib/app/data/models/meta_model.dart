import 'job_category_model.dart';

/// A `{value, label}` pair as the enums' `selectItems()` emits them.
class SelectOption {
  const SelectOption({required this.value, required this.label});

  final String value;
  final String label;

  factory SelectOption.fromJson(Map<String, dynamic> json) => SelectOption(
        value: json['value']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );
}

class ProvinceModel {
  const ProvinceModel({required this.id, required this.name});

  final int id;
  final String name;

  factory ProvinceModel.fromJson(Map<String, dynamic> json) => ProvinceModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
      );
}

class CityModel {
  const CityModel({
    required this.id,
    required this.name,
    required this.provinceId,
  });

  final int id;
  final String name;
  final int provinceId;

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        provinceId: (json['province_id'] as num?)?.toInt() ?? 0,
      );
}

/// `GET api/v1/meta` — the whole filter taxonomy in one call, cached an hour
/// server-side.
class AppMeta {
  const AppMeta({
    required this.jobCategories,
    required this.provinces,
    required this.cities,
    required this.employmentTypes,
    required this.workArrangements,
    required this.experienceLevels,
    required this.educationLevels,
  });

  final List<JobCategoryModel> jobCategories;
  final List<ProvinceModel> provinces;

  /// The endpoint ships every Indonesian city in one payload, on purpose: the
  /// picker is expected to filter by province offline rather than round-trip.
  final List<CityModel> cities;

  final List<SelectOption> employmentTypes;
  final List<SelectOption> workArrangements;
  final List<SelectOption> experienceLevels;
  final List<SelectOption> educationLevels;

  static const AppMeta empty = AppMeta(
    jobCategories: [],
    provinces: [],
    cities: [],
    employmentTypes: [],
    workArrangements: [],
    experienceLevels: [],
    educationLevels: [],
  );

  List<CityModel> citiesIn(int? provinceId) => provinceId == null
      ? const []
      : cities.where((city) => city.provinceId == provinceId).toList();

  factory AppMeta.fromJson(Map<String, dynamic> json) => AppMeta(
        jobCategories: _list(json, 'job_categories', JobCategoryModel.fromJson),
        provinces: _list(json, 'provinces', ProvinceModel.fromJson),
        cities: _list(json, 'cities', CityModel.fromJson),
        employmentTypes: _list(json, 'employment_types', SelectOption.fromJson),
        workArrangements:
            _list(json, 'work_arrangements', SelectOption.fromJson),
        experienceLevels:
            _list(json, 'experience_levels', SelectOption.fromJson),
        educationLevels:
            _list(json, 'education_levels', SelectOption.fromJson),
      );

  static List<T> _list<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) =>
      (json[key] as List? ?? const [])
          .whereType<Map>()
          .map((row) => parse(row.cast<String, dynamic>()))
          .toList();
}
