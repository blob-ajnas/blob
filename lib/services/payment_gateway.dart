import 'package:flutter/foundation.dart';

class PaymentResult {
  final bool success;
  final String message;
  final String? gatewayRef;

  const PaymentResult({
    required this.success,
    required this.message,
    this.gatewayRef,
  });
}

/// INR-only payment gateway abstraction.
///
/// Note there is no currency argument — the single currency rule is
/// enforced at the interface level. A Razorpay implementation swaps in
/// here once live API keys are supplied.
abstract class PaymentGateway {
  Future<PaymentResult> charge({
    required int amountPaise,
    required String description,
    required String payerId,
  });

  Future<PaymentResult> payout({
    required int amountPaise,
    required String payeeId,
    required String description,
  });
}

/// Stub gateway used until Razorpay keys + RazorpayX KYC are available.
/// The ledger it feeds is fully functional and real.
class StubPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentResult> charge({
    required int amountPaise,
    required String description,
    required String payerId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (kDebugMode) {
      debugPrint('[BLOB PAY] charge $amountPaise paise ($description)');
    }
    return PaymentResult(
      success: true,
      message: 'Payment successful',
      gatewayRef: 'stub_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<PaymentResult> payout({
    required int amountPaise,
    required String payeeId,
    required String description,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return PaymentResult(
      success: true,
      message: 'Payout cleared',
      gatewayRef: 'stubpo_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
