import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'support/memory_backends.dart';
import 'package:test/test.dart';

/// A use case that writes twice is only safe when the caller supplies a store
/// that can roll back. These tests pin both halves of that: with a unit of work
/// the partial write is undone, and without one it is not.
void main() {
  late MemoryDeviceTypeRepository skus;
  late MemorySkuComponentRepository components;
  late MemoryDeviceRepository devices;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  setUp(() async {
    skus = MemoryDeviceTypeRepository();
    components = MemorySkuComponentRepository();
    devices = MemoryDeviceRepository();
    await CreateDeviceType(skus)(
      DeviceType(meta: meta('rack'), manufacturerId: 'm', modelNumber: 'RACK'),
    ).run();
    // An edge whose child SKU is deliberately absent from the SKU store, so the
    // SKU delete fails *after* the edge delete has already succeeded.
    await CreateSkuComponent(components)(
      SkuComponent(
        meta: meta('edge'),
        parentDeviceTypeId: 'rack',
        childDeviceTypeId: 'card',
        quantity: 8,
      ),
    ).run();
  });

  Future<int> edgeCount() async => (await FetchSkuComponentsByDeviceType(
    components,
  )('rack').run()).getOrElse((_) => []).length;

  test('a unit of work rolls a failed SKU delete back', () async {
    final result = await DeleteDeviceType(
      deviceTypeRepository: skus,
      deviceRepository: devices,
      skuComponentRepository: components,
      unitOfWork: MemoryUnitOfWork([skus, components]),
    )('card').run();

    result.isLeft().should.beTrue();
    (await edgeCount()).should.be(1);
  });

  test('without a unit of work the assembly line is already gone', () async {
    final result = await DeleteDeviceType(
      deviceTypeRepository: skus,
      deviceRepository: devices,
      skuComponentRepository: components,
    )('card').run();

    result.isLeft().should.beTrue();
    // No transaction: the cascade committed before the failure. This is the
    // behaviour a store that cannot roll back gets, and why `unitOfWork` exists.
    (await edgeCount()).should.be(0);
  });

  test('a device delete takes its images and the device in one unit', () async {
    final images = MemoryImageRepository();
    await CreateDevice(devices)(
      Device(
        meta: meta('d1'),
        deviceTypeId: 'rack',
        locateId: null,
        name: 'Dev 1',
      ),
    ).run();
    await CreateImageRecord(images)(
      ImageRecord(
        id: 'img1',
        owner: ImageOwner.device,
        ownerId: 'd1',
        filename: 'one.jpg',
        storedPath: 'data:image/jpeg;base64,AAAA',
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
    ).run();

    final result = await DeleteDevice(
      deviceRepository: devices,
      imageRepository: images,
      unitOfWork: MemoryUnitOfWork([devices, images]),
    )('d1').run();

    result.isRight().should.beTrue();
    (await devices.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
    (await images.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
  });
}
