import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const VoiceSOSApp());
}

class VoiceSOSApp extends StatelessWidget {
  const VoiceSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice SOS',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const SOSHomePage(),
    );
  }
}

class SOSHomePage extends StatefulWidget {
  const SOSHomePage({super.key});

  @override
  State<SOSHomePage> createState() => _SOSHomePageState();
}

class _SOSHomePageState extends State<SOSHomePage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';
  bool voiceSupported = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize();
    setState(() {
      voiceSupported = available;
    });
  }

  Future<void> _startListening() async {
    await _speech.listen(onResult: (val) {
      setState(() {
        _lastWords = val.recognizedWords;
      });
      if (_lastWords.toLowerCase().contains("help") ||
          _lastWords.toLowerCase().contains("sos")) {
        _sendAlert();
      }
    });
    setState(() => _isListening = true);
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendAlert() async {
    try {
      // Get current GPS location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      double latitude = position.latitude;
      double longitude = position.longitude;

      // Personalised SOS message
      final String message = Uri.encodeComponent(
          "🚨 SOS Alert! This is Shreya Pandey. I need urgent help!\n"
          "📍 My location: https://www.google.com/maps/search/?api=1&query=$latitude,$longitude\n"
          "⏰ Time: ${DateTime.now()}");

      // Replace with your emergency contact number (with country code, no +)
      const String phoneNumber = "919142003240";

      final Uri url = Uri.parse(
          "https://web.whatsapp.com/send?phone=$phoneNumber&text=$message");

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception("Could not launch $url");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending alert: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice SOS Alert"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Say 'Help' or 'SOS' to trigger an emergency alert.",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              "Last Heard: $_lastWords",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (voiceSupported)
              FilledButton.icon(
                onPressed: _isListening ? _stopListening : _startListening,
                icon:
                    Icon(_isListening ? Icons.hearing_disabled : Icons.hearing),
                label:
                    Text(_isListening ? "Stop Voice SOS" : "Start Voice SOS"),
              )
            else
              const Text(
                "Voice capture limited on Web. Use the button below to test alert.",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _sendAlert,
              icon: const Icon(Icons.warning_amber),
              label: const Text("Send Test SOS (GPS + WhatsApp)"),
            ),
            const Spacer(),
            const Text(
              "Tip: Use HTTPS in production so browsers allow GPS prompts (GitHub Pages/Netlify do).",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
