# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app (`karirconnect_app`, applicationId `karirconnect.karirconnect_app`) scaffolded with **get_cli** and using **GetX** for state management, DI, and routing. All six platform targets are enabled.

Environment: Dart SDK `^3.11.4` / Flutter 3.41.6 stable.

Key packages: `get`, `get_storage`, `dio`, `flutter_dotenv`, `flutter_screenutil`, `google_fonts` (Poppins), `iconsax`, `toastification`, `persistent_bottom_nav_bar_v2`.

The backend is the Laravel app at `/applications/laravel/karirconnect`. This client targets the **employee (jobseeker)** role only — see "Backend API" below.

## Commands

```bash
flutter pub get
flutter run                                # add -d chrome / -d macos / <device-id>
flutter analyze
flutter test
flutter test test/widget_test.dart         # single file
flutter test --name "substring"            # single test by name
flutter build apk --no-tree-shake-icons    # see caveat below
```

`get_cli` (v1.9.1) is installed at `~/.pub-cache/bin/get`. Generate feature modules rather than hand-creating the folder tree — it writes the bindings/controllers/views triad *and* appends the route:

```bash
get create page:profile
```

**Release builds must pass `--no-tree-shake-icons`.** `iconsax` 0.0.8 ships an icon with codepoint `0`, and the font subsetter aborts with `The value '0' (0) could not be parsed as a valid unicode codepoint` → `IconTreeShakerException`. Debug builds are unaffected.

## Architecture

```
lib/main.dart                          dotenv.load -> GetStorage.init -> Storage/Api/Auth services -> runApp
lib/app/core/theme/app_theme.dart      Poppins text theme, AppRadius + AppSpacing tokens
lib/app/core/values/app_colors.dart    palette mirrored from the web (see below)
lib/app/core/values/app_assets.dart    asset paths (logo files keep their upload hashes)
lib/app/core/utils/formatters.dart     ports of the web's rupiah / relative-time / status helpers
lib/app/core/utils/app_toast.dart      toastification wrapper (context-free)
lib/app/core/widgets/                  JobCard, SectionHeader, states, AuthScaffold, GradientHeader — shared across modules
lib/app/core/widgets/gradient_header.dart  the blue header shell Beranda and Lowongan both wear
lib/app/data/models/                   one class per API resource
lib/app/data/providers/                ApiException + ApiRequestMixin
lib/app/data/repositories/             catalog (public), auth, employee (role-gated)
lib/app/data/services/                 ApiService, StorageService, AuthService — all permanent
lib/app/routes/app_pages.dart          GetPage list: path -> view + binding
lib/app/routes/app_routes.dart         GENERATED — `part of app_pages.dart`, do not edit by hand
lib/app/modules/<feature>/{bindings,controllers,views}/
```

### Widget tree

`ToastificationWrapper` → `ScreenUtilInit` → `GetMaterialApp`. That order matters: `ToastificationWrapper` must sit *above* the app so `AppToast` can fire without a `BuildContext`, and `ScreenUtilInit` must be initialized before any `.w`/`.h`/`.sp`/`.r` extension is evaluated. Design size is `375x812`.

### Boot flow

`AppPages.INITIAL` is `Routes.SPLASH`. `SplashController` holds ~1.8s for its logo animation, then `Get.offAllNamed` to `ONBOARDING` if `StorageService.onboardingSeen` is false, otherwise `DASHBOARD`. Onboarding writes the flag before leaving, so it never replays.

Onboarding artwork (`assets/1..3.png`) already has its headline, subheadline **and page dots** baked in, and the three files do not share an aspect ratio (916x1717 vs 941x1672). `_Slide` therefore lays the image into a box 8% taller than the visible area and clips it back down — a plain `BoxFit.cover` trims a different amount per slide and leaves the baked dots visible on slide 3. Only the top skip control and bottom action row are drawn on top.

### GetX conventions

