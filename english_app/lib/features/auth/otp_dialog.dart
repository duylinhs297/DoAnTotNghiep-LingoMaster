// otp_dialog.dart
import 'package:flutter/material.dart';

class OtpVerificationDialog extends StatefulWidget {
  final String email;
  final String purpose;
  final Future<bool> Function(String otp) onVerify;

  const OtpVerificationDialog({
    super.key,
    required this.email,
    required this.purpose,
    required this.onVerify,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Xác thực 2FA', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mã OTP đã được gửi đến:\n${widget.email}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              errorText: _errorMessage,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isVerifying
              ? null
              : () async {
            // Lưu NavigatorState trước khoảng nghỉ async
            final navigator = Navigator.of(context);

            setState(() {
              _isVerifying = true;
              _errorMessage = null;
            });

            final success = await widget.onVerify(_otpController.text.trim());

            if (!mounted) return;

            if (success) {
              navigator.pop(true);
            } else {
              setState(() {
                _isVerifying = false;
                _errorMessage = 'Mã OTP không đúng hoặc đã hết hạn';
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          child: _isVerifying
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Xác nhận'),
        ),
      ],
    );
  }
}