import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_route/auto_route.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/google_books_service.dart';
import '../../../core/di/injection.dart';
import '../../../core/routing/app_router.dart';
import '../entities/book.dart';

@RoutePage()
class BookDetailPage extends StatefulWidget {
  final Book book;
  final String? heroTag;

  const BookDetailPage({
    super.key,
    required this.book,
    this.heroTag,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _aiSummary;
  List<String> _recommendations = [];
  List<Book> _authorBooks = [];
  bool _isLoadingSummary = false;
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadAuthorBooks();
    _loadAIContent();
  }

  Future<void> _loadAIContent() async {
    final geminiService = getIt<GeminiService>();
    
    setState(() {
      _isLoadingSummary = true;
    });
    
    final summary = await geminiService.generateBookSummary(
      title: widget.book.title,
      description: widget.book.description,
      author: widget.book.authorDisplay,
      categories: widget.book.categories,
    );
    
    setState(() {
      _aiSummary = summary;
      _isLoadingSummary = false;
    });

    setState(() {
      _isLoadingRecommendations = true;
    });
    
    final recommendations = await geminiService.generateRecommendations(
      title: widget.book.title,
      author: widget.book.authorDisplay,
      categories: widget.book.categories,
    );
    
    setState(() {
      _recommendations = recommendations;
      _isLoadingRecommendations = false;
    });
  }

  Future<void> _loadAuthorBooks() async {
    if (widget.book.authors.isEmpty) return;
    
    final googleBooksService = getIt<GoogleBooksService>();
    final results = await googleBooksService.searchByAuthor(widget.book.authors[0]);
    
    if (mounted) {
      setState(() {
        _authorBooks = results
            .map((json) => Book.fromJson(json))
            .where((book) => book.id != widget.book.id)
            .take(10)
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBookHeader(),
                  _buildBookInfo(),
                  _buildDescription(),
                  _buildAISummary(),
                  _buildRecommendations(),
                  _buildAuthorBooks(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: widget.book.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: widget.book.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.dotInactive,
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.dotInactive,
                  child: const Icon(Icons.book, size: 60),
                ),
              )
            : Container(
                color: AppColors.dotInactive,
                child: const Icon(Icons.book, size: 60),
              ),
      ),
    );
  }

  Widget _buildBookHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.book.title,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (widget.book.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.book.subtitle!,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'By ${widget.book.authorDisplay}',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          if (widget.book.averageRating != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < widget.book.averageRating!.round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${widget.book.averageRating!.toStringAsFixed(1)} (${widget.book.ratingsCount ?? 0} ratings)',
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
    );
  }

  Widget _buildBookInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.dotInactive.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (widget.book.publisher != null)
              _buildInfoRow('Publisher', widget.book.publisher!),
            if (widget.book.publishedDate != null)
              _buildInfoRow('Published', widget.book.publishedDate!),
            if (widget.book.pageCount != null)
              _buildInfoRow('Pages', widget.book.pageCount.toString()),
            if (widget.book.language != null)
              _buildInfoRow('Language', widget.book.language!.toUpperCase()),
            if (widget.book.isbn13 != null)
              _buildInfoRow('ISBN-13', widget.book.isbn13!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (widget.book.description == null || widget.book.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.book.description!,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISummary() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Summary',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingSummary)
            const Center(child: CircularProgressIndicator())
          else if (_aiSummary != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _aiSummary!,
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_recommendations.isEmpty && !_isLoadingRecommendations) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Similar Books',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingRecommendations)
            const Center(child: CircularProgressIndicator())
          else
            ..._recommendations.map((title) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.book,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildAuthorBooks() {
    if (_authorBooks.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'More by ${widget.book.authorDisplay}',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: _authorBooks.length,
            itemBuilder: (context, index) {
              return _buildAuthorBookCard(_authorBooks[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorBookCard(Book book) {
    return GestureDetector(
      onTap: () {
        context.router.push(BookDetailRoute(book: book));
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

