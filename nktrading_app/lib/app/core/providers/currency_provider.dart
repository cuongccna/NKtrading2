// File: lib/app/core/providers/currency_provider.dart
import 'package:flutter/material.dart';
import '../../../main.dart';

class CurrencyProvider extends ChangeNotifier {
  String _currency = 'USD';
  double _exchangeRate = 1.0;
  bool _isLoading = false;

  String get currency => _currency;
  double get exchangeRate => _exchangeRate;
  bool get isLoading => _isLoading;

  CurrencyProvider() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('user_profiles')
          .select('preferred_currency')
          .eq('id', userId)
          .maybeSingle();
      final data = response;

      if (data != null && data['preferred_currency'] != null) {
        _currency = data['preferred_currency'];

        // Load exchange rate if VND
        if (_currency == 'VND') {
          await _loadExchangeRate();
        }
      }
    } catch (e) {
      debugPrint('Error loading currency: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadExchangeRate() async {
    try {
      final response = await supabase.functions.invoke('get-exchange-rate');
      if (response.data != null && response.data['rate'] != null) {
        _exchangeRate = response.data['rate'].toDouble();
      }
    } catch (e) {
      debugPrint('Error loading exchange rate: $e');
      _exchangeRate = 23000.0; // Fallback rate
    }
  }

  Future<void> updateCurrency(String newCurrency) async {
    if (newCurrency == _currency) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('user_profiles').upsert({
        'id': userId,
        'preferred_currency': newCurrency,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      _currency = newCurrency;

      if (newCurrency == 'VND') {
        await _loadExchangeRate();
      } else {
        _exchangeRate = 1.0;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating currency: $e');
      rethrow;
    }
  }

  // Format currency based on current setting
  String formatCurrency(double amount) {
    final convertedAmount = _currency == 'VND'
        ? amount * _exchangeRate
        : amount;

    if (_currency == 'VND') {
      // Format VND without decimals
      return '${convertedAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
    } else {
      // Format USD with 2 decimals
      return '\$${convertedAmount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
  }
}
