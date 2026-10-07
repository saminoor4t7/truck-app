import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_drawer.dart';
import '../data/local_signature_repository.dart';
import 'signature_pad.dart';

class SignatureCaptureView extends StatefulWidget {
  const SignatureCaptureView({super.key});

  @override
  State<SignatureCaptureView> createState() => _SignatureCaptureViewState();
}

class _SignatureCaptureViewState extends State<SignatureCaptureView> {
  final _signatures = LocalSignatureRepository();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppDrawerMenuButton(),
      title: const Text('Proof of delivery signature'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Customer signature'),
        const SizedBox(height: 12),
        SignaturePad(
          savedMessage: 'Signature saved and available in Admin Dashboard.',
          onSaved: (base64Png) async {
            await _signatures.save(base64Png);
          },
        ),
      ],
    ),
  );
}
