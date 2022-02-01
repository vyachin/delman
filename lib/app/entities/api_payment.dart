part of 'entities.dart';

class ApiPayment {
  final int id;
  final int deliveryPointOrderId;
  final double summ;
  final String? transactionId;

  const ApiPayment({
    required this.id,
    required this.deliveryPointOrderId,
    required this.summ,
    this.transactionId
  });

  factory ApiPayment.fromJson(dynamic json) {
    return ApiPayment(
      id: json['id'],
      deliveryPointOrderId: json['deliveryPointOrderId'],
      summ: Nullify.parseDouble(json['summ'])!,
      transactionId: json['transactionId']
    );
  }

  Payment toDatabaseEnt() {
    return Payment(
      id: id,
      deliveryPointOrderId: deliveryPointOrderId,
      summ: summ,
      transactionId: transactionId
    );
  }
}