- `app_routes.dart` is marked `// DO NOT EDIT. This is code generated via package:get_cli`. Add routes with `get create page:<name>`; if editing manually, add the const to both `Routes` and `_Paths` and register the `GetPage` in `AppPages.routes`. `analysis_options.yaml` disables `constant_identifier_names` because that file uses SCREAMING_CAPS.
- Controllers are bound through the route's `Bindings` class, never constructed in a view. Views extend `GetView<XController>` and read the inherited `controller` field — no `Get.put` inside `build`.
- **Read every observable inside the `Obx` builder itself, never inside a lazy `itemBuilder`.** A `ListView.builder` item callback runs outside `Obx`'s tracking scope, so `controller.foo.value` read there registers no dependency: the list silently stops rebuilding and GetX logs "improper use of a GetX has been detected". Hoist to a local at the top of the builder (see `_CategoryTabs` in `home_view.dart`).
- Navigate with `Get.toNamed(Routes.X)` using the generated constants, not string literals.
- Wrap short horizontal `ListView`s in `ScrollConfiguration(... scrollbars: false)`; on web and desktop Flutter paints a scrollbar over the row.

### Dashboard / bottom nav

`DashboardView` is a `PersistentTabView` using `Style13BottomNavBar` (floating circular middle item). Tabs, in order:

| # | Tab | Screen | Backing endpoints |
|---|-----|--------|-------------------|
| 0 | Beranda | `HomeView` | `jobs`, `companies`, `meta`, `saved-jobs` |
| 1 | Lowongan | `JobsView` | `jobs`, `meta`, `saved-jobs` |
| 2 | AI Karier | `AiCareerView` | hub only — links to `ai-interviews`, `career-coach`, `cv-builder`, `skill-assessments` |
| 3 | Lamaran | `ApplicationsView` | `applications` |
| 4 | Profil | `ProfileView` | `profile` |

Two constraints:

- **The tab count must stay odd.** `Style13BottomNavBar` asserts `items.length.isOdd` at construction, and index 2 is the one it floats.
- Tab screens are built directly inside `DashboardView`, so their *routes* never run and their own bindings never fire. Every tab controller is registered in `DashboardBinding` instead. `lazyPut` keeps them uninstantiated until their tab is first shown, so a cold start still only fires the Beranda requests.

`DashboardController` owns the `PersistentTabController` and disposes it in `onClose`. Use `goToTab(i)` from anywhere via `Get.find<DashboardController>()` — that is how the Beranda "Lihat semua" and AI banner jump tabs.

### The header shell

`core/widgets/gradient_header.dart` holds the pieces Beranda and Lowongan share, so the two tabs cannot drift apart:

