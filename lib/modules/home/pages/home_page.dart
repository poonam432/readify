import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../entities/category.dart';
import '../../book_search/entities/book.dart';
import '../../book_search/repositories/book_repository.dart';
import '../../book_search/enums/view_mode.dart';
import '../../../core/di/injection.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/search_history_service.dart';
import '../../../core/services/book_cache_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/widgets/lottie_empty_state.dart';
import '../../../core/services/error_handler_service.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<Book> _books = [];
  List<Book> _allBooks = []; // Store all fetched books for filtering
  bool _isLoading = false;
  bool _hasSearched = false;
  ViewMode _viewMode = ViewMode.list;
  final BookRepository _bookRepository = getIt<BookRepository>();
  final SearchHistoryService _historyService = SearchHistoryService();
  final BookCacheService _cacheService = getIt<BookCacheService>();
  final UserProfileService _profileService = getIt<UserProfileService>();
  List<String> _searchHistory = [];
  String _userName = 'User';
  
  // For debouncing search
  Timer? _searchTimer;
  
  // Filter state
  Set<String> _selectedCategories = {};
  double _minPrice = 0.0;
  double _maxPrice = 500.0;
  double _currentMinPrice = 0.0;
  double _currentMaxPrice = 500.0;

  @override
  void initState() {
    super.initState();
    // Set status bar to white for home page
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    _loadSearchHistory();
    _loadBooks();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final profile = await _profileService.getProfile();
    if (mounted) {
      // Always update to ensure name is in sync
      if (_userName != profile.name) {
        setState(() {
          _userName = profile.name;
        });
      }
    }
  }

  Future<void> _loadSearchHistory() async {
    final history = await _historyService.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _hasSearched = false;
    });
    try {
      // Fetch books using the "author" query as default
      final books = await _bookRepository.searchBooks('author');
      // Cache books for analytics
      await _cacheService.cacheBooks(books);
      setState(() {
        _allBooks = books;
        _books = _applyFilters(books);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    final trimmedQuery = query.trim();
    
    if (trimmedQuery.isEmpty) {
      // If search is empty, reload default books
      _loadBooks();
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // Search by title and author parameters
      // The Google Books API will search in both title and author fields
      // Using intitle: and inauthor: parameters for better results
      final books = await _bookRepository.searchBooks(trimmedQuery);
      // Cache books for analytics
      await _cacheService.cacheBooks(books);
      await _historyService.addSearchQuery(trimmedQuery);
      await _loadSearchHistory();
      
      if (mounted) {
        setState(() {
          _allBooks = books;
          _books = _applyFilters(books);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final errorMessage = ErrorHandlerService.getUserFriendlyMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always reload user name when tab becomes visible to sync changes
    _loadUserName();
    // Update status bar when tab becomes visible
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  final List<Category> _categories = const [
    Category(
      id: '1',
      name: 'Language',
      backgroundColor: Color(0xFFE3F2FD),
      imagePath: 'assets/ads (1).svg',
    ),
    Category(
      id: '2',
      name: 'Painting',
      backgroundColor: Color(0xFFF3E5F5),
      imagePath: 'assets/ads.svg',
    ),
  ];

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reload name when build is called (happens when tab becomes visible)
    // Use a post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserName();
      }
    });
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              height: MediaQuery.of(context).padding.top,
              color: Colors.white,
            ),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSearchBar(),
                  _buildCategories(),
                  _buildCourseSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0,right: 24.0,bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $_userName',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ), Text(
                'Let’s start learning',
                style: GoogleFonts.poppins(
                  color: Colors.black,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        height: 48,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.dotInactive,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: SvgPicture.asset(
                  'assets/search.svg',
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search books by title, author...',
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {}); // Rebuild to show/hide clear button
                    
                    // Cancel previous timer
                    _searchTimer?.cancel();
                    
                    // If search is empty, reload default books
                    if (value.trim().isEmpty) {
                      _loadBooks();
                      return;
                    }
                    
                    // Debounce search - wait 500ms after user stops typing
                    _searchTimer = Timer(const Duration(milliseconds: 500), () {
                      if (_searchController.text.trim() == value.trim()) {
                        _performSearch(value);
                      }
                    });
                  },
                  onSubmitted: (value) {
                    // Cancel timer and search immediately
                    _searchTimer?.cancel();
                    if (value.trim().isNotEmpty) {
                      _performSearch(value);
                    }
                  },
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    _loadBooks();
                  },
                ),
              // IconButton(
              //   icon: Icon(
              //     Icons.search,
              //     color: AppColors.primary,
              //     size: 20,
              //   ),
              //   onPressed: () {
              //     final query = _searchController.text.trim();
              //     if (query.isNotEmpty) {
              //       _performSearch(query);
              //     }
              //   },
              // ),
              GestureDetector(
                onTap: () {
                  _showFilterModal();
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SvgPicture.asset(
                    'assets/filter.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0,bottom: 36.0),
      child: Row(
        children: _categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: SizedBox(
              width: 172.0,
              height: 120,
              child: SvgPicture.asset(
                category.imagePath,
                width: 260.0,
                height: 108,
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCourseSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choice your books',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _viewMode = ViewMode.list;
                        });
                      },
                      child: Opacity(
                        opacity: _viewMode == ViewMode.list ? 1.0 : 0.5,
                        child: SvgPicture.asset(
                          'assets/Group 143.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _viewMode = ViewMode.grid;
                        });
                      },
                      child: SvgPicture.asset(
                        'assets/dashboard-3--app-application-dashboard-home-layout-vertical.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          _viewMode == ViewMode.grid
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: ['All', 'Popular', 'New'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: EdgeInsets.only(right: filter != 'New' ? 12 : 0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
                      foregroundColor: isSelected ? Colors.white : AppColors.textSecondary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      filter,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Show active filters indicator
          if (_selectedCategories.isNotEmpty || (_minPrice > 0 || _maxPrice < 500))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                children: [
                  if (_selectedCategories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: _selectedCategories.map((category) {
                        return Chip(
                          label: Text(category),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          labelStyle: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                          deleteIcon: Icon(Icons.close, size: 18, color: AppColors.primary),
                          onDeleted: () {
                            setState(() {
                              _selectedCategories.remove(category);
                              _books = _applyFilters(_allBooks);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  if (_minPrice > 0 || _maxPrice < 500)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Chip(
                        label: Text('₹${_minPrice.toInt()} - ₹${_maxPrice.toInt()}'),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                        deleteIcon: Icon(Icons.close, size: 18, color: AppColors.primary),
                        onDeleted: () {
                          setState(() {
                            _minPrice = 0.0;
                            _maxPrice = 500.0;
                            _currentMinPrice = 0.0;
                            _currentMaxPrice = 500.0;
                            _books = _applyFilters(_allBooks);
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched && _books.isEmpty && _selectedCategories.isEmpty && (_minPrice == 0.0 && _maxPrice == 500.0)
                    ? _buildInitialView()
                    : _books.isEmpty
                        ? LottieEmptyState(
                            title: 'No data found',
                            message: _hasSearched || _selectedCategories.isNotEmpty || (_minPrice > 0 || _maxPrice < 500)
                                ? 'Try adjusting your search or filters'
                                : 'Start searching for books!',
                            fallbackIcon: Icons.search_off,
                          )
                        : _viewMode == ViewMode.list
                            ? _buildBookList()
                            : _buildBookGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialView() {
    if (_searchHistory.isEmpty) {
      return const LottieEmptyState(
        title: 'Start exploring books!',
        message: 'Search for your favorite books, authors, or topics',
        fallbackIcon: Icons.search,
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () async {
                await _historyService.clearHistory();
                _loadSearchHistory();
              },
              child: Text(
                'Clear',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._searchHistory.map((query) => ListTile(
              title: Text(
                query,
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              leading: Icon(
                Icons.history,
                color: AppColors.textSecondary,
              ),
              onTap: () {
                _searchController.text = query;
                _performSearch(query);
              },
            )),
      ],
    );
  }

  Widget _buildBookList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        return _buildBookCard(_books[index]);
      },
    );
  }

  Widget _buildBookGrid() {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 24.0,top: 24.0,bottom: 24.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.6,
      ),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        return _buildBookGridCard(_books[index]);
      },
    );
  }

  Widget _buildBookCard(Book book) {
    return GestureDetector(
      onTap: () {
        context.router.push(BookDetailRoute(book: book));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.dotInactive,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: book.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: book.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.book,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : const Icon(
                        Icons.book,
                        color: AppColors.textSecondary,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.authors.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            book.authorDisplay,
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (book.averageRating != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          book.averageRating!.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookGridCard(Book book) {
    return GestureDetector(
      onTap: () {
        context.router.push(BookDetailRoute(book: book));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.dotInactive,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: book.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: book.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.book,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : const Icon(
                        Icons.book,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (book.authors.isNotEmpty)
            Text(
              book.authorDisplay,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (book.averageRating != null)
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  book.averageRating!.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<Book> _applyFilters(List<Book> books) {
    List<Book> filtered = books;
    
    // Apply category filter
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((book) {
        if (book.categories == null || book.categories!.isEmpty) {
          return false;
        }
        return book.categories!.any((category) {
          final categoryLower = category.toLowerCase();
          return _selectedCategories.any((selected) {
            return categoryLower.contains(selected.toLowerCase()) ||
                   selected.toLowerCase().contains(categoryLower);
          });
        });
      }).toList();
    }
    
    // Apply price filter (if price data is available in book)
    // Note: Google Books API doesn't provide price, so this is a placeholder
    // filtered = filtered.where((book) {
    //   // Price filtering would go here if price data was available
    //   return true;
    // }).toList();
    
    return filtered;
  }

  void _showFilterModal() {
    // Reset filter state to current values
    _currentMinPrice = _minPrice;
    _currentMaxPrice = _maxPrice;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return _buildFilterModal(setModalState);
        },
      ),
    );
  }

  Widget _buildFilterModal(StateSetter setModalState) {
    final categories = ['Fiction', 'Sci-fi', 'Biography', 'Music', 'Non-fiction', 'Mathematics'];
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'Search Filter',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 48), // Balance the close button
            ],
          ),
          const SizedBox(height: 24),
          // Categories Section
          Text(
            'Categories',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: categories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return GestureDetector(
                onTap: () {
                  setModalState(() {
                    if (isSelected) {
                      _selectedCategories.remove(category);
                    } else {
                      _selectedCategories.add(category);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.dotInactive,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          // Price Section
          Text(
            'Price',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          RangeSlider(
            values: RangeValues(_currentMinPrice, _currentMaxPrice),
            min: 0,
            max: 500,
            divisions: 50,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.dotInactive,
            labels: RangeLabels(
              '₹${_currentMinPrice.toInt()}',
              '₹${_currentMaxPrice.toInt()}',
            ),
            onChangeStart: (RangeValues values) {
              // Optional: handle when user starts dragging
            },
            onChangeEnd: (RangeValues values) {
              // Optional: handle when user stops dragging
            },
            onChanged: (RangeValues values) {
              setModalState(() {
                _currentMinPrice = values.start;
                _currentMaxPrice = values.end;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${_currentMinPrice.toInt()}',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${_currentMaxPrice.toInt()}',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setModalState(() {
                      _selectedCategories.clear();
                      _currentMinPrice = 0.0;
                      _currentMaxPrice = 500.0;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _minPrice = _currentMinPrice;
                      _maxPrice = _currentMaxPrice;
                      _books = _applyFilters(_allBooks);
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Apply Filter',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

}

