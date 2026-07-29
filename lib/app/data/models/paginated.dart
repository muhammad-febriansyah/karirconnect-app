/// Envelope Laravel's `JsonResource::collection($paginator)` produces:
/// `{ data: [...], links: {...}, meta: { current_page, last_page, total, ... } }`.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  static Paginated<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {};

    return Paginated<T>(
      items: (json['data'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => parse(row.cast<String, dynamic>()))
          .toList(),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? 0,
    );
  }

  static Paginated<T> empty<T>() =>
      Paginated<T>(items: const [], currentPage: 1, lastPage: 1, total: 0);
}
