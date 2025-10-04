import 'package:flutter/material.dart';

enum PlaceCategory {
  touristAttraction('Atracción turística', Icons.place, Colors.blue),
  restaurant('Restaurante', Icons.restaurant, Colors.orange),
  hotel('Hotel', Icons.hotel, Colors.green),
  gasStation('Gasolinera', Icons.local_gas_station, Colors.red),
  hospital('Hospital', Icons.local_hospital, Colors.pink),
  bank('Banco', Icons.account_balance, Colors.purple);

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