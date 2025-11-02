import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routing/app_router.dart';

@RoutePage()
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final Map<int, GlobalKey> _tabKeys = {
    0: GlobalKey(),
    1: GlobalKey(),
    3: GlobalKey(),
    4: GlobalKey(),
  };

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: const [
        HomeRoute(),
        AnalyticsRoute(),
        BookSearchRoute(),
        ContactsRoute(),
        ProfileRoute(),
      ],
      bottomNavigationBuilder: (_, tabsRouter) {
        return _buildBottomNavigationBar(tabsRouter);
      },
    );
  }

  Widget _buildBottomNavigationBar(TabsRouter tabsRouter) {
    final selectedIndex = tabsRouter.activeIndex;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Get actual tab position using GlobalKey
            double? getTabCenterPosition(int index) {
              final key = _tabKeys[index];
              if (key?.currentContext == null) return null;
              
              final RenderBox? box = key!.currentContext!.findRenderObject() as RenderBox?;
              if (box == null) return null;
              
              // Get position relative to the Stack (LayoutBuilder)
              final position = box.localToGlobal(Offset.zero);
              final parentBox = context.findRenderObject() as RenderBox?;
              if (parentBox == null) return null;
              
              final parentPosition = parentBox.localToGlobal(Offset.zero);
              final relativeX = position.dx - parentPosition.dx;
              
              // Return center position
              return relativeX + (box.size.width / 2) - 13; // Half of indicator width (26/2)
            }
            
            final screenWidth = constraints.maxWidth;
            final indicatorLeft = selectedIndex != 2
                ? (getTabCenterPosition(selectedIndex) ?? 
                   ((screenWidth / 5) * (selectedIndex + 0.5) - 13))
                : 0.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBottomNavItem(
                          tabsRouter,
                          0,
                          'Home',
                          'assets/home.svg',
                          _tabKeys[0]!,
                        ),
                        _buildBottomNavItem(
                          tabsRouter,
                          1,
                          'Analytics',
                          'assets/course.svg',
                          _tabKeys[1]!,
                        ),
                        _buildBottomNavItemPlaceholder('Search', 2),
                        _buildBottomNavItem(
                          tabsRouter,
                          3,
                          'Contacts',
                          'assets/contacts.svg',
                          _tabKeys[3]!,
                        ),
                        _buildBottomNavItem(
                          tabsRouter,
                          4,
                          'Profile',
                          'assets/account.svg',
                          _tabKeys[4]!,
                        ),
                      ],
                    ),
                  ),
                ),
                // Search icon that extends outside - always visible
                Positioned(
                  bottom: 32,
                  left: (screenWidth / 5 * 2) + (screenWidth / 5 / 2) - 40,
                  child: GestureDetector(
                    onTap: () => tabsRouter.setActiveIndex(2),
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.transparent,
                          width: 4.5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: selectedIndex == 2
                                ? AppColors.primary
                                : AppColors.dotInactive,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/search.svg',
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                selectedIndex == 2
                                    ? Colors.white
                                    : AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Top indicator line for non-search tabs
                if (selectedIndex != 2)
                  Positioned(
                    top: 0,
                    left: indicatorLeft,
                    child: Container(
                      width: 26,
                      height: 2,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    TabsRouter tabsRouter,
    int index,
    String label,
    String iconPath,
    GlobalKey key,
  ) {
    final isSelected = tabsRouter.activeIndex == index;
    const inactiveColor = AppColors.dotInactive;

    return GestureDetector(
      onTap: () => tabsRouter.setActiveIndex(index),
      child: Column(
        key: key,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 44,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      isSelected ? AppColors.primary : inactiveColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? AppColors.primary : inactiveColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItemPlaceholder(String label, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: 44,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
            ),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

