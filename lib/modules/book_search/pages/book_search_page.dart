import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_route/auto_route.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../blocs/book_search_bloc.dart';
import '../blocs/book_search_event.dart';
import '../blocs/book_search_state.dart';
import '../entities/book.dart';
import '../enums/search_mode.dart';
import '../enums/view_mode.dart';
import '../../../core/services/search_history_service.dart';
import '../../../core/routing/app_router.dart';
import 'scanner_page.dart';
import '../utils/ocr_utils.dart';
import '../repositories/book_repository.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/lottie_empty_state.dart';
import '../../../core/services/error_handler_service.dart';

@RoutePage()
class BookSearchPage extends StatefulWidget {
  const BookSearchPage({super.key});

  @override
  State<BookSearchPage> createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<BookSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  SearchMode _currentSearchMode = SearchMode.text;
  ViewMode _viewMode = ViewMode.list;
  final SearchHistoryService _historyService = SearchHistoryService();
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final history = await _historyService.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query, BuildContext? searchContext) {
    if (query.trim().isEmpty) return;
    
    final ctx = searchContext ?? context;
    ctx.read<BookSearchBloc>().add(SearchBooksEvent(query));
    _historyService.addSearchQuery(query);
    _loadSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookSearchBloc(getIt<BookRepository>())
        ..add(const ClearSearchEvent()),
      child: Builder(
        builder: (blocContext) => AnnotatedRegion<SystemUiOverlayStyle>(
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
                  _buildHeader(blocContext),
                  _buildSearchModeSelector(blocContext),
                  _buildSearchBar(blocContext),
                  Expanded(
                    child: BlocBuilder<BookSearchBloc, BookSearchState>(
                      builder: (context, state) {
                        if (state is BookSearchInitial) {
                          return _buildInitialView();
                        } else if (state is BookSearchLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (state is BookSearchError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.message,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (state is BookSearchSuccess) {
                          if (state.books.isEmpty) {
                            return const LottieEmptyState(
                              title: 'No books found',
                              message: 'Try a different search term or scan an ISBN',
                              fallbackIcon: Icons.book_outlined,
                            );
                          }
                          return _buildBookList(state.books);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext blocContext) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Text(
            'Book Search',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _viewMode == ViewMode.list ? Icons.grid_view : Icons.view_list,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == ViewMode.list
                    ? ViewMode.grid
                    : ViewMode.list;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchModeSelector(BuildContext blocContext) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: SearchMode.values.map((mode) {
            final isSelected = _currentSearchMode == mode;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(mode.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _currentSearchMode = mode;
                    });
                    _handleSearchModeChange(mode, blocContext);
                  }
                },
                selectedColor: AppColors.primary,
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _handleSearchModeChange(SearchMode mode, BuildContext blocContext) async {
    if (mode == SearchMode.qrCode || mode == SearchMode.barcode) {
      // Get the bloc from the context that has the BlocProvider
      final bloc = blocContext.read<BookSearchBloc>();
      final result = await Navigator.of(blocContext).push(
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: bloc,
            child: ScannerPage(searchMode: mode),
          ),
        ),
      );
      if (result == true) {
        // Scanner completed, results handled in scanner
      }
    } else if (mode == SearchMode.ocr) {
      await _handleOCRScan(blocContext);
    }
  }

  Future<void> _handleOCRScan(BuildContext blocContext) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final imageFile = File(image.path);
      final extractedText = await OCRUtils.extractTextFromImage(imageFile);
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (extractedText.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No text found in image')),
        );
        return;
      }

      if (!mounted) return;
      final bloc = blocContext.read<BookSearchBloc>();
      
      // Try to extract ISBN first
      final isbn = OCRUtils.extractIsbn(extractedText);
      if (isbn != null) {
        bloc.add(SearchByIsbnEvent(isbn));
      } else {
        // Use extracted text as search query
        bloc.add(SearchBooksEvent(extractedText));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      final errorMessage = ErrorHandlerService.getUserFriendlyMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildSearchBar(BuildContext blocContext) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.dotInactive,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20,
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
                onSubmitted: (query) => _performSearch(query, blocContext),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.search,
                color: AppColors.primary,
              ),
              onPressed: () => _performSearch(_searchController.text, blocContext),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    if (_searchHistory.isEmpty) {
      return const LottieEmptyState(
        title: 'Start searching for books',
        message: 'Enter a book title, author, or scan an ISBN',
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
                _performSearch(query, null);
              },
            )),
      ],
    );
  }

  Widget _buildBookList(List<Book> books) {
    if (_viewMode == ViewMode.grid) {
      return _buildGridView(books);
    }
    return _buildListView(books);
  }

  Widget _buildListView(List<Book> books) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return _buildBookCard(books[index]);
      },
    );
  }

  Widget _buildGridView(List<Book> books) {
    return GridView.builder(
      padding: const EdgeInsets.all(24.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return _buildBookGridCard(books[index]);
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
          border: Border.all(color: AppColors.dotInactive),
        ),
        child: Row(
          children: [
            if (book.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: book.thumbnailUrl!,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 120,
                    color: AppColors.dotInactive,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 120,
                    color: AppColors.dotInactive,
                    child: const Icon(Icons.book),
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.dotInactive,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.book, size: 40),
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
                  const SizedBox(height: 8),
                  Text(
                    book.authorDisplay,
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (book.averageRating != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
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
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.dotInactive,
                borderRadius: BorderRadius.circular(12),
              ),
              child: book.thumbnailUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: book.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.book,
                          size: 40,
                        ),
                      ),
                    )
                  : const Center(child: Icon(Icons.book, size: 40)),
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
          const SizedBox(height: 4),
          Text(
            book.authorDisplay,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
