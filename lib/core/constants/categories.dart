import 'package:flutter/material.dart';

class ItemCategory {
  final String id;
  final String name;
  final IconData icon;
  final String exampleHints;

  const ItemCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.exampleHints,
  });
}

class CategoryConstants {
  static const List<ItemCategory> allCategories = [
    ItemCategory(
      id: 'id_cards',
      name: 'ID Cards & Badges',
      icon: Icons.badge_outlined,
      exampleHints: 'VIT Student ID, Library Card, Lab Passes',
    ),
    ItemCategory(
      id: 'electronics',
      name: 'Electronics & Gadgets',
      icon: Icons.devices_outlined,
      exampleHints: 'Smartphones, Smartwatches, Powerbanks, Calculators',
    ),
    ItemCategory(
      id: 'audio',
      name: 'Earphones & Audio',
      icon: Icons.headphones_outlined,
      exampleHints: 'AirPods, Buds case, Over-ear headphones',
    ),
    ItemCategory(
      id: 'keys',
      name: 'Keys & Lanyards',
      icon: Icons.key_outlined,
      exampleHints: 'Hostel room keys, Bike keys, Keychains',
    ),
    ItemCategory(
      id: 'wallets',
      name: 'Wallets & Pouches',
      icon: Icons.account_balance_wallet_outlined,
      exampleHints: 'Wallets, Purses, Card holders, Money clips',
    ),
    ItemCategory(
      id: 'bags',
      name: 'Backpacks & Bags',
      icon: Icons.backpack_outlined,
      exampleHints: 'College bags, Gym bags, Laptop sleeves',
    ),
    ItemCategory(
      id: 'books_notes',
      name: 'Books & Stationery',
      icon: Icons.menu_book_outlined,
      exampleHints: 'Textbooks, Class notebooks, Scientific calculators, Pencil cases',
    ),
    ItemCategory(
      id: 'clothing',
      name: 'Clothing & Wearables',
      icon: Icons.checkroom_outlined,
      exampleHints: 'Jackets, Caps, Scarves, Watches, Eyeglasses',
    ),
    ItemCategory(
      id: 'bottles',
      name: 'Bottles & Umbrellas',
      icon: Icons.water_drop_outlined,
      exampleHints: 'Insulated flasks, Water bottles, Umbrellas',
    ),
    ItemCategory(
      id: 'other',
      name: 'Other Items',
      icon: Icons.category_outlined,
      exampleHints: 'Miscellaneous campus items',
    ),
  ];

  static ItemCategory findById(String id) {
    return allCategories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => allCategories.last,
    );
  }
}
