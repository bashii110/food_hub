// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import '../../data/services/jazzcash_payment_service.dart';
//
// class JazzCashPaymentScreen extends StatefulWidget {
//   final double amount;
//   final String customerEmail;
//   final String customerMobile;
//   final Function(bool success, String? transactionId) onPaymentComplete;
//
//   const JazzCashPaymentScreen({
//     super.key,
//     required this.amount,
//     required this.customerEmail,
//     required this.customerMobile,
//     required this.onPaymentComplete,
//   });
//
//   @override
//   State<JazzCashPaymentScreen> createState() => _JazzCashPaymentScreenState();
// }
//
// class _JazzCashPaymentScreenState extends State<JazzCashPaymentScreen> {
//   late final WebViewController _controller;
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeWebView();
//   }
//
//   void _initializeWebView() {
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onProgress: (int progress) {
//             if (progress == 100) {
//               setState(() => _isLoading = false);
//             }
//           },
//           onPageStarted: (String url) {
//             _checkPaymentResponse(url);
//           },
//           onPageFinished: (String url) {
//             _checkPaymentResponse(url);
//           },
//         ),
//       )
//       ..loadRequest(
//         Uri.parse(JazzCashPaymentService.baseUrl),
//         method: LoadRequestMethod.post,
//         body: _buildPostData(),
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//       );
//   }
//
//   // ✅ FIXED: Now returns Uint8List
//   Uint8List _buildPostData() {
//     final params = JazzCashPaymentService.createPaymentParams(
//       amount: widget.amount,
//       customerEmail: widget.customerEmail,
//       customerMobile: widget.customerMobile,
//     );
//
//     final postData = params.entries
//         .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
//         .join('&');
//
//     return Uint8List.fromList(postData.codeUnits);  // ✅ Correct conversion
//   }
//
//   void _checkPaymentResponse(String url) {
//     // Check if this is the return URL
//     if (url.contains('payment/callback')) {
//       final uri = Uri.parse(url);
//       final responseCode = uri.queryParameters['pp_ResponseCode'];
//       final txnRefNo = uri.queryParameters['pp_TxnRefNo'];
//
//       if (responseCode == '000') {
//         // Payment successful
//         widget.onPaymentComplete(true, txnRefNo);
//         Navigator.pop(context);
//       } else {
//         // Payment failed
//         widget.onPaymentComplete(false, null);
//         Navigator.pop(context);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('JazzCash Payment'),
//         leading: IconButton(
//           icon: const Icon(Icons.close),
//           onPressed: () {
//             widget.onPaymentComplete(false, null);
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: _controller),
//           if (_isLoading)
//             const Center(
//               child: CircularProgressIndicator(),
//             ),
//         ],
//       ),
//     );
//   }
// }