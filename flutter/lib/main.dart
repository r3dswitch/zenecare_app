import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wound Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WoundFormPage(),
    );
  }
}

class WoundFormPage extends StatefulWidget {
  const WoundFormPage({super.key});

  @override
  State<WoundFormPage> createState() => _WoundFormPageState();
}

class _WoundFormPageState extends State<WoundFormPage> {
  File? _image;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _generatePdfAndShare() async {
    final pdf = pw.Document();
    final image = _image != null ? pw.MemoryImage(_image!.readAsBytesSync()) : null;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Wound Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            if (image != null) pw.Image(image, height: 200),
            pw.SizedBox(height: 16),
            pw.Text("Date: ${_dateController.text}"),
            pw.Text("Description: ${_descriptionController.text}"),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/wound_report.pdf");
    await file.writeAsBytes(await pdf.save());

    Share.shareXFiles([XFile(file.path)], text: 'Wound Report PDF');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Wound Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Take Photo"),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 12),
              if (_image != null) Image.file(_image!, height: 200),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date of Wound'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Generate PDF & Share"),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _generatePdfAndShare();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
