const Object _noQueryValue = Object();

class AllNotificationsQuery {
  const AllNotificationsQuery({
    this.page = 1,
    this.isFinancialTransaction,
    this.searchText,
  }) : assert(page > 0);

  final int page;
  final bool? isFinancialTransaction;
  final String? searchText;

  String? get normalizedSearchText {
    final normalized = searchText?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  AllNotificationsQuery copyWith({
    int? page,
    Object? isFinancialTransaction = _noQueryValue,
    Object? searchText = _noQueryValue,
  }) {
    return AllNotificationsQuery(
      page: page ?? this.page,
      isFinancialTransaction: identical(isFinancialTransaction, _noQueryValue)
          ? this.isFinancialTransaction
          : isFinancialTransaction as bool?,
      searchText: identical(searchText, _noQueryValue)
          ? this.searchText
          : searchText as String?,
    );
  }
}
