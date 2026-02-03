import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart'; // Import to access currentRouteProvider

// 🧭 NAVIGATION HISTORY PROVIDER
final navigationHistoryProvider =
    StateNotifierProvider<NavigationHistoryNotifier, List<String>>((ref) {
      return NavigationHistoryNotifier(ref);
    });

class NavigationHistoryNotifier extends StateNotifier<List<String>> {
  final Ref ref;

  NavigationHistoryNotifier(this.ref) : super([]) {
    // Listen to currentRouteProvider and add each new route to history
    ref.listen<String>(currentRouteProvider, (previous, next) {
      if (next.isNotEmpty) {
        state = [...state, next]; // Append the new route, allowing duplicates
      }
    });
  }

  // Optional: Method to clear history if needed (though it resets on app close)
  void clearHistory() {
    state = [];
  }

  // Optional: Method to get the previous route (for custom back navigation if needed)
  String? getPreviousRoute() {
    if (state.length > 1) {
      return state[state.length - 2];
    }
    return null;
  }
}
