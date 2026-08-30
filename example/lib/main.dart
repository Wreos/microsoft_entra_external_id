import 'package:entra_external_id/entra_external_id.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Checking native bridge...';
  final _entraExternalIdPlugin = EntraExternalId();

  @override
  void initState() {
    super.initState();
    _loadNativeSdkStatus();
  }

  Future<void> _loadNativeSdkStatus() async {
    String statusText;
    try {
      final status = await _entraExternalIdPlugin.getNativeSdkStatus();
      statusText = status.linked
          ? 'MSAL ${status.sdkVersion ?? 'unknown version'} linked on '
                '${status.platform.name}'
          : 'Bootstrap ready on ${status.platform.name}; MSAL not linked yet';
    } on Object catch (error) {
      statusText = 'Native bridge check failed: $error';
    }

    if (!mounted) return;

    setState(() {
      _status = statusText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Entra External ID bootstrap')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_status, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
