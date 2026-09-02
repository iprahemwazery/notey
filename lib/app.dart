import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/services/app_lock_controller.dart';
import 'core/services/auth_scope.dart';
import 'core/services/biometric_service.dart';
import 'core/services/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/notes/domain/repositories/note_repository.dart';
import 'features/notes/data/repositories_impl/note_repository.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/notes/presentation/cubits/home_cubit.dart';
import 'features/shell/presentation/screens/main_shell.dart';
import 'features/auth/presentation/screens/lock_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/onboarding/data/repositories_impl/onboarding_repository.dart';
import 'features/onboarding/domain/repositories/onboarding_repository.dart';
import 'features/onboarding/domain/usecases/load_onboarding_status.dart';
import 'features/auth/presentation/screens/lock_setup_screen.dart';

class NoteyApp extends StatelessWidget {
  const NoteyApp({
    super.key,
    this.repository,
    this.biometricService,
    this.lockController,
    this.secureStorage,
    this.onboardingRepository,
  });

  /// Injectable for tests.
  final NoteRepository? repository;

  /// Injectable for tests.
  final BiometricService? biometricService;

  /// Injectable for tests.
  final AppLockController? lockController;

  /// Injectable for tests.
  final FlutterSecureStorage? secureStorage;

  /// Injectable for tests; defaults to the SharedPreferences-backed repo.
  final OnboardingRepository? onboardingRepository;

