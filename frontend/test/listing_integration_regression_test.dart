import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_mark/data/owner_listings_store.dart';
import 'package:rent_mark/models/owner_listing.dart';
import 'package:rent_mark/services/item_api_service.dart';

OwnerListing listing(String id, {List<String> photos = const []}) =>
    OwnerListing.fromJson({
      'id': id,
      'owner_id': 'owner',
      'owner_name': 'Owner',
      'name': 'Camera',
      'description': 'Camera for community events.',
      'category': 'electronics',
      'condition': 'Good',
      'price_per_day': 100,
      'availability': 'available',
      'community': 'Davao',
      'image_urls': photos,
      'image_paths': <String>[],
      'moderation_status': 'active',
    });

class FakeApi extends ItemApiService {
  final ownerRequests = <Completer<List<OwnerListing>>>[];
  final publicRequest = Completer<List<OwnerListing>>();
  final saveRequest = Completer<OwnerListing>();
  final cleaned = <String>[];
  int uploads = 0;
  int? failUpload;
  bool failSave = false;
  bool failCleanup = false;

  @override
  Future<List<OwnerListing>> listOwner(String token) {
    final request = Completer<List<OwnerListing>>();
    ownerRequests.add(request);
    return request.future;
  }

  @override
  Future<List<OwnerListing>> listPublic(String token) => publicRequest.future;

  @override
  Future<UploadedItemImage> uploadImage(String token, String path) async {
    uploads++;
    if (uploads == failUpload) throw StateError('upload failed');
    return UploadedItemImage(
      path: 'owner/$uploads.jpg',
      url: 'https://example.com/$uploads.jpg',
    );
  }

  @override
  Future<OwnerListing> create(
    String token,
    OwnerListing item,
    List<String> paths,
  ) {
    if (failSave) return Future.error(StateError('save failed'));
    return saveRequest.future;
  }

  @override
  Future<OwnerListing> update(
    String token,
    OwnerListing item,
    List<String> paths,
  ) => create(token, item, paths);

  @override
  Future<void> cleanupImages(String token, List<String> paths) async {
    cleaned.addAll(paths);
    if (failCleanup) throw StateError('cleanup failed');
  }
}

class PagedApi extends ItemApiService {
  final int count;
  final offsets = <int>[];
  PagedApi(this.count);

  @override
  Future<List<OwnerListing>> listPublicPage(
    String token, {
    required int limit,
    required int offset,
  }) async {
    offsets.add(offset);
    final remaining = count - offset;
    return List.generate(
      remaining.clamp(0, limit),
      (i) => listing('item-${offset + i}'),
    );
  }
}

void main() {
  test(
    'owner response arriving after logout cannot restore private items',
    () async {
      final api = FakeApi();
      final store = OwnerListingsStore.forTesting(api);
      final loading = store.loadOwner('token', ownerId: 'A');
      store.resetSession();
      api.ownerRequests.single.complete([listing('private-A')]);
      await loading;
      expect(store.items.map((item) => item.id), isNot(contains('private-A')));
      expect(store.isLoading, isFalse);
    },
  );

  test('old owner responses cannot replace the new owner list', () async {
    final api = FakeApi();
    final store = OwnerListingsStore.forTesting(api);
    final first = store.loadOwner('A', ownerId: 'A');
    final second = store.loadOwner('B', ownerId: 'B');
    api.ownerRequests[1].complete([listing('private-B')]);
    await second;
    api.ownerRequests[0].complete([listing('private-A')]);
    await first;
    expect(store.items.map((item) => item.id), ['private-B']);
  });

  test(
    'old load failures do not change the new session error or loading state',
    () async {
      final api = FakeApi();
      final store = OwnerListingsStore.forTesting(api);
      final first = store.loadOwner('A', ownerId: 'A');
      final second = store.loadOwner('B', ownerId: 'B');
      api.ownerRequests[0].completeError(StateError('old failure'));
      await first;
      expect(store.error, isNull);
      expect(store.isLoading, isTrue);
      api.ownerRequests[1].complete([]);
      await second;
    },
  );

  test('public responses arriving after logout are ignored', () async {
    final api = FakeApi();
    final store = OwnerListingsStore.forTesting(api);
    final loading = store.loadPublic('A');
    store.resetSession();
    api.publicRequest.complete([listing('old-catalog')]);
    await loading;
    expect(
      store.discoveryItems.map((item) => item.id),
      isNot(contains('old-catalog')),
    );
  });

  test(
    'completed save after logout does not populate the next session',
    () async {
      final api = FakeApi();
      final store = OwnerListingsStore.forTesting(api);
      final saving = store.saveRemote(listing('owner-local-new'), 'A');
      store.resetSession();
      api.saveRequest.complete(listing('saved-A'));
      await saving;
      expect(store.items.map((item) => item.id), isNot(contains('saved-A')));
    },
  );

  test(
    'partial upload failure cleans earlier uploads and leaves draft retryable',
    () async {
      final api = FakeApi()..failUpload = 2;
      final store = OwnerListingsStore.forTesting(api);
      final draft = listing('owner-local-new', photos: ['one.jpg', 'two.jpg']);
      await expectLater(store.saveRemote(draft, 'A'), throwsStateError);
      expect(api.cleaned, ['owner/1.jpg']);
      expect(draft.galleryUrls, ['one.jpg', 'two.jpg']);
      expect(draft.storagePaths, isEmpty);
    },
  );

  for (final id in ['owner-local-new', 'existing']) {
    test('failed save of $id cleans only newly uploaded photos', () async {
      final api = FakeApi()..failSave = true;
      final store = OwnerListingsStore.forTesting(api);
      final draft = listing(
        id,
        photos: ['https://example.com/old.jpg', 'new.jpg'],
      );
      draft.storagePaths = ['owner/old.jpg'];
      await expectLater(store.saveRemote(draft, 'A'), throwsStateError);
      expect(api.cleaned, ['owner/1.jpg']);
      expect(draft.storagePaths, ['owner/old.jpg']);
      expect(draft.galleryUrls.last, 'new.jpg');
    });
  }

  test('cleanup failure does not hide the original save error', () async {
    final api = FakeApi()
      ..failSave = true
      ..failCleanup = true;
    final store = OwnerListingsStore.forTesting(api);
    await expectLater(
      store.saveRemote(listing('owner-local-new', photos: ['new.jpg']), 'A'),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', 'save failed'),
      ),
    );
  });

  for (final count in [0, 50, 123]) {
    test(
      'discovery loads all $count records including pages beyond 50',
      () async {
        final api = PagedApi(count);
        final result = await api.listPublic('A');
        expect(result.length, count);
        expect(
          api.offsets,
          count == 0
              ? [0]
              : count == 50
              ? [0, 50]
              : [0, 50, 100],
        );
        if (count > 0) expect(result.last.id, 'item-${count - 1}');
      },
    );
  }
}