- `GradientHeader` — the hero gradient block with the contour pattern, a `SafeArea` and the standard gutter. **Square-bottomed**, because `HeaderSheet` owns the curve.
- `HeaderSheet` — the white content sheet that rises over it. Backed by `AppColors.heroGradientEnd` so its rounded top corners reveal blue; that paints the overlap instead of translating it, which keeps the widget's reported height honest.
- `HeaderSearchField` — built by hand rather than through `InputDecorationTheme`, whose `surfaceSoft` fill is tuned for a white page and would nearly vanish on the gradient.
- `HeaderActionButton` — the amber square beside the field, sized to match it. Takes an optional `onTap`; leave it null when a `PopupMenuButton` wraps it and owns the gesture (that is how Lowongan's sort control works).
- `FilterChipButton` — selection is a fill swap, never an outline swap.

### Beranda

Laid out after the Behance job-finder reference the owner supplied: a blue header block (rounded bottom) holding the province picker and notification bell above a white search field plus a yellow filter button, then a horizontal "Lowongan Pilihan" rail, then a category-chipped "Lowongan Terbaru" list, companies rail, AI banner and login CTA.

- The province picker and the filter sheet are both driven by `GET api/v1/meta`, so their options can never drift from what the API accepts. `AppMeta` is named that way on purpose — `MetaData` collides with Flutter's own widget of that name.
- Changing province reloads **both** rails; changing category or a filter reloads only the recent list.
- `JobCard` is shared with the Lowongan tab. Pass `width` to use it inside a horizontal rail, leave it null to fill a vertical list. Rail mode also switches the card to `MainAxisSize.max` and pins the footer with a `Spacer`, so tiles of differing title length still line up; a `Spacer` in list mode would throw against the unbounded height.
- **The attribute chips are a single non-wrapping row, and that is the point.** Postings carry one to four attributes and the old `Wrap` gave every card a different height, which is most of what made the feed look shuffled. `_AttributeChips` measures its own width and renders three chips above 250w, two below — `Flexible` shrinks children *proportionally*, so squeezing a third chip into a rail tile truncates all three instead of dropping one.
- **Quick menu** (`widgets/quick_menu.dart`): eight shortcuts, deliberately the employee endpoints the five tabs do *not* own. Three are public (`salary-insights`, `companies`, `career-resources`) so a guest can use the menu without a login wall; the rest set `requiresAuth` and route to login. Items whose `route` is `null` have no screen yet and toast instead. Rendered as two rows of four, so the list length must stay at eight.
- `QuickMenu` is the white content sheet that the rest of the feed sits on, and it overlaps the header by *painting* rather than by moving: its own background is `AppColors.heroGradientEnd` (the gradient's last stop) so its rounded top corners reveal blue and the two blocks read as one. It replaced a `Transform.translate`, which left a strip of dead space below equal to the offset — a transform does not affect layout. It still shares one `SliverToBoxAdapter` with `HomeHeader`; `HomeHeader` is square-bottomed because the sheet owns that curve.
- The card has no applicant count: `JobResource` does not expose `applications_count` (the web landing gets it from `HomeService`). Posted-time fills that slot instead.

### Lowongan

Wears the same shell as Beranda — `GradientHeader` (title + `meta.total` count + search + amber sort button) over a `HeaderSheet` carrying the filter chips.

- **The header and chip row sit outside the scroll view, not in slivers.** Beranda's header scrolls away because its feed is one page; this list paginates, and filters that scroll off after a hundred results are filters the user cannot get back to.
- Because the chips are pinned and the list scrolls under them, `_FilterBar`'s **bottom padding is load-bearing** — with none, the list's top edge butts flush against the chips and slices a card at the chip baseline, which reads as content bleeding through.
- The count is `controller.total` (from `meta.total`), not `jobs.length` — the latter only counts pages fetched so far, so it would climb as the user scrolls.
- Sort moved from a chip to the amber button so the header matches Beranda's shape. It kept its `PopupMenuButton`, which is why `HeaderActionButton` is given no `onTap` there.

### Detail lowongan

Same shell again: `GradientHeader` (back + save, then logo / title / company) over a `HeaderSheet`.

- **The identity block is fixed, not scrolling.** The body runs long — description, responsibilities, qualifications, benefits, company blurb — and a reader deep in the qualifications should still see which posting they are reading and be able to reach Back.
- Salary is the hero at the top of the sheet, with the deadline under it (amber once it is inside seven days, past-tense wording once it has passed) and `views_count` / `applications_count` as tonal counters. Those two came down on every detail response but had no surface before.
- The apply bar separates from the page by a `surfaceSoft` fill instead of a top border.
- `Formatters.date` / `daysUntil` exist because `relative` is backward-looking — a deadline through it reads "5h lalu".
- `Formatters._statusLabels` now carries `EducationLevel`, ported from the backend enum's `label()`. `JobDetailResource` sends only `min_education->value`, so without the mapping the fallback humaniser rendered `sma` as "Sma".
- **A "Lowongan serupa" bookmark used to save the wrong posting**: those cards were wired to `controller.toggleSave`, which owns the job on screen. They now go through `toggleSaveSimilar` against `savedSimilarSlugs`, keyed by each card's own slug.

### Screens vs the web

The web's jobseeker surface is `routes/employee.php` plus `resources/js/pages/employee/`. Built here: job detail + apply, application index + detail + withdraw, profile show + edit + the educations / work-experiences / certifications CRUD, saved jobs, recommendations, job alerts, interviews, messages, plus the public salary insights / companies / career resources.

Also built beyond the web's employee folder: company detail, article reader, and the notification inbox. CV upload + CV builder and the profile onboarding wizard are in as well.

### CVs and onboarding

`file_picker` 11 exposes **static** methods (`FilePicker.pickFiles`), not the `FilePicker.platform` instance older versions used.

- `POST cvs` and `POST onboarding/parse-cv` are multipart, and their size caps differ: 5 MB for a CV upload, 10 MB for the parser. Both are checked client-side so an oversized file fails instantly.
- `PUT cvs/{id}` requires **both** `label` and `is_active`, so a rename must resend the current active flag or it silently clears it.
- `is_active` — not `primary_resume_id` — is what marks the CV attached to new applications; the server keeps at most one active per profile, so flipping one means reloading the list rather than editing locally. (`primary_resume_id` is null across the seeded data.)
- The CV builder stores periods as **free text** (`"2020 – 2023"`), unlike the profile's own work experiences which use real dates. Its `gpa` is a string too.
- `POST onboarding/parse-cv` costs an AI call and 422s with `cv_parse_failed` when extraction yields nothing — that is a prompt to fill the form manually, not an error to surface as one. The wizard only fills fields the user left blank, so re-parsing never overwrites manual edits.
- The wizard uses an **`IndexedStack`, not a `PageView`**. A `PageView` pinned with `NeverScrollableScrollPhysics` swallows the pointer-scroll events its own children need, which made the step content unscrollable and hid the province and city pickers entirely.
- Cities come from `GET meta` in one payload for every province; the picker filters them offline via `AppMeta.citiesIn(provinceId)`. Changing province must clear the selected city, since the old one belongs to the old province.

The **Career Coach** chat is built (`modules/career_coach`, `career-coach` endpoints, `CareerCoachRepository`): one view that toggles a session list and a chat thread like the Pesan tab, with a welcome/starter-prompt state, optimistic user bubbles, and an animated typing indicator while the reply lands. Reached from the AI Karier hub — `AiFeature.route` now carries the app route, so Career Coach and CV Builder open their screens and the rest still toast "belum tersedia".

Still missing: AI interview run + result, skill assessments, company reviews (authoring), and salary submissions. Avatar upload is also absent from profile edit and the onboarding wizard — both endpoints accept it, but there is no image picker wired yet. Unconsumed endpoints: `PUT profile/skills`, `POST job-alerts/{id}/dispatch`, `POST conversations/start`, `GET search`, `GET dashboard`, `reviews/{id}/helpful`, `GET settings`, `faqs` / `about` / `legal`, `POST contact`.

**`POST api/v1/profile` replaces the whole record.** Any field the edit form does not load is cleared by the next save, which is why `ProfileEditController._fill` reads every field `ProfileUpdateRequest` accepts — including `date_of_birth` and `city_id`, which have no input yet and are simply carried through.

### Payload shapes that do not match their names

Several endpoints are hand-built in the controller rather than going through a resource class, and two of them will throw on a naive cast:

- `recommendations[].explanation` is a **single pre-joined string** (`"2 dari 5 skill cocok · gaji memenuhi ekspektasi"`), not an array. `RecommendationModel` splits on `·`.
- `meta.missing_items` on `GET profile` is a list of `{key, label, href}` objects, not strings.
- `GET job-alerts` is unpaginated — the whole list arrives under `data`.
- `GET conversations` index rows carry no `messages`; only `GET conversations/{id}` populates the thread, and opening it marks it read server-side.
- `GET jobs/{slug}` puts the viewer-specific extras (`is_saved`, `match_score`, `has_applied`) and `similar` under **`meta`**, not `data`, and they are absent entirely for a guest.
- Job and company long-text fields hold a mix of HTML and markdown from the web editors. `Formatters.richTextToPlain` strips tags, turns `<li>` into bullets and unwraps `**bold**`; rendering raw shows both tags and asterisks.
- `GET notifications` ids are Laravel database-notification **UUID strings**, not ints, and `action_url` is a *web* path (`/employee/applications/3`) with no mobile route behind it — tapping a row only marks it read.

### Notifications

In-app inbox only. `POST/DELETE api/v1/device-tokens` exists server-side but is deliberately **not** called, so nothing in this client depends on Firebase — that was the owner's call, with FCM to follow later. Adding push means registering the token against those two routes; `NotificationRepository` and the screen need no changes.

A parse failure inside a repository is **not** an `ApiException`, so a controller that only catches `ApiException` renders it as an empty list rather than an error — which is how the `explanation` bug read as "your profile is 0% complete". Where an empty state carries a specific diagnosis, catch broadly too (see `RecommendationController.load`).

### Colours

`AppColors` mirrors the web design tokens in `/applications/laravel/karirconnect/resources/css/app.css`. The web declares every token in **OKLCH**; the hex values in `AppColors` are what a browser rasterises those to, so both surfaces paint identically. When a token changes there, convert it — do not trust that file's inline hex comments (it annotates brand blue as `#1080e0`, but `oklch(0.62 0.18 248)` actually renders `#008AEB`).

The web uses Inter; this app uses Poppins. Only the palette is shared.

### Scrolling

`GetMaterialApp.scrollBehavior` is `AppScrollBehavior` (`core/theme/app_scroll_behavior.dart`) — **bouncing on every platform, no scrollbar, no Android glow**, set once instead of per widget. Do **not** pass an explicit `physics:` to a scroll view; an explicit one shadows this and loses the bounce on that screen only (that is why `home_view`'s `CustomScrollView` no longer sets `AlwaysScrollableScrollPhysics`). The behavior already composes `AlwaysScrollableScrollPhysics`, so a short/empty list still drags for `RefreshIndicator`.

### Every screen wears the gradient header

There are **no plain white `AppBar`s left** in `lib/app/modules`. `core/widgets/gradient_header.dart` supplies the whole family:

- `GradientHeader` — freeform gradient block, used by the five tabs (each lays out its own title/search/identity child).
- `GradientHeaderBar` — the pre-laid header for **pushed** pages: back circle + title + optional subtitle + optional trailing `HeaderCircleButton` actions + optional `bottom` (a search field, a stat strip). Every `Get.toNamed` destination uses this instead of an `AppBar`.
- `HeaderCircleButton` — the translucent-white circle for header controls (back, save, "baca semua", CV Builder), sized to 44pt.
- `HeaderSheet` / `HeaderSearchField` / `FilterChipButton` — as before.

Conversion pattern for a pushed page: drop `appBar:`, wrap the body in `Column(children: [GradientHeaderBar(...), Expanded(<body>)])`, and keep any `bottomNavigationBar` on the `Scaffold`. Where the body was `body: Obx(() {...})`, it usually moved into a private `_Body extends GetView<TheController>` so the `Obx` stays intact. `record_list_scaffold.dart` carries this for education / work-experience / certification in one place.

Tabs: Beranda, Lowongan, AI Karier, Lamaran, Profil. Lamaran and Profil were white `AppBar`s until moved onto the shell; Profil's identity block used to be a gradient card stacked *inside* a white AppBar page — it is now the header itself. Signed-out Lamaran/Profil/Notifikasi skip the header and show a full-screen `AuthRequiredState`.

`message` keeps a dynamic header: in a thread the title is the counterpart and Back calls `controller.closeThread` (returns to the list) rather than popping the route.

### Bottom sheets

Every bottom sheet shares chrome through `core/widgets/form_fields.dart`:

- `SheetContainer` — the rounded top (same radius as `HeaderSheet`), the `SheetGrabber`, safe-area inset and gutter. The one hairline the borderless system keeps is the grab handle, because a sheet needs a grab affordance.
- `FormSheetShell` — `SheetContainer` + title/subtitle + a scrolling body + a full-width submit button. Used by every form sheet (job-alert, reschedule, education / work-experience / certification, CV-builder entries).
- `SheetShell` (`home/views/widgets/`) — `SheetContainer` + a title row for list/filter sheets (province picker, filter).

`apply_sheet` uses `SheetContainer` directly rather than `FormSheetShell` because its submit button is an `Obx` with a loading spinner that the shell's plain button can't express. Sheet filter chips are fill-swap (`surfaceSoft`/`primary`) like everywhere else. No sheet hand-rolls its grabber or radius any more.

### Surfaces: no borders, no shadows

Cards separate from the page by a **tonal step**, not by a stroke or an elevation. The ladder is `background` (#FFFFFF) < `surfaceSoft` (#F2F6FB) < `muted`, and it must stay in that order or the separation collapses. Anything nested inside a `surfaceSoft` card — chips, logo tiles — inverts to `surfaceInset` (white).

This is enforced in the theme, so most call sites get it for free: `cardTheme` and `chipTheme` have no `side`, every `InputDecorationTheme` state returns a border object (swapping `InputBorder.none` in on some states and an outline on others makes the field jump on focus), and `OutlinedButton` paints as a tonal `accent` fill — it is still an `OutlinedButton` at every call site, just strokeless.

**That `accent` fill is a light blue, so an `OutlinedButton` whose call site only overrides `foregroundColor` can land far below contrast.** Two already did: the "Daftar" button on the AI Karier hero (white on `accent`, 1.5:1 — now a translucent white over the gradient) and "Tolak" in the interview list (`destructive` on `accent`, 4.19:1 — now `destructiveSoft`). When a button is not on a plain light surface, set `backgroundColor` too.

Two more rules the home feed follows:

- **Every rounded corner comes from `AppRadius`, every gap from `AppSpacing`.** Section gaps in particular are all `AppSpacing.section`; the ad-hoc `18.h` / `22.h` / `10.h` values it used to mix were a visible source of the "unplanned" read.
- **A `Container` with an `alignment` expands to its largest allowed size.** That silently stretched the "1 lowongan" and "AI CV Review" badges across their parents. Use padding alone to hug a label, or wrap in an `Align`.

This is now applied app-wide: every `Border.all(color: AppColors.border)` card, the dashboard nav-bar shadow, the message composer's top rule, and the notification/CV state strokes are gone, each replaced by a tonal fill. The remaining `AppColors.border` uses are **hairline table rules and sheet grabbers only** (`Divider`s inside a card, the drag handle on a bottom sheet) — those are legitimate, not card outlines. Selection on every filter chip is a **fill swap**, never an outline swap, via `FilterChipButton`.

Two traps this sweep hit, worth knowing before adding a card:
- A card's fill sometimes lives on a wrapping `Material(color:)`, not on its `BoxDecoration`. Removing a border from the decoration leaves the fill intact there, but a script that only retints `BoxDecoration` colours will miss it — those wrappers had to be retinted by hand.
- A `BoxDecoration` with only `borderRadius` and no `color` is fine *if* a `Material` behind it paints the fill; it is invisible if the parent is the white page. After removing a border, confirm something still paints the fill.

### Config and networking

`.env` is loaded via `dotenv.load()` before `runApp` and is declared as a Flutter **asset** in `pubspec.yaml`. Assets ship inside the app bundle and are extractable from a released APK/IPA — treat `.env` as build configuration (base URLs, timeouts), not as a secret store. `.env` is gitignored; `.env.example` is the committed template, so adding a key means updating both.

`BASE_URL` must end in `/api/v1`. From an Android emulator the host is `10.0.2.2`, not `127.0.0.1`, and a plaintext `http://` base also needs `android:usesCleartextTraffic="true"` in `android/app/src/main/AndroidManifest.xml` (not currently set).

`ApiService` reads `BASE_URL` / `CONNECT_TIMEOUT_MS` / `RECEIVE_TIMEOUT_MS` from dotenv and attaches `Authorization: Bearer <token>`, reading the token from `StorageService` per request rather than caching it — login, logout and refresh all rewrite it.

`validateStatus` accepts anything `< 500`, so a 401 or 422 arrives as an ordinary response instead of throwing. **Every repository call must go through `ApiRequestMixin.send`**, which turns both non-2xx bodies and `DioException`s into `ApiException`; skipping it makes a failed call parse as an empty success.

Import `dio` in files that also import `get` with `hide Response, FormData, MultipartFile` on the `get` import to avoid the name clash.

Never use `dart:io`'s `Platform` in shared code. It compiles for web but throws `UnsupportedError` when read — see `AuthRepository._platform`, which uses `kIsWeb` + `defaultTargetPlatform` instead.

### Auth

`AuthService` (permanent) owns the session. The API pairs a short-lived JWT with a **rotating** refresh token: `POST auth/refresh` burns the old refresh token and returns a new pair, so both must be persisted together.

Refresh-on-401 lives in `ApiService`'s response interceptor — not `onError`, because `validateStatus` lets a 401 through as an ordinary response. Three things there are load-bearing:

- A single shared `_refreshing` future. Without it, a screen firing parallel calls would spend several refresh tokens at once and all but the first would fail, since the server rotates on use.
- The refresh itself goes out on a **bare** `Dio`, so it cannot re-enter the interceptor or pick up the stale Authorization header.
- Requests are retried once (`_retriedFlag`) and `/auth/*` is skipped entirely — refreshing in response to a failed login would recurse and would turn bad credentials into something else.

A transport failure leaves the tokens alone; only a rejected refresh clears the session and fires `onSessionExpired`, which `main.dart` wires to `AuthService.handleSessionExpired`.

Register signs the user in as well (tokens come back on 201), and always sends `role: employee`; `password_confirmation` is required because the server validates with `Password::default()` + `confirmed`. `LoginController` signs an employer or admin straight back out — this client has no screens for those roles and their endpoints would answer 403.

Screens behind `auth:api` + `role:employee` (Lamaran, Profil) check `AuthService.isLoggedIn` and render `AuthRequiredState` instead of firing a request that would only 401. Their controllers also `ever(_auth.user, ...)` so signing in or out reloads the live tab.

### Backend API

The backend is the Laravel app at `/applications/laravel/karirconnect`, routes in `routes/api.php` under the explicit `api/v1` prefix. This client targets the **employee (jobseeker)** role only.

Public and guest-readable: `jobs`, `jobs/{slug}`, `companies`, `companies/{slug}`, `companies/{slug}/jobs`, `meta`, `settings`, `salary-insights`, `faqs`, `about`, `career-resources`.

Three of those have screens: `SalaryInsightView`, `CompanyBrowseView`, `CareerResourceView`. Two shapes there are hand-built rather than resource classes, so they do not follow the usual envelope — `career-resources` reports `created_at` under the `published_at` key and its `category` is a free-text column (no taxonomy endpoint, so the chip row is derived from the first unfiltered page); `salary-insights` returns everything in one unpaginated payload under `data.{aggregate,top_companies,recent_submissions,popular_categories,curated_insights}`.

Two gaps worth knowing before building against it:

- **There is no `GET api/v1/home`.** The web landing's `HomeService::snapshot()` (metrics, featured jobs, top companies, top categories with counts, salary teasers, testimonials, articles) is Inertia-only. Beranda composes `jobs` + `companies` + `meta` instead, and metrics, per-category job counts and testimonials have **no API source at all**.
- `GET companies/{slug}/jobs` does not eager-load `skills`, so `JobResource.skills` is always `[]` there. `GET jobs` is fine — `JobBrowseFilter` loads them.

Response shapes to respect when adding models: `JobResource` nulls salary unless `is_salary_visible` and reports an anonymous posting's company as `Confidential` with no id or slug; `open_jobs_count` exists only on the companies *index*; `ApplicationResource.job` is `whenLoaded`; and `meta.missing_items` on `GET profile` is a list of `{key, label, href}` objects, not strings.
