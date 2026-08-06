import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';

class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.source,
    required this.time,
    required this.tag,
    required this.paragraphs,
    this.related = const [],
  });

  final String title;
  final String source;
  final String time;
  final String tag;
  final List<String> paragraphs;

  /// Titles of related case studies shown as pills.
  final List<String> related;
}

class NewsArticleScreen extends StatefulWidget {
  const NewsArticleScreen({
    super.key,
    required this.article,
    this.onOpenRelatedCase,
  });

  final NewsArticle article;

  /// Called with the case title when a related-case pill is tapped.
  final ValueChanged<String>? onOpenRelatedCase;

  @override
  State<NewsArticleScreen> createState() => _NewsArticleScreenState();
}

class _NewsArticleScreenState extends State<NewsArticleScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.progressTrack,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              article.tag,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 16 / 11,
                                letterSpacing: -0.08,
                                color: AppColors.textGrey555,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            article.source,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 18 / 13,
                              letterSpacing: -0.08,
                              color: AppColors.textGrey555,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            article.time,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 30 / 22,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(height: 1, color: AppColors.divider),
                      const SizedBox(height: 20),
                      const _SectionCaption('ARTICLE SUMMARY'),
                      const SizedBox(height: 12),
                      for (int i = 0; i < article.paragraphs.length; i++) ...[
                        if (i > 0) const SizedBox(height: 14),
                        Text(
                          article.paragraphs[i],
                          style: const TextStyle(
                            fontSize: 14,
                            height: 22 / 14,
                            letterSpacing: -0.15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                      if (article.related.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const _SectionCaption('RELATED CASES'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final title in article.related)
                              Material(
                                color: AppColors.fillGrey,
                                borderRadius: BorderRadius.circular(100),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(100),
                                  onTap: widget.onOpenRelatedCase == null
                                      ? null
                                      : () => widget.onOpenRelatedCase!(title),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: AppColors.borderGrey,
                                      ),
                                    ),
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        height: 16 / 12,
                                        letterSpacing: -0.08,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildReadButton(),
                      const SizedBox(height: 12),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const CircleBackButton(),
          const Expanded(
            child: Text(
              'Legal News',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 24 / 17,
                letterSpacing: -0.34,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _saved = !_saved),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SvgPicture.asset(
                'assets/icons/ic_bookmark.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  _saved ? AppColors.textPrimary : AppColors.textGrey,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            // TODO: open the source article once article URLs are available.
            onTap: () {},
            child: const Center(
              child: Text(
                'Read Full Article',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.23,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => setState(() => _saved = !_saved),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_bookmark.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  AppColors.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _saved ? 'Saved' : 'Save Article',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.23,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.5,
        letterSpacing: 1.8,
        color: AppColors.textGrey,
      ),
    );
  }
}
