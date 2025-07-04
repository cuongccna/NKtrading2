import 'package:equatable/equatable.dart';

class TradeFilterModel extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? symbol;
  final String? strategy;

  const TradeFilterModel({
    this.startDate,
    this.endDate,
    this.symbol,
    this.strategy,
  });

  @override
  List<Object?> get props => [startDate, endDate, symbol, strategy];
}
