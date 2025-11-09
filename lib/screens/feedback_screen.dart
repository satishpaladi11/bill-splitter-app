import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();

  bool isLoading = false;
  bool _submitted = false;

  void submitFeedback() {
    final feedback = _feedbackController.text.trim();

    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your feedback")),
      );
      return;
    }

    setState(() => isLoading = true);

    // Simulate async submission. After completion, show an inline confirmation
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _submitted = true;
      });
      // Clear the controller to avoid leaving text behind
      _feedbackController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Feedback"), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_submitted) ...[
                const Text(
                  "We value your feedback 😊",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
              ],

              // If submitted, show a friendly confirmation card in-place
              if (_submitted)
                Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green, size: 56),
                          const SizedBox(height: 12),
                          const Text('Thanks — we received your feedback!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('We appreciate you taking the time. We will review your message and get back if needed.', textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 160,
                            child: ElevatedButton(
                              onPressed: () {
                                // Reset submitted state so the same feedback form is shown
                                // and the user can submit another message.
                                setState(() {
                                  _submitted = false;
                                  isLoading = false;
                                  // feedback controller already cleared after submit
                                });
                                // keep on the same page so user can add another feedback
                              },
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: TextField(
                    controller: _feedbackController,
                    decoration: const InputDecoration(
                      labelText: "Your feedback",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    maxLength: 1000,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  ),
                ),
              const SizedBox(height: 16),

              // Only show the submit button when not already submitted
              if (!_submitted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submitFeedback,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(),
                          )
                        : const Text("Submit"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
