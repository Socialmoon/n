import 'package:flutter/material.dart';

class PostNewRequestResult {
  const PostNewRequestResult({
    required this.category,
    required this.message,
  });

  final String category;
  final String message;
}

class PostNewRequestScreen extends StatefulWidget {
  const PostNewRequestScreen({
    required this.categories,
    super.key,
  });

  final List<String> categories;

  @override
  State<PostNewRequestScreen> createState() => _PostNewRequestScreenState();
}

class _PostNewRequestScreenState extends State<PostNewRequestScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categories.first;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post New Request')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF4F7FA), Color(0xFFEFF3E8)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF0D3443), Color(0xFF2E6A5D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x220B2530),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Need support from members?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose the category and write your request clearly. Nearby members can call, message, and coordinate quickly.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Request Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: widget.categories
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _messageController,
                        maxLines: 6,
                        minLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Describe what help you need',
                          alignLabelWithHint: true,
                          hintText: 'Example: Need urgent blood donor at district hospital...',
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tip: Mention urgency, location, and best callback number in your message.',
                        style: TextStyle(color: Color(0xFF5A6B74), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Post Request'),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter request details before posting.')),
      );
      return;
    }

    Navigator.of(context).pop(
      PostNewRequestResult(
        category: _selectedCategory,
        message: message,
      ),
    );
  }
}
