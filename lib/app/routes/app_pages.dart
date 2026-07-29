import 'package:get/get.dart';

import '../modules/ai_career/bindings/ai_career_binding.dart';
import '../modules/ai_career/views/ai_career_view.dart';
import '../modules/application_detail/bindings/application_detail_binding.dart';
import '../modules/application_detail/views/application_detail_view.dart';
import '../modules/applications/bindings/applications_binding.dart';
import '../modules/applications/views/applications_view.dart';
import '../modules/article_detail/bindings/article_detail_binding.dart';
import '../modules/article_detail/views/article_detail_view.dart';
import '../modules/career_resource/bindings/career_resource_binding.dart';
import '../modules/career_resource/views/career_resource_view.dart';
import '../modules/certification/bindings/certification_binding.dart';
import '../modules/certification/views/certification_view.dart';
import '../modules/company_browse/bindings/company_browse_binding.dart';
import '../modules/company_browse/views/company_browse_view.dart';
import '../modules/company_detail/bindings/company_detail_binding.dart';
import '../modules/company_detail/views/company_detail_view.dart';
import '../modules/cv/bindings/cv_binding.dart';
import '../modules/cv/views/cv_view.dart';
import '../modules/cv_builder/bindings/cv_builder_binding.dart';
import '../modules/cv_builder/views/cv_builder_view.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/education/bindings/education_binding.dart';
import '../modules/education/views/education_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/interview/bindings/interview_binding.dart';
import '../modules/interview/views/interview_view.dart';
import '../modules/job_alert/bindings/job_alert_binding.dart';
import '../modules/job_alert/views/job_alert_view.dart';
import '../modules/job_detail/bindings/job_detail_binding.dart';
import '../modules/job_detail/views/job_detail_view.dart';
import '../modules/jobs/bindings/jobs_binding.dart';
import '../modules/jobs/views/jobs_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/career_coach/bindings/career_coach_binding.dart';
import '../modules/career_coach/views/career_coach_view.dart';
import '../modules/message/bindings/message_binding.dart';
import '../modules/message/views/message_view.dart';
import '../modules/notification/bindings/notification_binding.dart';
import '../modules/notification/views/notification_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/profile_edit/bindings/profile_edit_binding.dart';
import '../modules/profile_edit/views/profile_edit_view.dart';
import '../modules/profile_onboarding/bindings/profile_onboarding_binding.dart';
import '../modules/profile_onboarding/views/profile_onboarding_view.dart';
import '../modules/recommendation/bindings/recommendation_binding.dart';
import '../modules/recommendation/views/recommendation_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/salary_insight/bindings/salary_insight_binding.dart';
import '../modules/salary_insight/views/salary_insight_view.dart';
import '../modules/saved_job/bindings/saved_job_binding.dart';
import '../modules/saved_job/views/saved_job_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/work_experience/bindings/work_experience_binding.dart';
import '../modules/work_experience/views/work_experience_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.ONBOARDING,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: _Paths.JOBS,
      page: () => const JobsView(),
      binding: JobsBinding(),
    ),
    GetPage(
      name: _Paths.AI_CAREER,
      page: () => const AiCareerView(),
      binding: AiCareerBinding(),
    ),
    GetPage(
      name: _Paths.APPLICATIONS,
      page: () => const ApplicationsView(),
      binding: ApplicationsBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.SALARY_INSIGHT,
      page: () => const SalaryInsightView(),
      binding: SalaryInsightBinding(),
    ),
    GetPage(
      name: _Paths.COMPANY_BROWSE,
      page: () => const CompanyBrowseView(),
      binding: CompanyBrowseBinding(),
    ),
    GetPage(
      name: _Paths.CAREER_RESOURCE,
      page: () => const CareerResourceView(),
      binding: CareerResourceBinding(),
    ),
    GetPage(
      name: _Paths.SAVED_JOB,
      page: () => const SavedJobView(),
      binding: SavedJobBinding(),
    ),
    GetPage(
      name: _Paths.RECOMMENDATION,
      page: () => const RecommendationView(),
      binding: RecommendationBinding(),
    ),
    GetPage(
      name: _Paths.JOB_ALERT,
      page: () => const JobAlertView(),
      binding: JobAlertBinding(),
    ),
    GetPage(
      name: _Paths.INTERVIEW,
      page: () => const InterviewView(),
      binding: InterviewBinding(),
    ),
    GetPage(
      name: _Paths.MESSAGE,
      page: () => const MessageView(),
      binding: MessageBinding(),
    ),
    GetPage(
      name: _Paths.CAREER_COACH,
      page: () => const CareerCoachView(),
      binding: CareerCoachBinding(),
    ),
    GetPage(
      name: _Paths.JOB_DETAIL,
      page: () => const JobDetailView(),
      binding: JobDetailBinding(),
    ),
    GetPage(
      name: _Paths.APPLICATION_DETAIL,
      page: () => const ApplicationDetailView(),
      binding: ApplicationDetailBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE_EDIT,
      page: () => const ProfileEditView(),
      binding: ProfileEditBinding(),
    ),
    GetPage(
      name: _Paths.EDUCATION,
      page: () => const EducationView(),
      binding: EducationBinding(),
    ),
    GetPage(
      name: _Paths.WORK_EXPERIENCE,
      page: () => const WorkExperienceView(),
      binding: WorkExperienceBinding(),
    ),
    GetPage(
      name: _Paths.CERTIFICATION,
      page: () => const CertificationView(),
      binding: CertificationBinding(),
    ),
    GetPage(
      name: _Paths.COMPANY_DETAIL,
      page: () => const CompanyDetailView(),
      binding: CompanyDetailBinding(),
    ),
    GetPage(
      name: _Paths.ARTICLE_DETAIL,
      page: () => const ArticleDetailView(),
      binding: ArticleDetailBinding(),
    ),
    GetPage(
      name: _Paths.NOTIFICATION,
      page: () => const NotificationView(),
      binding: NotificationBinding(),
    ),
    GetPage(
      name: _Paths.CV,
      page: () => const CvView(),
      binding: CvBinding(),
    ),
    GetPage(
      name: _Paths.CV_BUILDER,
      page: () => const CvBuilderView(),
      binding: CvBuilderBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE_ONBOARDING,
      page: () => const ProfileOnboardingView(),
      binding: ProfileOnboardingBinding(),
    ),
  ];
}
