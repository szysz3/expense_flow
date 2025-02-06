abstract class NavigationEvent {
  const NavigationEvent();
}

class NavigateToIndex extends NavigationEvent {
  final int index;
  const NavigateToIndex(this.index);
}
