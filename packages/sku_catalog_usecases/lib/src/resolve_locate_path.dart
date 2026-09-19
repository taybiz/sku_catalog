import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Resolves the display path for a locate by walking up the parent chain.
class ResolveLocatePath {
  /// Creates a [ResolveLocatePath] use case.
  const ResolveLocatePath(this._locateRepository);

  final ILocateRepository _locateRepository;

  /// Returns the locate path (e.g., "Building A / Floor 2 / Room 201").
  TaskEither<DomainFailure, String> call(String locateId) => _locateRepository
      .fetchById(locateId)
      .andThen(() => _locateRepository.fetchAll())
      .map((allLocates) {
        final locateMap = {for (final l in allLocates) l.meta.id: l};
        final path = <String>[];
        var currentId = locateId;
        final visited = <String>{};

        while (currentId.isNotEmpty && visited.add(currentId)) {
          final current = locateMap[currentId];
          if (current == null) break;
          path.add(current.name);
          currentId = current.parentLocateId ?? '';
        }

        return path.reversed.join(' / ');
      });
}
