import 'package:flutter/material.dart';

enum PlaceCategory {
  // Acciones Deportivas y Recreativas
  swimming('Natación', Icons.pool, Color(0xFF03A9F4)),
  hiking('Caminata', Icons.hiking, Color(0xFF795548)),
  trekking('Senderismo', Icons.terrain, Color(0xFF8D6E63)),
  running('Correr', Icons.directions_run, Color(0xFF2196F3)),
  cycling('Ciclismo', Icons.directions_bike, Color(0xFF00BCD4)),
  football('Fútbol', Icons.sports_soccer, Color(0xFF4CAF50)),
  basketball('Baloncesto', Icons.sports_basketball, Color(0xFFFF9800)),
  volleyball('Voleibol', Icons.sports_volleyball, Color(0xFFE91E63)),
  gym('Entrenamiento en Gimnasio', Icons.fitness_center, Color(0xFFE53935)),
  yoga('Yoga y Meditación', Icons.self_improvement, Color(0xFF673AB7)),
  sports('Deportes Varios', Icons.sports, Color(0xFF9C27B0)),
  tourism('Turismo y Paseos', Icons.attractions, Color(0xFFFF5722));

  const PlaceCategory(this.displayName, this.icon, this.color);
  final String displayName;
  final IconData icon;
  final Color color;
}

class CategoryBottomSheet extends StatelessWidget {
  final Function(PlaceCategory) onCategorySelected;

  const CategoryBottomSheet({
    super.key,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Selecciona una categoría',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: PlaceCategory.values.length,
              itemBuilder: (context, index) {
                final category = PlaceCategory.values[index];
                return _buildCategoryTile(context, category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, PlaceCategory category) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            category.icon,
            color: category.color,
            size: 24,
          ),
        ),
        title: Text(
          category.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onTap: () {
          Navigator.pop(context);
          // Add a small delay to ensure UI is updated
          Future.delayed(const Duration(milliseconds: 100), () {
            onCategorySelected(category);
          });
        },
      ),
    );
  }

  static void show(BuildContext context, Function(PlaceCategory) onCategorySelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: CategoryBottomSheet(onCategorySelected: onCategorySelected),
      ),
    );
  }
}