  @override
  Widget build(BuildContext context) {
    // Shared app-lock instances so the auth gate (deletion confirmation) uses
    // exactly the same controller/service as the boot flow.
    final lockController =
        this.lockController ?? AppLockController(secureStorage: secureStorage);
    final biometricService =
        this.biometricService ?? DeviceBiometricService();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleController.instance.locale,
          builder: (context, locale, _) {
            return ScreenUtilInit(
              designSize: const Size(360, 690),
              minTextAdapt: true,
              splitScreenMode: true,
              builder: (context, child) {
                return GetMaterialApp(
                  title: 'Notey',
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      const <LocalizationsDelegate<dynamic>>[
                        ...AppLocalizations.localizationsDelegates,
                      ],
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: mode,
                  navigatorKey: noteyNavigatorKey,
                  // Frame-1 viewport guard: if the engine reports a zero-size
                  // view before metrics bind (splash → first layout), inject
                  // the physical size so no subtree ever lays out at 0×0.
                  builder: (context, child) {
                    final mq = MediaQuery.of(context);
                    Widget? frame;
                    if (mq.size.isEmpty) {
                      final view = View.of(context);
                      if (view.physicalSize.isEmpty) {
                        frame = child ?? const SizedBox.shrink();
                      } else {
                        frame = MediaQuery(
                          data: mq.copyWith(
                            size: view.physicalSize / view.devicePixelRatio,
                          ),
                          child: child ?? const SizedBox.shrink(),
                        );
                      }
                    } else {
                      frame = child;
                    }
                    // Wrap above the Navigator so every pushed route (trash,
                    // vault detail, …) can look up the auth gate via AuthScope.
                    return AuthScope(
                      lockController: lockController,
                      biometricService: biometricService,
                      child: frame!,
                    );
                  },
                  home: BootstrapScreen(
                    repository: repository,
                    biometricService: biometricService,
                    lockController: lockController,
                    onboardingRepository: onboardingRepository,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Global navigator so notification taps can push the note viewer from
/// anywhere.
final GlobalKey<NavigatorState> noteyNavigatorKey = GlobalKey<NavigatorState>();

/// Decides the entry route based on the app-lock choice.
class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({
    super.key,
    required this.repository,
    required this.biometricService,
    required this.lockController,
    this.onboardingRepository,
  });

  final NoteRepository? repository;
  final BiometricService biometricService;
  final AppLockController lockController;
  final OnboardingRepository? onboardingRepository;

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  late final OnboardingRepository _onboarding =
      widget.onboardingRepository ?? OnboardingRepositoryImpl();

  /// Only shows onboarding when prefs PROVE it wasn't completed; defaults to
  /// opening the app instantly (no splash waiting on disk reads).
  bool? _showOnboarding;
  bool _startupFallback = false;
  Timer? _startupTimer;

  @override
  void initState() {
    super.initState();
    widget.lockController.addListener(_onControllerChanged);
    if (!widget.lockController.initialized) {
      if (kDebugMode) debugPrint('[boot] requesting lock-controller init…');
      widget.lockController.init();
    }
    _startupTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (widget.lockController.initialized) return;
      if (kDebugMode) {
        debugPrint(
          '[boot] startup fallback reached after 3s — app will not stay on white loading screen',
        );
      }
      setState(() => _startupFallback = true);
    });
    LoadOnboardingStatus(_onboarding)().then((bool done) {
      if (mounted && !done) setState(() => _showOnboarding = true);
    });
  }

  void _completeOnboarding() {
    if (mounted) setState(() => _showOnboarding = null);
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    widget.lockController.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (kDebugMode) {
      debugPrint(
        '[boot] lock controller ready: '
        'initialized=${widget.lockController.initialized} '
        'method=${widget.lockController.method}',
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.lockController;

    if (!controller.initialized) {
      if (_startupFallback) {
        final method = controller.method ?? AppLockMethod.none;
        if (method == AppLockMethod.none) {
          return BlocProvider<HomeCubit>(
            create: (_) => HomeCubit(widget.repository ?? NoteRepositoryImpl()),
            child: MainShell(
              repository: widget.repository ?? NoteRepositoryImpl(),
              lockController: controller,
              biometricService: widget.biometricService,
            ),
          );
        }
        return _LifecycleRelocker(
          controller: controller,
          biometricService: widget.biometricService,
          child: LockSetupScreen(
            controller: controller,
            biometricService: widget.biometricService,
            repository: widget.repository,
          ),
        );
      }
      return _LifecycleRelocker(
        controller: controller,
        biometricService: widget.biometricService,
        child: const _LoadingScreen(),
      );
    }

    final method = controller.method;
    if (method == null) {
      if (_showOnboarding == true) {
        return OnboardingScreen(
          onDone: _completeOnboarding,
          repository: _onboarding,
        );
      }
      return _LifecycleRelocker(
        controller: controller,
        biometricService: widget.biometricService,
        child: LockSetupScreen(
          controller: controller,
          biometricService: widget.biometricService,
          repository: widget.repository,
        ),
      );
    }
    if (method == AppLockMethod.none) {
      return BlocProvider<HomeCubit>(
        create: (_) => HomeCubit(widget.repository ?? NoteRepositoryImpl()),
        child: MainShell(
          repository: widget.repository ?? NoteRepositoryImpl(),
          lockController: controller,
          biometricService: widget.biometricService,
        ),
      );
    }
    return _LifecycleRelocker(
      controller: controller,
      biometricService: widget.biometricService,
      child: LockScreen(
        controller: controller,
        biometricService: widget.biometricService,
        repository: widget.repository,
      ),
    );
  }
}

/// Re-locks the app whenever it comes back from the background while an
/// app-lock method is enabled. Sits above the navigator so it survives
/// every route change.
class _LifecycleRelocker extends StatefulWidget {
  const _LifecycleRelocker({
    required this.controller,
    required this.biometricService,
    required this.child,
  });

  final AppLockController controller;
  final BiometricService biometricService;
  final Widget child;

  @override
  State<_LifecycleRelocker> createState() => _LifecycleRelockerState();
}

class AppLifecycleRelockerPolicy {
  const AppLifecycleRelockerPolicy();

  static const Duration relockThreshold = Duration(seconds: 2);

  static bool shouldRelock(Duration elapsed) {
    return elapsed >= relockThreshold;
  }
}

class _LifecycleRelockerState extends State<_LifecycleRelocker>
    with WidgetsBindingObserver {
  bool _leftApp = false;
  bool _lockRouteOpen = false;
  DateTime? _backgroundedAt;

  static bool shouldRelock(Duration elapsed) {
    return AppLifecycleRelockerPolicy.shouldRelock(elapsed);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _leftApp = true;
        _backgroundedAt ??= DateTime.now();
      case AppLifecycleState.inactive:
        _leftApp = true;
        _backgroundedAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        if (_leftApp) {
          final elapsed = _backgroundedAt == null
              ? Duration.zero
              : DateTime.now().difference(_backgroundedAt!);
          _leftApp = false;
          _backgroundedAt = null;
          if (shouldRelock(elapsed)) {
            _maybeShowLock();
          }
        }
    }
  }

  void _maybeShowLock() {
    final method = widget.controller.method;
    if (!_lockRouteOpen &&
        widget.controller.initialized &&
        method != null &&
        method != AppLockMethod.none) {
      _lockRouteOpen = true;
      noteyNavigatorKey.currentState
          ?.push(
            MaterialPageRoute<bool>(
              fullscreenDialog: true,
              builder: (_) => LockScreen(
                controller: widget.controller,
                biometricService: widget.biometricService,
                onUnlocked: () {
                  final navCtx = noteyNavigatorKey.currentContext;
                  if (navCtx != null) Navigator.of(navCtx).pop();
                },
              ),
            ),
          )
          .whenComplete(() => _lockRouteOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Minimal, logo-free loading frame shown only for the instant before the
/// lock method is read from prefs. No branding, nothing to get stuck on.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Center(
        child: SizedBox(
          width: 180,
          height: 180,
          child: Image.asset(
            'asset/Gemini_Generated_Image_jw1w8cjw1w8cjw1w.jpeg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
