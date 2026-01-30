// import 'dart:typed_data';  // ← Add this import
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// import '../../data/services/easypaisa_paiment_service.dart';
//
//
// class EasypaisaPaymentScreen extends StatefulWidget {
//   final double amount;
//   final String customerEmail;
//   final String customerMobile;
//   final Function(bool success, String? transactionId) onPaymentComplete;
//
//   const EasypaisaPaymentScreen({
//     required this.amount,
//     required this.customerEmail,
//     required this.customerMobile,
//     required this.onPaymentComplete,
//     super.key,
//   });
//
//   @override
//   State<EasypaisaPaymentScreen> createState() => _EasypaisaPaymentScreenState();
// }
//
// class _EasypaisaPaymentScreenState extends State<EasypaisaPaymentScreen> {
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
//         Uri.parse(EasypaisaPaymentService.baseUrl),
//         method: LoadRequestMethod.post,
//         body: _buildPostData(),
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//       );
//   }
//
//   // ✅ FIXED: Now returns Uint8List
//   Uint8List _buildPostData() {
//     final params = EasypaisaPaymentService.createPaymentParams(
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
//     if (url.contains('payment/easypaisa/callback')) {
//       final uri = Uri.parse(url);
//       final status = uri.queryParameters['status'];
//       final orderRefNum = uri.queryParameters['orderRefNum'];
//
//       if (status == '0000') {
//         // Payment successful
//         widget.onPaymentComplete(true, orderRefNum);
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
//         title: const Text('Easypaisa Payment'),
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