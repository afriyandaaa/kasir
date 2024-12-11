import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

class DocumentDirectoryExample extends StatefulWidget {
  @override
  _DocumentDirectoryExampleState createState() => _DocumentDirectoryExampleState();
}

class _DocumentDirectoryExampleState extends State<DocumentDirectoryExample> {
  String? _directoryPath;

  @override
  void initState() {
    super.initState();
    _getDocumentDirectory();
  }

  Future<void> _getDocumentDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      setState(() {
        _directoryPath = directory.path;
      });
    } catch (e) {
      setState(() {
        _directoryPath = 'Failed to get directory: $e';
      });
    }
  }

  Future<String> saveImageToLocal(Uint8List imageData, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(imageData);
    return filePath; // Kembalikan path file yang disimpan
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Directory Example'),
      ),
      body: Center(
        child: Text(
          _directoryPath ?? 'Fetching directory...',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
