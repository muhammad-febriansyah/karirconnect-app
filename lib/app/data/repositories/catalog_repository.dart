import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../models/company_detail_model.dart';
import '../models/company_model.dart';
import '../models/job_category_model.dart';
import '../models/career_resource_model.dart';
import '../models/job_detail_model.dart';
import '../models/job_model.dart';
import '../models/meta_model.dart';
import '../models/paginated.dart';
import '../models/salary_insight_model.dart';
import '../providers/api_request.dart';
import '../services/api_service.dart';

/// The public browsing half of the API — everything a guest may read.
///
/// The backend deliberately leaves these routes unauthenticated so the app can
/// show jobs before signup (see the comment above the routes in
/// `routes/api.php`). Anything behind `role:employee` belongs in another
/// repository.
class CatalogRepository with ApiRequestMixin {
  CatalogRepository({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  final ApiService _api;

  /// `GET api/v1/jobs`. Server caps `per_page` at 50 and defaults to 20.
  ///
  /// [sort] accepts `latest`, `oldest`, `salary_desc`, `salary_asc`.
  Future<Paginated<JobModel>> jobs({
    String? search,
    int? categoryId,
    int? provinceId,
    int? cityId,
    String? employmentType,
    String? workArrangement,
    String? experienceLevel,
    bool? featuredOnly,
    String sort = 'latest',
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/jobs',
        query: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          'sort': sort,
          if (search != null && search.isNotEmpty) 'search': search,
          'category_id': ?categoryId,
          'province_id': ?provinceId,
          'city_id': ?cityId,
          'employment_type': ?employmentType,
          'work_arrangement': ?workArrangement,
          'experience_level': ?experienceLevel,
          // The server casts this with boolean(), so only send it when true —
          // `featured_only=0` and an absent key mean the same thing there.
          if (featuredOnly == true) 'featured_only': 1,
        },
      ),
    );

    return Paginated.fromJson(response, JobModel.fromJson);
  }

  /// `GET api/v1/companies`. Rows carry `open_jobs_count` (published only).
  Future<Paginated<CompanyModel>> companies({
    String? search,
    int? industryId,
    int? provinceId,
    bool verifiedOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/companies',
        query: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
          'industry_id': ?industryId,
          'province_id': ?provinceId,
          if (verifiedOnly) 'verified_only': 1,
        },
      ),
    );

    return Paginated.fromJson(response, CompanyModel.fromJson);
  }

  /// `GET api/v1/meta` — the whole filter taxonomy in one call, cached an hour
  /// server-side.
  Future<AppMeta> meta() async {
    final response = await send(() => _api.get<Map<String, dynamic>>('/meta'));

    return AppMeta.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Convenience for callers that only draw the category chips.
  Future<List<JobCategoryModel>> jobCategories() async =>
      (await meta()).jobCategories;

  /// `GET api/v1/salary-insights`. Public and unpaginated — the server returns
  /// the whole aggregate in one payload.
  Future<SalaryInsightData> salaryInsights({
    int? jobCategoryId,
    int? provinceId,
    String? experienceLevel,
  }) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/salary-insights',
        query: <String, dynamic>{
          'job_category_id': ?jobCategoryId,
          'province_id': ?provinceId,
          'experience_level': ?experienceLevel,
        },
      ),
    );

    return SalaryInsightData.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// `GET api/v1/career-resources`. Hand-built payload, so `meta` carries only
  /// `current_page` / `last_page` / `total`.
  Future<Paginated<CareerResourceModel>> careerResources({
    String? search,
    String? category,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/career-resources',
        query: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
          'category': ?category,
        },
      ),
    );

    return Paginated.fromJson(response, CareerResourceModel.fromJson);
  }

  /// `GET api/v1/jobs/{slug}`. Public, but the bearer token is honoured when
  /// present — `meta` then also carries `is_saved`, `match_score` and
  /// `has_applied`.
  Future<JobDetailModel> job(String slug) async {
    final response =
        await send(() => _api.get<Map<String, dynamic>>('/jobs/$slug'));

    return JobDetailModel.fromResponse(response);
  }

  /// `GET api/v1/companies/{slug}`. 404s for a pending or suspended employer —
  /// their existence is not public.
  Future<CompanyDetailModel> company(String slug) async {
    final response =
        await send(() => _api.get<Map<String, dynamic>>('/companies/$slug'));

    return CompanyDetailModel.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// `GET api/v1/companies/{slug}/jobs`.
  ///
  /// This endpoint does **not** eager-load skills, so `JobModel.skills` is
  /// always empty here — unlike `jobs()`.
  Future<Paginated<JobModel>> companyJobs(
    String slug, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/companies/$slug/jobs',
        query: <String, dynamic>{'page': page, 'per_page': perPage},
      ),
    );

    return Paginated.fromJson(response, JobModel.fromJson);
  }

  /// `GET api/v1/companies/{slug}/reviews`. Approved reviews only, with the
  /// aggregate under `meta.stats`.
  Future<({List<CompanyReviewModel> items, int total, double avgRating})>
      companyReviews(String slug, {int perPage = 10}) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/companies/$slug/reviews',
        query: <String, dynamic>{'per_page': perPage},
      ),
    );

    final meta = (response['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final stats = (meta['stats'] as Map?)?.cast<String, dynamic>() ?? const {};

    return (
      items: (response['data'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => CompanyReviewModel.fromJson(row.cast<String, dynamic>()))
          .toList(),
      total: (stats['total'] as num?)?.toInt() ?? 0,
      avgRating: (stats['avg_rating'] as num?)?.toDouble() ?? 0,
    );
  }

  /// `GET api/v1/career-resources/{slug}`. 404s for an unpublished draft.
  Future<CareerResourceDetailModel> careerResource(String slug) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>('/career-resources/$slug'),
    );

    return CareerResourceDetailModel.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
