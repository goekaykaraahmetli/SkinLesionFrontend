import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Lesion Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Skin Lesion Detector'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _prediction;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _prediction = null; // Reset previous results
      });
    }
  }

  Future<void> _predict() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5000/predict'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      print("Response: $responseData"); // Debugging output

      setState(() {
        _prediction = json.decode(responseData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_image != null) ...[
                  Image.file(_image!, height: 200),
                  const SizedBox(height: 20),
                ],
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Select Image'),
                ),
                const SizedBox(height: 20),
                if (_image != null)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _predict,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Predict'),
                  ),
                if (_prediction != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Predicted Class: ${_prediction!['predicted_class']}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  /*
                  // Confidence Scores
                  Text(
                    'Confidence Scores:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    (_prediction!['mean_prediction'] as List)
                        .expand((e) => e as List)  // Flatten the list
                        .map((score) => (score as num).toStringAsFixed(3))
                        .join(', '),
                  ),
                  const SizedBox(height: 10),

                  // Uncertainty Scores
                  Text(
                    'Uncertainty Scores:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    (_prediction!['uncertainty'] as List)
                        .expand((e) => e as List)  // Flatten the list
                        .map((score) => (score as num).toStringAsFixed(3))
                        .join(', '),
                  ),
                  */
                  const SizedBox(height: 10),

                  // OOD Detection Alert
                  if (_prediction!['is_ood'] == true) ...[
                    const SizedBox(height: 10),
                    Text(
                      '🚨 OOD Detected!',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}