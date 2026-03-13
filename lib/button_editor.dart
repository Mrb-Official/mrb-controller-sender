import 'package:flutter/material.dart';
import 'custom_button_model.dart';

const _iconOptions = {
  'speed':              Icons.speed,
  'pan_tool':           Icons.pan_tool,
  'expand_less':        Icons.expand_less,
  'expand_more':        Icons.expand_more,
  'gamepad':            Icons.gamepad,
  'touch_app':          Icons.touch_app,
  'arrow_upward':       Icons.arrow_upward,
  'arrow_downward':     Icons.arrow_downward,
  'arrow_back':         Icons.arrow_back,
  'arrow_forward':      Icons.arrow_forward,
  'radio_button_checked': Icons.radio_button_checked,
  'stars':              Icons.stars,
  'bolt':               Icons.bolt,
  'flag':               Icons.flag,
};

IconData iconFromName(String name) => _iconOptions[name] ?? Icons.gamepad;

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

  void _editButton(int index) {
    final btn = _buttons[index];
    final nameCtrl = TextEditingController(text: btn.name);
    final xCtrl    = TextEditingController(text: btn.x.toInt().toString());
    final yCtrl    = TextEditingController(text: btn.y.toInt().toString());
    String selectedIcon = btn.icon;
    bool isHold = btn.isHold;

    showDialog(context: context, builder: (_) {
      return StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Edit: ${btn.name}',
            style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white38),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(
                    controller: xCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'X',
                      labelStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24))),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(
                    controller: yCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Y',
                      labelStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24))),
                  )),
                ]),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _iconOptions.entries.map((e) {
                    final sel = selectedIcon == e.key;
                    return GestureDetector(
                      onTap: () => setS(() => selectedIcon = e.key),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel ? Colors.white : Colors.transparent,
                          border: Border.all(
                            color: sel ? Colors.white : Colors.white24)),
                        child: Icon(e.value,
                          color: sel ? Colors.black : Colors.white54,
                          size: 20),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Hold?',
                    style: TextStyle(color: Colors.white54)),
                  const Spacer(),
                  Switch(
                    value: isHold,
                    onChanged: (v) => setS(() => isHold = v),
                    activeColor: Colors.white),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _buttons[index] = CustomButton(
                    id: btn.id,
                    name: nameCtrl.text.toUpperCase(),
                    icon: selectedIcon,
                    isHold: isHold,
                    x: double.tryParse(xCtrl.text) ?? btn.x,
                    y: double.tryParse(yCtrl.text) ?? btn.y,
                  );
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text('Save',
                style: TextStyle(color: Colors.black))),
          ],
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Button Config',
          style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE',
              style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _buttons.add(CustomButton(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: 'NEW',
              icon: 'gamepad',
              isHold: true,
              x: 500, y: 500,
            ));
          });
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _buttons.isEmpty
        ? const Center(
            child: Text('No buttons\nTap + to add',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38)))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _buttons.length,
            itemBuilder: (_, i) {
              final btn = _buttons[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12)),
                child: Row(children: [
                  Icon(iconFromName(btn.icon),
                    color: Colors.white70, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(btn.name,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 15,
                            fontWeight: FontWeight.bold)),
                        Text('X:${btn.x.toInt()}  Y:${btn.y.toInt()}'
                          '  ${btn.isHold ? "Hold" : "Tap"}',
                          style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white38),
                    onPressed: () => _editButton(i)),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                      setState(() => _buttons.removeAt(i))),
                ]),
              );
            },
          ),
    );
  }
}
