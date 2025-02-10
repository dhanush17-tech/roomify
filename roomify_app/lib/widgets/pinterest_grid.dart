import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/marketplace/item_details.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:roomify_app/views/property/property_details.dart';

class PinterestGrid extends StatelessWidget {
  final List<Listing> items;
  final ScrollPhysics? physics;
  final bool showDeleteIcon;
  final Function(Listing)? onTapDelete;
  final double latitude;
  final double longitude;
  PinterestGrid(this.items, this.latitude, this.longitude,
      {Key? key, this.physics, this.showDeleteIcon = false, this.onTapDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return AnimatedListItem(
            key: ValueKey(items[index].id), // Add key for proper animation
            index: index,
            child: FeaturedItemCard(
              item: items[index],
              showDeleteIcon: showDeleteIcon,
              onTapDelete: onTapDelete != null
                  ? (Listing item) => onTapDelete!(item)
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        items[index].type == ListingType.Property
                            ? PropertyDetailsScreen(
                                items[index],
                                latitude,
                                longitude,
                              )
                            : ItemDetailsScreen(
                                items[index],
                                latitude,
                                longitude,
                              ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedListItem({
    Key? key,
    required this.child,
    required this.index,
  }) : super(key: key);

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) {
        _controller.forward();
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.reset();
      setState(() {
        _isVisible = false;
      });
      Future.delayed(Duration(milliseconds: 50 * widget.index), () {
        if (mounted) {
          _controller.forward();
          setState(() {
            _isVisible = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      opacity: _isVisible ? 1.0 : 0.0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

class FeaturedItemCard extends StatelessWidget {
  final VoidCallback? onTap;
  final Listing item;
  final bool showDeleteIcon;
  final Function(Listing item)? onTapDelete;

  const FeaturedItemCard({
    Key? key,
    required this.item,
    this.onTap,
    this.onTapDelete,
    this.showDeleteIcon = false,
  }) : super(key: key);

  int _getMinPrice(List<FloorPlan> floorPlans) {
    return floorPlans
        .map((fp) => fp.price.toInt())
        .reduce((a, b) => a < b ? a : b);
  }

  int _getMaxPrice(List<FloorPlan> floorPlans) {
    return floorPlans
        .map((fp) => fp.price.toInt())
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Hero(
                      tag: 'property-image-${item.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          width: double.infinity,
                          imageUrl: item.type == ListingType.Property
                              ? item.property?.imageUrls?.isNotEmpty == true
                                  ? item.property!.imageUrls!.first
                                  : 'https://via.placeholder.com/180'
                              : item.marketplaceItem!.imageUrls?.isNotEmpty ==
                                      true
                                  ? item.marketplaceItem!.imageUrls!.first
                                  : 'https://via.placeholder.com/180',
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              buildPropertyImageShimmer(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        ),
                      ),
                    ),
                    if (item.hasActiveReport)
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: ReportBadge(reports: item.reports),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Hero(
                  tag: 'property-title-${item.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      item.title,
                      style: AppTextStyles.subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.location,
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Hero(
                      tag: 'property-price-${item.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (item.type == ListingType.Property) &&
                                    (item.user?.isProfessional == true) &&
                                    item.property?.floorPlans?.isNotEmpty ==
                                        true
                                ? '\$${_getMinPrice(item.property!.floorPlans!)}-\$${_getMaxPrice(item.property!.floorPlans!)}'
                              : '\$${item.price}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDeleteIcon)
          Positioned(
            top: 13,
            right: 15,
            child: GestureDetector(
              onTap: () => onTapDelete?.call(item),
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete, color: Colors.red, size: 20),
              ),
            ),
          ),
      ],
    );
  }
}

class ReportBadge extends StatefulWidget {
  final List<Report> reports;

  const ReportBadge({
    Key? key,
    required this.reports,
  }) : super(key: key);

  @override
  State<ReportBadge> createState() => _ReportBadgeState();
}

class _ReportBadgeState extends State<ReportBadge>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
          if (_isExpanded) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: _isExpanded ? MediaQuery.of(context).size.width * 0.8 : 40,
        constraints: BoxConstraints(
          minHeight: 40,
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: _isExpanded ? _buildExpandedView() : _buildCollapsedView(),
      ),
    );
  }

  Widget _buildCollapsedView() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.warning_amber_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildExpandedView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  '${widget.reports.length} Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ...widget.reports
                .map((report) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.reason,
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            report.status
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
