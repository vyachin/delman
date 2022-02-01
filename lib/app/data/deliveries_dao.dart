part of 'database.dart';

@DriftAccessor(
  tables: [Deliveries, DeliveryPoints, DeliveryPointOrders],
  queries: {
    'deliveryPointEx': '''
      SELECT
        dp.**,
        EXISTS(
          SELECT 1
          FROM delivery_point_orders AS dpo
          JOIN orders AS o ON o.id = dpo.order_id
          WHERE
            dpo.delivery_point_id = dp.id AND
            dp.fact_arrival IS NULL
        ) is_not_in_progress,
        EXISTS(
          SELECT 1
          FROM delivery_point_orders AS dpo
          JOIN orders AS o ON o.id = dpo.order_id
          WHERE
            dpo.delivery_point_id = dp.id AND
            dp.fact_arrival IS NOT NULL AND
            dp.fact_departure IS NULL
        ) is_in_progress,
        EXISTS(
          SELECT 1
          FROM delivery_point_orders AS dpo
          JOIN orders AS o ON o.id = dpo.order_id
          WHERE
            dpo.pickup = 0 AND
            dpo.finished = 1 AND
            dpo.delivery_point_id = dp.id AND
            o.need_payment = 1 AND
            dp.fact_arrival IS NOT NULL AND
            dp.fact_departure IS NOT NULL
        ) is_incomplete,
        dp.fact_arrival IS NOT NULL AND
          dp.fact_departure IS NOT NULL AND (
            NOT EXISTS(
              SELECT 1
              FROM delivery_point_orders AS dpo
              JOIN orders AS o ON o.id = dpo.order_id
              WHERE
                dpo.pickup = 0 AND
                dpo.finished = 1 AND
                dpo.delivery_point_id = dp.id AND
                o.need_payment = 1
            ) OR EXISTS(
              SELECT 1
              FROM delivery_point_orders AS dpo
              JOIN orders AS o ON o.id = dpo.order_id
              WHERE
                dpo.pickup = 1 AND
                dpo.finished = 1 AND
                dpo.delivery_point_id = dp.id
            )
          ) is_completed,
          (
            SELECT MAX(CASE dpo.pickup WHEN 1 THEN o.pickup_date_time_from ELSE o.delivery_date_time_from END)
            FROM delivery_point_orders dpo
            JOIN orders o ON o.id = dpo.order_id
            WHERE dpo.delivery_point_id = dp.id
          ) date_time_from,
          (
            SELECT MAX(CASE dpo.pickup WHEN 1 THEN o.pickup_date_time_to ELSE o.delivery_date_time_to END)
            FROM delivery_point_orders dpo
            JOIN orders o ON o.id = dpo.order_id
            WHERE dpo.delivery_point_id = dp.id
          ) date_time_to
      FROM deliveries AS d
      JOIN delivery_points AS dp ON dp.delivery_id = d.id
      ORDER BY d.delivery_date ASC, dp.seq ASC
    ''',
    'deliveryPointOrderEx': '''
      SELECT
        dpo.**,
        o.**
      FROM delivery_point_orders dpo
      JOIN orders o ON o.id = dpo.order_id
      ORDER BY o.tracking_number ASC
    '''
  }
)
class DeliveriesDao extends DatabaseAccessor<AppStorage> with _$DeliveriesDaoMixin {
  DeliveriesDao(AppStorage db) : super(db);

  Future<List<ExDelivery>> getExDeliveries() async {
    final query = select(deliveries)..orderBy([(t) => OrderingTerm.asc(t.deliveryDate)]);
    final exDeliveryPoints = await deliveryPointEx().get();

    List<Delivery> queryDeliveries = await query.get();

    return queryDeliveries.map((Delivery delivery) {
      return ExDelivery(
        delivery: delivery,
        deliveryPoints: exDeliveryPoints.where((element) => element.dp.deliveryId == delivery.id).toList()
      );
    }).toList();
  }

  Future<List<DeliveryPointExResult>> getExDeliveryPoints(int deliveryId) async {
    return (await deliveryPointEx().get()).where((el) => el.dp.deliveryId == deliveryId).toList();
  }

  Future<DeliveryPointExResult?> getExDeliveryPoint(int id) async {
    return (await deliveryPointEx().get()).firstWhereOrNull((el) => el.dp.id == id);
  }

  Future<List<DeliveryPointOrderExResult>> getExDeliveryPointOrders(int deliveryPointId) async {
    return (await deliveryPointOrderEx().get()).where((el) => el.dpo.deliveryPointId == deliveryPointId).toList();
  }

  Future<DeliveryPointOrderExResult?> getExDeliveryPointOrder(int deliveryPointOrderId) async {
    return (await deliveryPointOrderEx().get()).firstWhereOrNull((el) => el.dpo.id == deliveryPointOrderId);
  }

  Future<void> loadDeliveries(List<Delivery> deliveryList) async {
    await batch((batch) {
      batch.deleteWhere(deliveries, (row) => const Constant(true));
      batch.insertAll(deliveries, deliveryList);
    });
  }

  Future<void> loadDeliveryPoints(List<DeliveryPoint> deliveryPointList) async {
    await batch((batch) {
      batch.deleteWhere(deliveryPoints, (row) => const Constant(true));
      batch.insertAll(deliveryPoints, deliveryPointList);
    });
  }

  Future<void> loadDeliveryPointOrders(List<DeliveryPointOrder> deliveryPointOrderList) async {
    await batch((batch) {
      batch.deleteWhere(deliveryPointOrders, (row) => const Constant(true));
      batch.insertAll(deliveryPointOrders, deliveryPointOrderList);
    });
  }

  Future<void> updateDeliveryPoint(int id, DeliveryPointsCompanion deliveryPoint) {
    return (update(deliveryPoints)..where((t) => t.id.equals(id))).write(deliveryPoint);
  }

  Future<void> updateDeliveryPointOrder(int id, DeliveryPointOrdersCompanion deliveryPointOrder) {
    return (update(deliveryPointOrders)..where((t) => t.id.equals(id))).write(deliveryPointOrder);
  }
}

class ExDelivery {
  ExDelivery({
    required this.delivery,
    required this.deliveryPoints
  });

  final Delivery delivery;
  final List<DeliveryPointExResult> deliveryPoints;
}
