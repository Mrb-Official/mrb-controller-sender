import 'package:flutter/material.dart';
import 'custom_button_model.dart';

class ButtonEditor extends StatefulWidget {
  const ButtonEditor({super.key});
  @override
  State<ButtonEditor> createState() => _ButtonEditorState();
}

class _ButtonEditorState extends State<ButtonEditor> {
  List<CustomButton> _buttons = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final btns = await ButtonStorage.load();
    setState(() => _buttons = btns);
  }

  Future<void> _save() async {
    await ButtonStorage.save(_buttons);
    if (mounted) Navigator.pop(context);
  }

  void _addButton() {
    showDialog(context: context, builder: (_) {
      final nameCtrl  = TextEditingController();
      final emojiCtrl = TextEditingController(text: '🎯');
      bool isHold = true;
      return StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('New Button', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Button Name (e.g. HORN)',
                  labelStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF333355))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emojiCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 24),
                decoration: const InputDecoration(
                  labelText: 'Emoji',
                  labelStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF333355))),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Hold button?',
                    style: TextStyle(color: Colors.white54)),
                  const Spacer(),
                  Switch(
                    value: isHold,
                    onChanged: (v) => setS(() => isHold = v),
                    activeColor: const Color(0xFF00D4FF),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                setState(() {
                  _buttons.add(CustomButton(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.toUpperCase(),
                    emoji: emojiCtrl.text,
                    isHold: isHold,
                  ));
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF)),
              child: const Text('Add', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        title: const Text('⚙️ Custom Buttons',
          style: TextStyle(color: Color(0xFF00D4FF))),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE', style: TextStyle(color: Color(0xFF00D4FF))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addButton,
        backgroundColor: const Color(0xFF00D4FF),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _buttons.isEmpty
          ? const Center(
              child: Text('No buttons yet\nTap + to add',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _buttons.length,
              itemBuilder: (_, i) {
                final btn = _buttons[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111133),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF333355)),
                  ),
                  child: Row(
                    children: [
                      Text(btn.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(btn.name,
                              style: const TextStyle(color: Colors.white,
                                fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(btn.isHold ? 'Hold' : 'Tap',
                              style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => setState(() => _buttons.removeAt(i)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
