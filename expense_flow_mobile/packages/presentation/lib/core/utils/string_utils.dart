class StringUtils {
  static String formatCategoryName(String category) {
    final parts = category.split('.');
    final categoryName = parts.last;

    return categoryName
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
