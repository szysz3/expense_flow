class Category {
  Category._();

  static const String groceries = 'groceries';
  static const String alcoholicBeverages = 'alcoholic_beverages';
  static const String personalCare = 'personal_care';
  static const String household = 'household';
  static const String clothing = 'clothing';
  static const String entertainment = 'entertainment';
  static const String transportation = 'transportation';
  static const String pet = 'pet';
  static const String other = 'other';
  static const String standingOrders = 'standing_orders';

  static const List<String> all = [
    groceries,
    alcoholicBeverages,
    personalCare,
    household,
    clothing,
    entertainment,
    transportation,
    pet,
    other,
    standingOrders,
  ];

  static const String defaultCategory = groceries;

  static bool isValid(String? categoryId) {
    if (categoryId == null) return false;
    return all.contains(categoryId);
  }

  static String ensureValid(String? categoryId) {
    if (isValid(categoryId)) return categoryId!;
    return other;
  }
}
