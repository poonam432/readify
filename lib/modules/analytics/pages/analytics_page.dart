import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/search_analytics_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/routing/app_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

@RoutePage()
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool _isInitialized = false;
  final AnalyticsService _analyticsService = getIt<AnalyticsService>();
  final WebSocketService _webSocketService = getIt<WebSocketService>();
  final SearchAnalyticsService _searchAnalyticsService = getIt<SearchAnalyticsService>();
  final UserProfileService _profileService = getIt<UserProfileService>();
  
  List<GenreData> _genreData = [];
  List<PublishingTrendData> _publishingTrend = [];
  List<TrendingBook> _trendingBooks = [];
  Map<String, dynamic> _searchAnalytics = {};
  bool _isLoadingAnalytics = true;
  StreamSubscription<List<TrendingBook>>? _trendingSubscription;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    // Set status bar to primary color immediately
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    
    // Delay initialization to ensure fl_chart classes are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _loadUserName();
        await _loadAnalyticsData();
        _setupWebSocket();
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  Future<void> _loadUserName() async {
    final profile = await _profileService.getProfile();
    if (mounted) {
      // Always update to ensure name is in sync
      setState(() {
        _userName = profile.name;
      });
    }
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoadingAnalytics = true;
    });

    try {
      final genreData = await _analyticsService.getGenreDistribution();
      final publishingTrend = await _analyticsService.getPublishingTrend();
      final searchAnalytics = await _searchAnalyticsService.getSearchAnalytics();
      
      if (mounted) {
        setState(() {
          _genreData = genreData;
          _publishingTrend = publishingTrend;
          _searchAnalytics = searchAnalytics;
          _isLoadingAnalytics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAnalytics = false;
        });
        // Silently handle analytics errors - don't show to user
        // Analytics are non-critical features
      }
    }
  }

  void _setupWebSocket() {
    _webSocketService.connect();
    _trendingSubscription = _webSocketService.trendingBooksStream.listen((books) {
      if (mounted) {
        setState(() {
          _trendingBooks = books;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update status bar when tab becomes visible
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    // Reload user name when tab becomes visible to sync changes
    _loadUserName();
    // Refresh analytics when tab becomes visible
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _trendingSubscription?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 0,
                  color: AppColors.primary,
                ),
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 190), // Space for overlapping card (card height ~180px + 40px spacing)
                        _buildPublishingTrendCard(),
                        const SizedBox(height: 30),
                        if (_trendingBooks.isNotEmpty) ...[
                          _buildTrendingBooksCard(),
                          const SizedBox(height: 30),
                        ],
                        if (_searchAnalytics.isNotEmpty) ...[
                          _buildSearchAnalyticsCard(),
                          const SizedBox(height: 30),
                        ],
                        _buildMeetupCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Positioned card that overlaps the header
            Positioned(
              top: 183 - 30, // Start 30px above the end of header (183px height - 30px overlap)
              left: 24,
              right: 24,
              child: _buildGenreDistributionCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 183,
      color: AppColors.primary,
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: MediaQuery.of(context).padding.top,
        bottom: 24.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $_userName',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ), Text(
                'Let’s start learning',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              context.router.push(const ProfileRoute());
            },
            child: SizedBox(
              width: 36,
              height: 50,
              child: SvgPicture.asset(
                'assets/Mask Group.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreDistributionCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFCEECFE),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 120,
              // padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoadingAnalytics || !_isInitialized
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPieChart(),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Genre distribution',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ..._genreData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  // Use fixed colors in order: Fiction (dark), Non-fiction (grey), Romance (green)
                  Color color;
                  if (index == 0) {
                    color = AppColors.fictionColor; // Dark color for first item
                  } else if (index == 1) {
                    color = AppColors.nonFictionColor; // Grey color for second item
                  } else {
                    color = AppColors.romanceColor; // Green color for third item
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLegendItem(data.genre, color),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    if (_genreData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: _genreData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          // Use fixed colors in order: Fiction (dark), Non-fiction (grey), Romance (green)
          Color color;
          if (index == 0) {
            color = AppColors.fictionColor; // Dark color for first item
          } else if (index == 1) {
            color = AppColors.nonFictionColor; // Grey color for second item
          } else {
            color = AppColors.romanceColor; // Green color for third item
          }
          return PieChartSectionData(
            value: data.percentage,
            color: color,
            radius: 20,
            title: '',
            showTitle: false,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,borderRadius: BorderRadius.circular(4.0)
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPublishingTrendCard() {
    return Container(
      width: 358.0,
      height: 240,
      // margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20), // Space for outer border
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey,
          width: 0.6,
        ),// Outer border radius
      ),
      child: Container(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Inner border radius
          border: Border.all(
            color: Colors.grey,
            width: 0.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
            'Book Publishing Trend',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTrendLegend('Books Published', const Color(0xFF67E9F1)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,drawHorizontalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.dotInactive,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _publishingTrend.length) {
                          // Show last 2 digits of year
                          final year = _publishingTrend[index].year;
                          final shortYear = year.length > 2 ? year.substring(year.length - 2) : year;
                          return Text(
                            shortYear,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final count = value.toInt();
                        if (count >= 0) {
                          return Text(
                            count.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                  border: Border.all(
                    color: AppColors.dotInactive,
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: _publishingTrend.isNotEmpty ? (_publishingTrend.length - 1).toDouble() : 4,
                minY: 0,
                maxY: _publishingTrend.isNotEmpty 
                    ? (_publishingTrend.map((e) => e.count).reduce((a, b) => a > b ? a : b) * 1.2).clamp(1, 10).toDouble()
                    : 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: _publishingTrend.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF67E9F1),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTrendLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingBooksCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Trending Books',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._trendingBooks.take(3).map((book) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.dotInactive,
                  ),
                  child: book.thumbnailUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: book.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Icon(
                              Icons.book,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.book,
                          color: AppColors.textSecondary,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🔥',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSearchAnalyticsCard() {
    final totalSearches = _searchAnalytics['totalSearches'] as int? ?? 0;
    final uniqueSearches = _searchAnalytics['uniqueSearches'] as int? ?? 0;
    final topCategories = _searchAnalytics['topCategories'] as List<dynamic>? ?? [];
    final averageRating = _searchAnalytics['averageRating'] as double? ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Search Insights',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total Searches', totalSearches.toString()),
              ),
              Expanded(
                child: _buildStatItem('Unique Searches', uniqueSearches.toString()),
              ),
              Expanded(
                child: _buildStatItem('Avg Rating', averageRating.toStringAsFixed(1)),
              ),
            ],
          ),
          if (topCategories.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Top Categories',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topCategories.take(5).map((category) {
                return Chip(
                  label: Text(
                    category.toString(),
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  labelStyle: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMeetupCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.meetupCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meetup',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.meetupTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Off-line exchange of learning experiences',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.meetupTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            height: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/illustration.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}