import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unshelf_buyer/views/category_view.dart';

class CategoryIconsRow extends StatefulWidget {
  @override
  _CategoryIconsRowState createState() => _CategoryIconsRowState();
}

class _CategoryIconsRowState extends State<CategoryIconsRow> {
  int _pressedIndex = -1;

  final List<CategoryItem> categories = [
    CategoryItem('Grocery', 'assets/images/category_grocery.svg', 'Grocery'),
    CategoryItem('Fruits', 'assets/images/category_fruits.svg', 'Fruits'),
    CategoryItem('Veggies', 'assets/images/category_vegetables.svg', 'Vegetables'),
    CategoryItem('Baked', 'assets/images/category_baked.svg', 'Baked Goods'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.asMap().entries.map((entry) {
            int index = entry.key;
            CategoryItem category = entry.value;

            return GestureDetector(
              onTapDown: (_) => setState(() => _pressedIndex = index),
              onTapUp: (_) => setState(() => _pressedIndex = -1),
              onTapCancel: () => setState(() => _pressedIndex = -1),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryProductsPage(category: category),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _pressedIndex == index ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                child: Row(
                  children: [
                    SvgPicture.asset(category.iconPath, height: 18.0, width: 18.0),
                    const SizedBox(width: 6.0),
                    Text(
                      category.name,
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _pressedIndex == index ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class CategoryItem {
  final String name;
  final String iconPath;
  final String categoryKey;

  CategoryItem(this.name, this.iconPath, this.categoryKey);

  String get categoryName => name;
}
