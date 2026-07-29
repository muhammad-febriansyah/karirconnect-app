/// `GET api/v1/salary-insights` — public, aggregated salary data.
///
/// Every figure is derived from published job postings plus *approved* salary
/// submissions, so `sampleSize` is what tells the user how much to trust it.
class SalaryInsightData {
  const SalaryInsightData({
    required this.aggregate,
    required this.topCompanies,
    required this.popularCategories,
    required this.curatedInsights,
  });

  final SalaryAggregate aggregate;
  final List<SalaryCompany> topCompanies;
  final List<SalaryCategory> popularCategories;
  final List<CuratedSalaryInsight> curatedInsights;

  static const SalaryInsightData empty = SalaryInsightData(
    aggregate: SalaryAggregate.empty,
    topCompanies: [],
    popularCategories: [],
    curatedInsights: [],
  );

  factory SalaryInsightData.fromJson(Map<String, dynamic> json) =>
      SalaryInsightData(
        aggregate: SalaryAggregate.fromJson(
          (json['aggregate'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        topCompanies: _list(json, 'top_companies', SalaryCompany.fromJson),
        popularCategories:
            _list(json, 'popular_categories', SalaryCategory.fromJson),
        curatedInsights:
            _list(json, 'curated_insights', CuratedSalaryInsight.fromJson),
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

class SalaryAggregate {
  const SalaryAggregate({
    required this.sampleSize,
    required this.postingCount,
    required this.submissionCount,
    this.p25,
    this.p50,
    this.p75,
    this.min,
    this.max,
    this.average,
  });

  final int sampleSize;
  final int postingCount;
  final int submissionCount;
  final int? p25;
  final int? p50;
  final int? p75;
  final int? min;
  final int? max;
  final int? average;

  bool get hasData => sampleSize > 0 && p50 != null;

  static const SalaryAggregate empty = SalaryAggregate(
    sampleSize: 0,
    postingCount: 0,
    submissionCount: 0,
  );

  factory SalaryAggregate.fromJson(Map<String, dynamic> json) =>
      SalaryAggregate(
        sampleSize: (json['sample_size'] as num?)?.toInt() ?? 0,
        postingCount: (json['posting_count'] as num?)?.toInt() ?? 0,
        submissionCount: (json['submission_count'] as num?)?.toInt() ?? 0,
        p25: (json['p25'] as num?)?.toInt(),
        p50: (json['p50'] as num?)?.toInt(),
        p75: (json['p75'] as num?)?.toInt(),
        min: (json['min'] as num?)?.toInt(),
        max: (json['max'] as num?)?.toInt(),
        average: (json['average'] as num?)?.toInt(),
      );
}

class SalaryCompany {
  const SalaryCompany({
    required this.companyName,
    required this.slug,
    required this.count,
    this.p50,
  });

  final String companyName;
  final String slug;
  final int count;
  final int? p50;

  factory SalaryCompany.fromJson(Map<String, dynamic> json) => SalaryCompany(
        companyName: json['company_name'] as String? ?? 'Unknown',
        slug: json['slug'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        p50: (json['p50'] as num?)?.toInt(),
      );
}

class SalaryCategory {
  const SalaryCategory({
    required this.id,
    required this.name,
    required this.count,
  });

  final int id;
  final String name;
  final int count;

  factory SalaryCategory.fromJson(Map<String, dynamic> json) => SalaryCategory(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

class CuratedSalaryInsight {
  const CuratedSalaryInsight({
    required this.id,
    required this.jobTitle,
    this.roleCategory,
    this.city,
    this.experienceLevel,
    this.minSalary,
    this.medianSalary,
    this.maxSalary,
    this.sampleSize,
  });

  final int id;
  final String jobTitle;
  final String? roleCategory;
  final String? city;
  final String? experienceLevel;
  final int? minSalary;
  final int? medianSalary;
  final int? maxSalary;
  final int? sampleSize;

  factory CuratedSalaryInsight.fromJson(Map<String, dynamic> json) =>
      CuratedSalaryInsight(
        id: (json['id'] as num?)?.toInt() ?? 0,
        jobTitle: json['job_title'] as String? ?? '',
        roleCategory: json['role_category'] as String?,
        city: json['city'] as String?,
        experienceLevel: json['experience_level'] as String?,
        minSalary: (json['min_salary'] as num?)?.toInt(),
        medianSalary: (json['median_salary'] as num?)?.toInt(),
        maxSalary: (json['max_salary'] as num?)?.toInt(),
        sampleSize: (json['sample_size'] as num?)?.toInt(),
      );
}
