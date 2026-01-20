// models/pagination_meta.dart

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final int? from;
  final int? to;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    this.from,
    this.to,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: _parseInt(json['current_page']) ?? 1,
      lastPage: _parseInt(json['last_page']) ?? 1,
      total: _parseInt(json['total']) ?? 0,
      perPage: _parseInt(json['per_page']) ?? 20,
      from: _parseInt(json['from']),
      to: _parseInt(json['to']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'total': total,
      'per_page': perPage,
      'from': from,
      'to': to,
    };
  }

  int get totalPages => lastPage;
  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
  bool get isFirstPage => currentPage == 1;
  bool get isLastPage => currentPage == lastPage;

  String get range {
    if (from == null || to == null) return '';
    return '$from-$to sur $total';
  }

  PaginationMeta copyWith({
    int? currentPage,
    int? lastPage,
    int? total,
    int? perPage,
    int? from,
    int? to,
  }) {
    return PaginationMeta(
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      perPage: perPage ?? this.perPage,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }

  @override
  String toString() =>
      'PaginationMeta(page: $currentPage/$lastPage, total: $total, range: $range)';
}