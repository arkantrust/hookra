# Clean Architecture with BLoC

In this module we implement Clean Architecture combined with BLoC to build robust, maintainable Flutter apps. The pattern's fundamental rule: outer layers depend on inner layers, never the other way around. The domain knows nothing about the outside world.

## The three layers

![Clean Layers](layers.png)

The layers are read from the inside out. The closer to the center, the purer and more stable the layer.

- Domain (core) — Depends on nothing. Pure Dart only. `UseCase` and `AbstractRepository` live here.
- Application — Contains `BLoC`. Only knows the Domain.
- Infrastructure (outer) — Contains `View`, `RepositoryImpl`, and `DataSource`. This is the layer that touches the real world: HTTP, databases, Flutter UI.


## Request flow

When the user performs an action, data travels like this:

![Data Flow](flow.png)

The BLoC never calls `RepositoryImpl` directly. It only knows the abstraction. That is dependency inversion.

## Domain: the pure core

It is the heart of the application. Nothing from Flutter, HTTP, or external libraries is imported here. If the domain compiles with `dart run`, you're on the right track.

### AbstractRepository

Defines the contract the domain needs. It doesn't know how data is obtained, only what data it needs.

```dart
abstract class MusicRepository {
  Future<List<Track>> searchTracks(String query);
}
```

- It is an abstract class — it only declares methods, it does not implement them.
- The `UseCase` depends on this abstraction, never on `RepositoryImpl`.
- Allows swapping the data source (HTTP, mock, SQLite) without touching a single line of domain code.


### UseCase

Encapsulates a concrete business action. One `UseCase` = one responsibility.

```dart
class SearchTracksUseCase {
  final MusicRepository repository;

  SearchTracksUseCase(this.repository);

  Future<List<Track>> call(String query) {
    return repository.searchTracks(query);
  }
}
```

- The `call` method allows using the syntax `await useCase(query)` directly.
- Only imports domain entities. Zero dependencies on HTTP, BLoC, or Flutter.
- To test business logic, you only mock `MusicRepository` — there are no further dependencies.

## Data: the layer that touches the outside world

This is where domain contracts are implemented and connections to APIs, databases, or any external source are made.

### DataSource

Makes the raw HTTP call. It only knows how to make requests and return unprocessed JSON.

```dart
class DeezerDataSource {
  final http.Client client;

  DeezerDataSource(this.client);

  Future<List<Map<String, dynamic>>> fetchTracks(String query) async {
    final uri = Uri.parse('https://api.deezer.com/search?q=$query');
    final response = await client.get(uri);
    final json = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(json['data']);
  }
}
```

### RepositoryImpl

Implements `AbstractRepository`. Orchestrates calls to `DataSource` and converts JSON into domain entities.

```dart
class MusicRepositoryImpl implements MusicRepository {
  final DeezerDataSource dataSource;

  MusicRepositoryImpl(this.dataSource);

  @override
  Future<List<Track>> searchTracks(String query) async {
    final raw = await dataSource.fetchTracks(query);
    return raw.map((json) => Track.fromJson(json)).toList();
  }
}
```

- `implements MusicRepository` — this is where the connection between domain and infrastructure happens.
- Converts `Map<String, dynamic>` to `Track` entities. The `BLoC` never sees raw JSON.
- Could orchestrate multiple `DataSource` instances (network + cache) without the domain knowing.


## UI: BLoC and View

### BLoC

Receives events from the UI, invokes the `UseCase`, and emits states. It knows nothing about HTTP or how data is retrieved.

```dart
class MusicBloc extends Bloc<MusicEvent, MusicState> {
  final SearchTracksUseCase searchTracks;

  MusicBloc(this.searchTracks) : super(MusicInitial()) {
    on<SearchRequested>((event, emit) async {
      emit(MusicLoading());
      try {
        final tracks = await searchTracks(event.query);
        emit(MusicLoaded(tracks));
      } catch (e) {
        emit(MusicError(e.toString()));
      }
    });
  }
}
```

### View / Widget

Listens to BLoC states and renders the UI. Contains no business logic.

```dart
BlocBuilder<MusicBloc, MusicState>(
  builder: (context, state) {
    if (state is MusicLoading) return CircularProgressIndicator();
    if (state is MusicLoaded) return TrackListView(tracks: state.tracks);
    if (state is MusicError) return Text(state.message);
    return const SizedBox.shrink();
  },
)
```

## Summary: who knows whom

![Layer and flow diagram](diagram.png)

- `View` only talks to `BLoC` — nothing else.
- `BLoC` only talks to `UseCase` — never to `RepositoryImpl`.
- `UseCase` only knows `AbstractRepository` — it doesn't know whether data comes from HTTP or a database.
- `RepositoryImpl` fulfills the domain contract and invokes `DataSource`.
- The green dashed arrow indicates implementation: `RepositoryImpl` satisfies the interface defined by the domain.