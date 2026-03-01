import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Three',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const SharedAssetDemoPage(),
    );
  }
}

class SharedAssetDemoPage extends StatelessWidget {
  const SharedAssetDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Three · Shared Assets')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('공용 에셋 재사용 데모', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Image(image: AssetImage('assets/shared/kenney_ui_preview.png')),
          SizedBox(height: 12),
          Image(image: AssetImage('assets/shared/emotes_preview.png')),
          SizedBox(height: 12),
          Text('오디오 파일 포함: assets/audio/click_a.ogg'),
        ],
      ),
    );
  }
}
