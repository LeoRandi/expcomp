import 'dart:math';

/// Highest speed first; shuffle each tied group afresh every round.
List<T> orderBySpeed<T>(
  Iterable<T> actors,
  int Function(T) speed,
  Random random,
) {
  final groups = <int, List<T>>{};
  for (final actor in actors) {
    groups.putIfAbsent(speed(actor), () => []).add(actor);
  }
  final speeds = groups.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final value in speeds) ...(groups[value]!..shuffle(random))];
}
