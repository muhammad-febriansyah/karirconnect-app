import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:toastification/toastification.dart';

import 'app/core/theme/app_scroll_behavior.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/services/api_service.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/storage_service.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  await GetStorage.init();

  // Order matters: ApiService reads the persisted access token from storage,
  // and AuthService builds a repository on top of ApiService.
  final storage = Get.put<StorageService>(StorageService(), permanent: true);
  final api = Get.put<ApiService>(ApiService(storage), permanent: true);
  final auth = Get.put<AuthService>(AuthService(storage), permanent: true);

  // ApiService refreshes the access token on a 401 by itself; this is how it
  // reports the case where even that failed and the session is really over.
  api.onSessionExpired = auth.handleSessionExpired;

  runApp(const KarirConnectApp());
}

class KarirConnectApp extends StatelessWidget {
  const KarirConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => GetMaterialApp(
          title: 'KarirConnect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          scrollBehavior: const AppScrollBehavior(),
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,
          defaultTransition: Transition.cupertino,
        ),
      ),
    );
  }
}
