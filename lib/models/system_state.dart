enum SystemState {
  allSafe,
  mistouchWindow,
  activeDispatch,
  resolved;

  String get label {
    switch (this) {
      case SystemState.allSafe:
        return 'ALL SAFE · NO ALERTS';
      case SystemState.mistouchWindow:
        return 'MISTOUCH COUNTDOWN ACTIVE';
      case SystemState.activeDispatch:
        return '🚨 ACTIVE EMERGENCY DISPATCH';
      case SystemState.resolved:
        return 'INCIDENT RESOLVED';
    }
  }
}
