import 'package:flutter/material.dart';

/// Widget interactivo para seleccionar una calificación de 1 a 5 estrellas
class StarRatingInput extends StatefulWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  int _hoveredRating = 0;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Colors.amber;
    final inactiveColor = widget.inactiveColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isActive = starNumber <= (_hoveredRating > 0 ? _hoveredRating : widget.rating);

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredRating = starNumber),
          onExit: (_) => setState(() => _hoveredRating = 0),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => widget.onRatingChanged(starNumber),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isActive ? Icons.star_rounded : Icons.star_border_rounded,
                  size: widget.size,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
