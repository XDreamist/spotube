import 'package:catcher/catcher.dart';
import 'package:collection/collection.dart';
import 'package:fl_query/fl_query.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/hooks/use_spotify_infinite_query.dart';
import 'package:spotube/hooks/use_spotify_query.dart';

class AlbumQueries {
  Query<Iterable<AlbumSimple>, dynamic> useOfMineQuery(WidgetRef ref) {
    return useSpotifyQuery<Iterable<AlbumSimple>, dynamic>(
      "current-user-albums",
      (spotify) {
        return spotify.me.savedAlbums().all();
      },
      ref: ref,
    );
  }

  Query<List<TrackSimple>, dynamic> useTracksOfQuery(
    WidgetRef ref,
    String albumId,
  ) {
    return useSpotifyQuery<List<TrackSimple>, dynamic>(
      "album-tracks/$albumId",
      (spotify) {
        return spotify.albums
            .getTracks(albumId)
            .all()
            .then((value) => value.toList());
      },
      ref: ref,
    );
  }

  Query<bool, dynamic> useIsSavedForMeQuery(
    WidgetRef ref,
    String album,
  ) {
    return useSpotifyQuery<bool, dynamic>(
      "is-saved-for-me/$album",
      (spotify) {
        return spotify.me.isSavedAlbums([album]).then((value) => value.first);
      },
      ref: ref,
    );
  }

  InfiniteQuery<Page<AlbumSimple>, dynamic, int> useNewReleasesQuery(
      WidgetRef ref) {
    return useSpotifyInfiniteQuery<Page<AlbumSimple>, dynamic, int>(
      "new-releases",
      (pageParam, spotify) async {
        try {
          final albums = await Pages(
            spotify,
            'v1/browse/new-releases',
            (json) => AlbumSimple.fromJson(json),
            'albums',
            (json) => AlbumSimple.fromJson(json),
          ).getPage(5, pageParam);
          return albums;
        } catch (e, stack) {
          Catcher.reportCheckedError(e, stack);
          rethrow;
        }
      },
      ref: ref,
      initialPage: 0,
      nextPage: (lastParam, pages) {
        final lastPage = pages.elementAtOrNull(lastParam);
        if (lastPage == null ||
            lastPage.isLast ||
            (lastPage.items ?? []).length < 5) return null;

        return lastPage.nextOffset;
      },
    );
  }
}
