import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../models/application_detail_model.dart';
import '../models/cv_model.dart';
import '../models/application_model.dart';
import '../models/employee_profile_model.dart';
import '../models/profile_record_models.dart';
import '../models/interview_model.dart';
import '../models/job_alert_model.dart';
import '../models/job_model.dart';
import '../models/recommendation_model.dart';
import '../models/paginated.dart';
import '../providers/api_request.dart';
import '../services/api_service.dart';

/// Everything behind `auth:api` + `role:employee`.
///
/// Every call here 401s without a session, so screens must gate on
/// `AuthService.isLoggedIn` before reaching for it.
class EmployeeRepository with ApiRequestMixin {
  EmployeeRepository({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  final ApiService _api;

  /// `GET api/v1/applications`. [status] filters by `ApplicationStatus`.
  Future<Paginated<ApplicationModel>> applications({
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/applications',
        query: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          'status': ?status,
        },
      ),
    );

    return Paginated.fromJson(response, ApplicationModel.fromJson);
  }

  /// `GET api/v1/profile`. The response also carries `meta.missing_items`,
  /// which lists what the profile still needs to reach 100%.
  Future<({EmployeeProfileModel profile, List<ProfileMissingItem> missingItems})>
      profile() async {
    final response =
        await send(() => _api.get<Map<String, dynamic>>('/profile'));

    final meta = (response['meta'] as Map?)?.cast<String, dynamic>() ?? const {};

    return (
      profile: EmployeeProfileModel.fromJson(
        (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      missingItems: (meta['missing_items'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => ProfileMissingItem.fromJson(
                item.cast<String, dynamic>(),
              ))
          .toList(),
    );
  }

  Future<Paginated<JobModel>> savedJobs({int page = 1, int perPage = 20}) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/saved-jobs',
        query: <String, dynamic>{'page': page, 'per_page': perPage},
      ),
    );

    return Paginated.fromJson(response, JobModel.fromJson);
  }

  Future<void> saveJob(String slug) =>
      send(() => _api.post<Map<String, dynamic>>('/saved-jobs/$slug'));

  Future<void> unsaveJob(String slug) =>
      send(() => _api.delete<Map<String, dynamic>>('/saved-jobs/$slug'));

  // ---- Recommendations ---------------------------------------------------

