import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:sku_catalog_memory/sku_catalog_memory.dart';
import 'package:sku_catalog_usecases/sku_catalog_usecases.dart';
import 'package:test/test.dart';

/// A device is one article of a SKU at one place, and the rules that matter are
/// about *where* it is: names are unique per place, a copy is not fitted
/// anywhere, and a SKU that lives inside a host carries no place of its own.
void main() {
  late MemoryDeviceRepository devices;
  late MemoryDeviceTypeRepository skus;
  late MemoryTraitRepository traits;
  late MemoryImageRepository images;
  late MemoryLocateRepository locates;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  Device device(
    String id,
    String name, {
    String? locateId = 'rack-1',
    String typeId = 'free',
  }) => Device(
    meta: meta(id),
    deviceTypeId: typeId,
    locateId: locateId,
    name: name,
  );

  UpdateDevice updateDevice() => UpdateDevice(
    deviceRepository: devices,
    deviceTypeRepository: skus,
    traitRepository: traits,
    slotBoundTraitNames: const {'slotted'},
  );

  DuplicateDevice duplicator() => DuplicateDevice(
    deviceRepository: devices,
    deviceTypeRepository: skus,
    traitRepository: traits,
    slotBoundTraitNames: const {'slotted'},
  );

  setUp(() async {
    devices = MemoryDeviceRepository();
    skus = MemoryDeviceTypeRepository();
    traits = MemoryTraitRepository();
    images = MemoryImageRepository();
    locates = MemoryLocateRepository();

    // Two SKUs: one free-standing, one that lives inside a host.
    await CreateDeviceType(skus)(
      DeviceType(meta: meta('free'), manufacturerId: 'm', modelNumber: 'FREE'),
    ).run();
    await CreateTrait(traits)(
      Trait(meta: meta('slot'), name: 'Slotted', scope: const [TraitScope.sku]),
    ).run();
    await CreateDeviceType(skus)(
      DeviceType(
        meta: meta('slotted'),
        manufacturerId: 'm',
        modelNumber: 'SLOT',
        traitIds: const ['slot'],
      ),
    ).run();
    await CreateLocate(locates)(
      Locate(meta: meta('rack-1'), name: 'Rack 1'),
    ).run();
    await CreateLocate(locates)(
      Locate(meta: meta('rack-2'), name: 'Rack 2'),
    ).run();
  });

  test('a created device is fetched back and found by its place', () async {
    await CreateDevice(devices)(device('d1', 'Sensor 1')).run();

    (await FetchAllDevices(
      devices,
    )().run()).getOrElse((_) => fail('expected Right')).should.haveCount(1);

    final atRack = await FetchDevicesByLocate(devices)('rack-1').run();
    atRack
        .getOrElse((_) => fail('expected Right'))
        .single
        .name
        .should
        .be('Sensor 1');
    (await FetchDevicesByLocate(devices)(
      'rack-2',
    ).run()).getOrElse((_) => []).should.beEmpty();
  });

  test('a device knows whether it is placed', () {
    device('d1', 'Sensor 1').isPlaced.should.beTrue();
    device('d2', 'Loose', locateId: null).isPlaced.should.beFalse();
  });

  test(
    'a name clash at the same place is refused, and allowed elsewhere',
    () async {
      await CreateDevice(devices)(device('d1', 'Sensor 1')).run();
      await CreateDevice(devices)(device('d2', 'Other')).run();
      await CreateDevice(devices)(
        device('d3', 'Third', locateId: 'rack-2'),
      ).run();

      final clash = await updateDevice()(device('d2', 'sensor 1')).run();
      clash.isLeft().should.beTrue();
      clash
          .fold((f) => f, (_) => fail('expected Left'))
          .should
          .beAssignableTo<AlreadyExistsFailure>();

      // The same name at a different place is fine.
      final elsewhere = await updateDevice()(
        device('d3', 'Sensor 1', locateId: 'rack-2'),
      ).run();
      elsewhere.isRight().should.beTrue();
    },
  );

  test('a slot-bound SKU is never given a place of its own', () async {
    await CreateDevice(devices)(
      device('d1', 'Card 1', typeId: 'slotted'),
    ).run();

    final saved = await updateDevice()(
      device('d1', 'Card 1', typeId: 'slotted'),
    ).run();

    saved.getOrElse((_) => fail('expected Right')).locateId.should.beNull();
  });

  test(
    'a device whose SKU names no slot-bound trait keeps its place',
    () async {
      await CreateDevice(devices)(device('d1', 'Sensor 1')).run();

      final saved = await updateDevice()(device('d1', 'Sensor 1')).run();

      saved
          .getOrElse((_) => fail('expected Right'))
          .locateId
          .should
          .be('rack-1');
    },
  );

  test('a copy gets a unique name and the original keeps its place', () async {
    await CreateDevice(devices)(device('d1', 'Sensor 1')).run();

    final first = await duplicator()('d1').run();
    first
        .getOrElse((_) => fail('expected Right'))
        .name
        .should
        .be('Sensor 1 copy');

    final second = await duplicator()('d1').run();
    second
        .getOrElse((_) => fail('expected Right'))
        .name
        .should
        .be('Sensor 1 copy 2');
  });

  test('a copy of a slot-bound device is not fitted anywhere', () async {
    await CreateDevice(devices)(
      device('d1', 'Card 1', typeId: 'slotted'),
    ).run();

    final copy = await duplicator()('d1').run();

    copy.getOrElse((_) => fail('expected Right')).locateId.should.beNull();
  });

  test('deleting a device takes its images with it', () async {
    await CreateDevice(devices)(device('d1', 'Sensor 1')).run();
    await CreateImageRecord(images)(
      ImageRecord(
        id: 'img-d1',
        owner: ImageOwner.device,
        ownerId: 'd1',
        filename: 'd1.jpg',
        storedPath: 'data:image/jpeg;base64,AAAA',
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
    ).run();

    final result = await DeleteDevice(
      deviceRepository: devices,
      imageRepository: images,
    )('d1').run();

    result.isRight().should.beTrue();
    (await FetchAllDevices(
      devices,
    )().run()).getOrElse((_) => []).should.beEmpty();
    (await images.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
  });

  test(
    'deleting a device leaves images owned by something else alone',
    () async {
      await CreateDevice(devices)(device('d1', 'Sensor 1')).run();
      await CreateImageRecord(images)(
        ImageRecord(
          id: 'img-sku',
          owner: ImageOwner.sku,
          ownerId: 'd1',
          filename: 'sku.jpg',
          storedPath: 'data:image/jpeg;base64,AAAA',
          createdAt: '2024-01-01T00:00:00.000Z',
        ),
      ).run();

      await DeleteDevice(deviceRepository: devices, imageRepository: images)(
        'd1',
      ).run();

      (await images.fetchAll().run()).getOrElse((_) => []).should.haveCount(1);
    },
  );

  test('instance traits and values are carried on the device itself', () async {
    final one = device('d1', 'Sensor 1').copyWith(
      traitIds: const ['calibrated'],
      attributeValues: const {'calibrated_on': '2026-01-01'},
    );

    final saved = await CreateDevice(devices)(one).run();
    final back = saved.getOrElse((_) => fail('expected Right'));

    back.traitIds.should.be(['calibrated']);
    (back.attributeValues['calibrated_on'] as String).should.be('2026-01-01');
  });
}
