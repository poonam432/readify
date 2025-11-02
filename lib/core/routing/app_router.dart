import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../modules/home/pages/home_page.dart';
import '../../modules/analytics/pages/analytics_page.dart';
import '../../modules/book_search/pages/book_search_page.dart';
import '../../modules/book_search/pages/book_detail_page.dart';
import '../../modules/book_search/entities/book.dart';
import '../../modules/contacts/pages/contacts_page.dart';
import '../../modules/profile/pages/profile_page.dart';
import '../../modules/onboarding/pages/onboarding_page.dart';
import '../../modules/auth/pages/sign_up_page.dart';
import '../../modules/auth/pages/login_page.dart';
import '../../modules/auth/pages/verified_page.dart';
import '../../modules/main/pages/main_page.dart';
import '../../modules/search/pages/search_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: OnboardingRoute.page, initial: true),
    AutoRoute(page: SignUpRoute.page),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: VerifiedRoute.page),
    AutoRoute(page: BookDetailRoute.page),
    AutoRoute(
      page: MainRoute.page,
      children: [
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(page: AnalyticsRoute.page),
        AutoRoute(page: BookSearchRoute.page),
        AutoRoute(page: ContactsRoute.page),
        AutoRoute(page: ProfileRoute.page),
      ],
    ),
  ];
}

