import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'item_image.dart';

/// Large swipeable image gallery for the top of Item Details. Falls back
/// to a single polished [ItemImage] (with its own icon fallback) when
/// only one photo — or none — is available, so the layout never looks
/// broken for thin mock data.
class ItemImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final IconData fallbackIcon;
  final double height;

  const ItemImageGallery({
    super.key,
    required this.imageUrls,
    required this.fallbackIcon,
    this.height = 320,
  });

  @override
  State<ItemImageGallery> createState() => _ItemImageGalleryState();
}

class _ItemImageGalleryState extends State<ItemImageGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.xl),
      ),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            if (images.isEmpty)
              ItemImage(
                imageUrl: null,
                icon: widget.fallbackIcon,
                height: widget.height,
                width: double.infinity,
              )
            else
              PageView.builder(
                controller: _controller,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _FullScreenGallery(
                        images: images,
                        fallbackIcon: widget.fallbackIcon,
                        initialIndex: i,
                      ),
                    ),
                  ),
                  child: ItemImage(
                    imageUrl: images[i],
                    icon: widget.fallbackIcon,
                    height: widget.height,
                    width: double.infinity,
                  ),
                ),
              ),
            if (images.isNotEmpty)
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${_index + 1} / ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            if (images.length > 1)
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (i) {
                    final selected = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: selected ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final IconData fallbackIcon;
  final int initialIndex;

  const _FullScreenGallery({
    required this.images,
    required this.fallbackIcon,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController controller;
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    controller = PageController(initialPage: index);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: widget.images.length,
            onPageChanged: (value) => setState(() => index = value),
            itemBuilder: (_, imageIndex) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: ItemImage(
                  imageUrl: widget.images[imageIndex],
                  icon: widget.fallbackIcon,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: IconButton.filledTonal(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  '${index + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