  /// `GET api/v1/recommendations`. Server caps `limit` at 30.
  ///
  /// Returns the rows plus the profile completion the response reports, which
  /// is what an empty list should be explained by.
  Future<({List<RecommendationModel> items, int profileCompletion})>
      recommendations({int limit = 12}) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/recommendations',
        query: <String, dynamic>{'limit': limit},
      ),
    );

    final meta = (response['meta'] as Map?)?.cast<String, dynamic>() ?? const {};

    return (
      items: (response['data'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => RecommendationModel.fromJson(row.cast<String, dynamic>()))
          .toList(),
      profileCompletion: (meta['profile_completion'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> dismissRecommendation(String slug) => send(
        () => _api.post<Map<String, dynamic>>('/recommendations/$slug/dismiss'),
      );

  // ---- Job alerts --------------------------------------------------------

  /// `GET api/v1/job-alerts`. Unpaginated — the controller returns the whole
  /// list under `data`.
  Future<List<JobAlertModel>> jobAlerts() async {
    final response =
        await send(() => _api.get<Map<String, dynamic>>('/job-alerts'));

    return (response['data'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => JobAlertModel.fromJson(row.cast<String, dynamic>()))
        .toList();
  }

  Future<JobAlertModel> createJobAlert(Map<String, dynamic> payload) async {
    final response = await send(
      () => _api.post<Map<String, dynamic>>('/job-alerts', data: payload),
    );

    return JobAlertModel.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Future<JobAlertModel> updateJobAlert(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await send(
      () => _api.put<Map<String, dynamic>>('/job-alerts/$id', data: payload),
    );

    return JobAlertModel.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Future<void> deleteJobAlert(int id) =>
      send(() => _api.delete<Map<String, dynamic>>('/job-alerts/$id'));

  /// What an alert would match right now, so the user can tune it before
  /// waiting for a digest.
  Future<List<JobModel>> previewJobAlert(int id) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>('/job-alerts/$id/preview'),
    );

    return (response['data'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => JobModel.fromJson(row.cast<String, dynamic>()))
        .toList();
  }

  // ---- Interviews --------------------------------------------------------

  Future<Paginated<InterviewModel>> interviews({
    String? status,
    bool upcomingOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/interviews',
        query: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          'status': ?status,
          if (upcomingOnly) 'upcoming': 1,
        },
      ),
    );

    return Paginated.fromJson(response, InterviewModel.fromJson);
  }

  /// [answer] is `accepted`, `declined` or `tentative`. Accepting is what
  /// confirms the interview server-side.
  Future<InterviewModel> respondToInterview(int id, String answer) async {
    final body = await send(
      () => _api.post<Map<String, dynamic>>(
        '/interviews/$id/respond',
        data: {'response': answer},
      ),
    );

    return InterviewModel.fromJson(
      (body['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Server requires 1-5 proposed slots, each strictly in the future.
  Future<void> requestReschedule({
    required int id,
    required String reason,
    required List<DateTime> proposedSlots,
  }) =>
      send(
        () => _api.post<Map<String, dynamic>>(
          '/interviews/$id/reschedule',
          data: {
            'reason': reason,
            'proposed_slots': proposedSlots
                .map((slot) => slot.toUtc().toIso8601String())
                .toList(),
          },
        ),
      );

  // ---- Applying ----------------------------------------------------------

  /// `POST api/v1/jobs/{slug}/apply`.
  ///
  /// Every guard lives in `SubmitApplicationAction` server-side: the job must
  /// be published, not already applied to, not the applicant's own company, and
  /// the profile must be at least 60% complete. All of those come back as a
  /// 422/403 `ApiException`, so callers should surface the message rather than
  /// pre-judging eligibility.
  Future<void> apply({
    required String slug,
    String? coverLetter,
    int? expectedSalary,
    int? candidateCvId,
    List<Map<String, dynamic>>? answers,
  }) =>
      send(
        () => _api.post<Map<String, dynamic>>(
          '/jobs/$slug/apply',
          data: {
            'cover_letter': ?coverLetter,
            'expected_salary': ?expectedSalary,
            'candidate_cv_id': ?candidateCvId,
            if (answers != null && answers.isNotEmpty) 'answers': answers,
          },
        ),
      );

  Future<ApplicationDetailModel> application(int id) async {
    final response =
        await send(() => _api.get<Map<String, dynamic>>('/applications/$id'));

    return ApplicationDetailModel.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Refused server-side once the application reached hired / rejected /
  /// withdrawn — at that point the process is over and withdrawing would
  /// rewrite history rather than stop it.
  Future<void> withdrawApplication(int id) =>
      send(() => _api.post<Map<String, dynamic>>('/applications/$id/withdraw'));

  // ---- Profile ------------------------------------------------------------

  /// `POST api/v1/profile`. `is_open_to_work` and `visibility` are required by
  /// `ProfileUpdateRequest`, so they are always sent.
  Future<void> updateProfile(Map<String, dynamic> payload) =>
      send(() => _api.post<Map<String, dynamic>>('/profile', data: payload));

  // ---- Educations ---------------------------------------------------------

  Future<List<EducationModel>> educations() =>
      _records('/profile/educations', EducationModel.fromJson);

  Future<void> createEducation(Map<String, dynamic> payload) =>
      send(() => _api.post<Map<String, dynamic>>(
            '/profile/educations',
            data: payload,
          ));

  Future<void> updateEducation(int id, Map<String, dynamic> payload) =>
      send(() => _api.put<Map<String, dynamic>>(
            '/profile/educations/$id',
            data: payload,
          ));

  Future<void> deleteEducation(int id) =>
      send(() => _api.delete<Map<String, dynamic>>('/profile/educations/$id'));

  // ---- Work experiences ---------------------------------------------------

  Future<List<WorkExperienceModel>> workExperiences() =>
      _records('/profile/work-experiences', WorkExperienceModel.fromJson);

  Future<void> createWorkExperience(Map<String, dynamic> payload) =>
      send(() => _api.post<Map<String, dynamic>>(
            '/profile/work-experiences',
            data: payload,
          ));

  Future<void> updateWorkExperience(int id, Map<String, dynamic> payload) =>
      send(() => _api.put<Map<String, dynamic>>(
            '/profile/work-experiences/$id',
            data: payload,
          ));

  Future<void> deleteWorkExperience(int id) => send(
        () => _api.delete<Map<String, dynamic>>('/profile/work-experiences/$id'),
      );

  // ---- Certifications -----------------------------------------------------

  Future<List<CertificationModel>> certifications() =>
      _records('/profile/certifications', CertificationModel.fromJson);

  Future<void> createCertification(Map<String, dynamic> payload) =>
      send(() => _api.post<Map<String, dynamic>>(
            '/profile/certifications',
            data: payload,
          ));

  Future<void> updateCertification(int id, Map<String, dynamic> payload) =>
      send(() => _api.put<Map<String, dynamic>>(
            '/profile/certifications/$id',
            data: payload,
          ));

  Future<void> deleteCertification(int id) => send(
        () => _api.delete<Map<String, dynamic>>('/profile/certifications/$id'),
      );

  /// The three profile sub-resources share one controller trait server-side and
  /// so share one envelope: an unpaginated list under `data`.
  Future<List<T>> _records<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final response = await send(() => _api.get<Map<String, dynamic>>(path));

    return (response['data'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => parse(row.cast<String, dynamic>()))
        .toList();
  }

  // ---- CVs ----------------------------------------------------------------

  /// `GET api/v1/cvs`. Unpaginated, with the profile's primary resume id under
  /// `meta`.
  Future<({List<CandidateCvModel> items, int? primaryResumeId})> cvs() async {
    final response = await send(() => _api.get<Map<String, dynamic>>('/cvs'));

    final meta = (response['meta'] as Map?)?.cast<String, dynamic>() ?? const {};

    return (
      items: (response['data'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => CandidateCvModel.fromJson(row.cast<String, dynamic>()))
          .toList(),
      primaryResumeId: (meta['primary_resume_id'] as num?)?.toInt(),
    );
  }

  /// `POST api/v1/cvs` — multipart. Server accepts pdf/doc/docx up to 5 MB and
  /// recomputes profile completion, since a CV is worth 10 points toward the
  /// 60% needed to apply.
  Future<void> uploadCv({
    required String label,
    required String filePath,
    required String fileName,
  }) =>
      send(
        () => _api.post<Map<String, dynamic>>(
          '/cvs',
          data: FormData.fromMap({
            'label': label,
            'file': MultipartFile.fromFileSync(filePath, filename: fileName),
          }),
        ),
      );

  /// Both fields are `required` server-side, so a rename must resend
  /// `is_active` and vice versa.
  Future<void> updateCv({
    required int id,
    required String label,
    required bool isActive,
  }) =>
      send(
        () => _api.post<Map<String, dynamic>>(
          '/cvs/$id',
          data: {'label': label, 'is_active': isActive},
        ),
      );

  Future<void> deleteCv(int id) =>
      send(() => _api.delete<Map<String, dynamic>>('/cvs/$id'));

  // ---- CV builder ---------------------------------------------------------

  Future<CvBuilderDraft> cvBuilderDraft() async {
    final response =
        await send(() => _api.get<Map<String, dynamic>>('/cv-builder'));

    return CvBuilderDraft.fromResponse(response);
  }

  /// Renders a PDF server-side and stores it as another CandidateCv, so this
  /// both saves the draft and produces a downloadable file.
  Future<void> buildCv(Map<String, dynamic> payload) =>
      send(() => _api.post<Map<String, dynamic>>('/cv-builder', data: payload));

  // ---- Onboarding ---------------------------------------------------------

  /// `GET api/v1/onboarding`. Same profile payload as `profile()`, plus whether
  /// onboarding was ever completed.
  Future<({EmployeeProfileModel profile, bool completed})> onboarding() async {
    final response =
        await send(() => _api.get<Map<String, dynamic>>('/onboarding'));

    final meta = (response['meta'] as Map?)?.cast<String, dynamic>() ?? const {};

    return (
      profile: EmployeeProfileModel.fromJson(
        (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      completed: meta['completed'] as bool? ?? false,
    );
  }

  /// `POST api/v1/onboarding`. Shares `CompleteOnboardingAction` with the web
  /// wizard, so the required set is the same: headline, about, date_of_birth,
  /// gender, province_id, city_id, experience_level and at least one skill.
  Future<void> completeOnboarding(Map<String, dynamic> payload) =>
      send(() => _api.post<Map<String, dynamic>>('/onboarding', data: payload));

  /// `POST api/v1/onboarding/parse-cv` — multipart, 10 MB cap, throttled to 10
  /// per minute because each call reaches an external model.
  ///
  /// A 422 with `cv_parse_failed` means the extraction produced nothing; the
  /// wizard should fall back to manual entry rather than treat it as an error.
  Future<Map<String, dynamic>> parseCv({
    required String filePath,
    required String fileName,
    String? label,
  }) async {
    final response = await send(
      () => _api.post<Map<String, dynamic>>(
        '/onboarding/parse-cv',
        data: FormData.fromMap({
          'cv_file': MultipartFile.fromFileSync(filePath, filename: fileName),
          'label': ?label,
        }),
      ),
    );

    final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? const {};

    return (data['parsed'] as Map?)?.cast<String, dynamic>() ?? const {};
  }
}
