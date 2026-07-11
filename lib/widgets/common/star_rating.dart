import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double starSize;
  final Color color;
  final bool showRating;
  final int reviewCount;
  final bool allowEditing;
  final ValueChanged<double>? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.starSize = 20,
    this.color = Colors.amber,
    this.showRating = false,
    this.reviewCount = 0,
    this.allowEditing = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (allowEditing) _buildEditableStars(),
        if (!allowEditing) _buildStaticStars(),
        if (showRating) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: starSize * 0.7,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          if (reviewCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: TextStyle(
                fontSize: starSize * 0.6,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildStaticStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          _getStarIcon(index),
          size: starSize,
          color: color,
        );
      }),
    );
  }

  Widget _buildEditableStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: onRatingChanged != null
              ? () => onRatingChanged!(index + 1.0)
              : null,
          child: Icon(
            _getStarIcon(index),
            size: starSize,
            color: color,
          ),
        );
      }),
    );
  }

  IconData _getStarIcon(int index) {
    if (index < rating.floor()) {
      return Icons.star;
    } else if (index < rating.ceil()) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }
}