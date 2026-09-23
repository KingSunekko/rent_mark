import 'package:flutter/material.dart';

/// "About this item" section — a short readable paragraph, no card
/// chrome, just generous line height for legibility.
class ItemDescription extends StatelessWidget {
  final String description;

  const ItemDescription({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About this item', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
