class HorizontalCreatePlan {
  const HorizontalCreatePlan._({
    required this.isBlocked,
    required this.blockingMessage,
    required this.identityVersion,
    required this.syncable,
  });

  factory HorizontalCreatePlan.blocked(String message) {
    return HorizontalCreatePlan._(
      isBlocked: true,
      blockingMessage: message,
      identityVersion: 2,
      syncable: false,
    );
  }

  factory HorizontalCreatePlan.ready({required bool syncable}) {
    return HorizontalCreatePlan._(
      isBlocked: false,
      blockingMessage: null,
      identityVersion: 2,
      syncable: syncable,
    );
  }

  final bool isBlocked;
  final String? blockingMessage;
  final int identityVersion;
  final bool syncable;
}

HorizontalCreatePlan buildHorizontalCreatePlan({
  required int? equipoId,
  required int? seccionId,
  required int? jefeGuardiaId,
  required int? operadorId,
}) {
  if (equipoId == null) {
    return HorizontalCreatePlan.blocked(
      'Cannot save without a cached equipment ID.',
    );
  }

  if (seccionId == null) {
    return HorizontalCreatePlan.blocked(
      'Cannot save without a cached section ID.',
    );
  }

  if (jefeGuardiaId == null) {
    return HorizontalCreatePlan.blocked(
      'Cannot save without a cached guard leader ID.',
    );
  }

  return HorizontalCreatePlan.ready(syncable: operadorId != null);
}
