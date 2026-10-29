import 'dart:convert';

import 'package:databee/models/delivery_address.dart';
import 'package:databee/models/order_info.dart';
import 'package:databee/services/app_state.dart';
import 'package:databee/services/store_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'demo shopping data persists and follows the delivery lifecycle',
    () async {
      final repository = StoreRepository(demoMode: true);
      final product = StoreRepository.demoProducts.first;
      final address = DeliveryAddress(
        id: 'address-1',
        label: 'Home',
        fullName: 'Demo Customer',
        phone: '09123456789',
        street: '12 Sample Street',
        barangay: 'Barangay One',
        city: 'Quezon City',
        province: 'Metro Manila',
        postalCode: '1100',
        isDefault: true,
      );

      expect(address.isValid, isTrue);
      expect(address.copyWith(street: 'placeholder').isValid, isFalse);
      await expectLater(
        repository.createCodOrder(
          items: [CartItem(product: product, quantity: 1)],
          address: address.copyWith(street: 'placeholder'),
          checkoutKey: 'invalid-checkout',
        ),
        throwsStateError,
      );

      final cartItem = CartItem(product: product, quantity: 2);
      await repository.saveCart([cartItem]);
      await repository.saveAddresses([address]);
      await repository.setFavorite(product.id, true);

      final restartedRepository = StoreRepository(demoMode: true);
      expect((await restartedRepository.fetchCart()).single.quantity, 2);
      expect(
        (await restartedRepository.fetchAddresses()).single.isValid,
        isTrue,
      );
      expect(await restartedRepository.fetchFavoriteIds(), {product.id});

      final orderId = await restartedRepository.createCodOrder(
        items: [cartItem],
        address: address,
        checkoutKey: 'checkout-test-1',
      );
      var order = OrderInfo.fromMap(
        (await restartedRepository.fetchOrders()).single,
      );
      expect(order.id, orderId);
      expect(order.stage, OrderStage.pendingConfirmation);
      expect(order.paymentMethod, 'COD');
      expect(order.amount, product.price * 2 + 150);
      expect(order.items.single.productName, product.name);
      expect(
        await restartedRepository.createCodOrder(
          items: [cartItem],
          address: address,
          checkoutKey: 'checkout-test-1',
        ),
        orderId,
      );
      expect((await restartedRepository.fetchOrders()).length, 1);
      expect(
        (await restartedRepository.fetchProducts())
            .firstWhere((item) => item.id == product.id)
            .stock,
        product.stock - 2,
      );

      await expectLater(
        restartedRepository.transitionOrder(orderId, 'mark_delivered'),
        throwsStateError,
      );
      await restartedRepository.transitionOrder(orderId, 'confirm');
      await restartedRepository.transitionOrder(orderId, 'ready_for_pickup');
      await restartedRepository.transitionOrder(orderId, 'accept_delivery');
      await expectLater(
        restartedRepository.transitionOrder(orderId, 'accept_delivery'),
        throwsStateError,
      );
      await restartedRepository.transitionOrder(orderId, 'mark_delivered');

      order = OrderInfo.fromMap(
        (await restartedRepository.fetchOrders()).single,
      );
      expect(order.stage, OrderStage.delivered);
      expect(order.riderId, StoreRepository.demoRiderId);
      expect(order.deliveredAt, isNotNull);
    },
  );

  test(
    'demo paid orders advance on the requested one-minute schedule',
    () async {
      final repository = StoreRepository(demoMode: true);
      final product = StoreRepository.demoProducts.first;
      final address = DeliveryAddress(
        id: 'demo-timeline-address',
        label: 'Home',
        fullName: 'Demo Customer',
        phone: '09123456789',
        street: '12 Sample Street',
        barangay: 'Barangay One',
        city: 'Quezon City',
        province: 'Metro Manila',
        postalCode: '1100',
      );
      final orderId = await repository.createDemoPaidOrder(
        items: [CartItem(product: product, quantity: 1)],
        address: address,
        checkoutKey: 'demo-xendit-timeline',
      );
      final preferences = await SharedPreferences.getInstance();

      Future<OrderInfo> orderAtAge(Duration age) async {
        final saved = jsonDecode(
          preferences.getString('databee.demo.orders')!,
        ) as List<dynamic>;
        final order = Map<String, dynamic>.from(saved.single as Map)
          ..['created_at'] = DateTime.now()
              .toUtc()
              .subtract(age)
              .toIso8601String();
        await preferences.setString('databee.demo.orders', jsonEncode([order]));
        final rows = await repository.fetchOrders();
        return OrderInfo.fromMap(rows.single);
      }

      expect(
        (await orderAtAge(const Duration(seconds: 9))).stage,
        OrderStage.pendingConfirmation,
      );
      final confirmed = await orderAtAge(const Duration(seconds: 10));
      expect(confirmed.stage, OrderStage.toShip);
      expect(confirmed.confirmedAt, isNotNull);

      final ready = await orderAtAge(const Duration(seconds: 30));
      expect(ready.stage, OrderStage.readyForPickup);
      expect(ready.readyForPickupAt, isNotNull);

      final outForDelivery = await orderAtAge(const Duration(seconds: 40));
      expect(outForDelivery.stage, OrderStage.outForDelivery);
      expect(outForDelivery.outForDeliveryAt, isNotNull);
      expect(outForDelivery.riderId, StoreRepository.demoRiderId);

      final delivered = await orderAtAge(const Duration(seconds: 60));
      expect(delivered.id, orderId);
      expect(delivered.stage, OrderStage.delivered);
      expect(delivered.deliveredAt, isNotNull);
    },
  );
}
