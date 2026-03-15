import 'package:flutter/material.dart';
import 'custom_button_model.dart';

const _iconOptions = {
  'speed':                Icons.speed,
  'pan_tool':             Icons.pan_tool,
  'keyboard_arrow_up':    Icons.keyboard_arrow_up,
  'keyboard_arrow_down':  Icons.keyboard_arrow_down,
  'expand_less':          Icons.expand_less,
  'expand_more':          Icons.expand_more,
  'gamepad':              Icons.gamepad,
  'touch_app':            Icons.touch_app,
  'arrow_upward':         Icons.arrow_upward,
  'arrow_downward':       Icons.arrow_downward,
  'u_turn_left':          Icons.u_turn_left,
  'swap_vert':            Icons.swap_vert,
  'bolt':                 Icons.bolt,
  'flag':                 Icons.flag,
  'sports_score':         Icons.sports_score,
};

IconData iconFromName(String name) =>
  _iconOptions[name] ?? Icons.gamepad;

const _swipeDirs = ['none', 'up', 'down', 'left', 'right'];

class ButtonEditor extends StatefulWidget {
  const ButtonEditor({super.key});
  @override
  State<ButtonEditor> createState() => _ButtonEditorState();
}

class _ButtonEditorState extends State<ButtonEditor> {
  List<CustomButton> _buttons = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final btns = await ButtonStorage.load();
    setState(() => _buttons = btns);
  }

  Future<void> _save() async {
    await ButtonStorage.save(_buttons);
    if (mounted) Navigator.pop(context);
  }

  void _editButton(int index) {
    final btn       = _buttons[index];
    final nameCtrl  = TextEditingController(text: btn.name);
    final txCtrl    = TextEditingController(text: btn.touchX.toInt().toString());
    final tyCtrl    = TextEditingController(text: btn.touchY.toInt().toString());
    final wCtrl     = TextEditingController(text: btn.uiWidth.toInt().toString());
    final hCtrl     = TextEditingController(text: btn.uiHeight.toInt().toString());
    final distCtrl  = TextEditingController(text: btn.swipeDist.toInt().toString());
    String icon     = btn.icon;
    bool isHold     = btn.isHold;
    String swipeDir = btn.swipeDir;
    String side     = btn.side;

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
                _field(nameCtrl, 'Button Name'),
                const SizedBox(height: 10),
                _label('Touch Coordinates (Game Screen)'),
                Row(children: [
                  Expanded(child: _field(txCtrl, 'Touch X', num: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(tyCtrl, 'Touch Y', num: true)),
                ]),
                const SizedBox(height: 10),
                _label('Button Size (UI)'),
                Row(children: [
                  Expanded(child: _field(wCtrl, 'Width', num: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(hCtrl, 'Height', num: true)),
                ]),
                const SizedBox(height: 10),
                _label('Screen Side'),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setS(() => side = 'left'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: side == 'left'
                            ? Colors.white : const Color(0xFF222222),
                          border: Border.all(
                            color: side == 'left'
                              ? Colors.white : Colors.white24)),
                        child: Text('LEFT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: side == 'left'
                              ? Colors.black : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setS(() => side = 'right'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: side == 'right'
                            ? Colors.white : const Color(0xFF222222),
                          border: Border.all(
                            color: side == 'right'
                              ? Colors.white : Colors.white24)),
                        child: Text('RIGHT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: side == 'right'
                              ? Colors.black : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                _label('Swipe Direction'),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _swipeDirs.map((d) {
                    final sel = swipeDir == d;
                    return GestureDetector(
                      onTap: () => setS(() => swipeDir = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: sel
                            ? Colors.white : const Color(0xFF222222),
                          border: Border.all(
                            color: sel ? Colors.white : Colors.white24)),
                        child: Text(d,
                          style: TextStyle(
                            color: sel ? Colors.black : Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                if (swipeDir != 'none') ...[
                  const SizedBox(height: 8),
                  _field(distCtrl, 'Swipe Distance (px)', num: true),
                ],
                const SizedBox(height: 10),
                _label('Icon'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _iconOptions.entries.map((e) {
                    final sel = icon == e.key;
                    return GestureDetector(
                      onTap: () => setS(() => icon = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
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
                const SizedBox(height: 10),
                Row(children: [
                  const Text('Hold?',
                    style: TextStyle(
                      color: Colors.white54, fontSize: 13)),
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
                    id:        btn.id,
                    name:      nameCtrl.text.toUpperCase(),
                    icon:      icon,
                    isHold:    isHold,
                    touchX:    double.tryParse(txCtrl.text)   ?? btn.touchX,
                    touchY:    double.tryParse(tyCtrl.text)   ?? btn.touchY,
                    uiWidth:   double.tryParse(wCtrl.text)    ?? btn.uiWidth,
                    uiHeight:  double.tryParse(hCtrl.text)    ?? btn.uiHeight,
                    uiPosX:    btn.uiPosX,   // SAME rehne do
                    uiPosY:    btn.uiPosY,   // SAME rehne do
                    swipeDir:  swipeDir,
                    swipeDist: double.tryParse(distCtrl.text) ?? btn.swipeDist,
                    side:      side,
                  );
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white),
              child: const Text('Save',
                style: TextStyle(color: Colors.black))),
          ],
        );
      });
    });
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
        style: const TextStyle(
          color: Colors.white38, fontSize: 11))));

  Widget _field(TextEditingController ctrl, String label,
      {bool num = false}) =>
    TextField(
      controller: ctrl,
      keyboardType: num ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24))));

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
                color: Colors.white,
                fontWeight: FontWeight.bold))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _buttons.add(CustomButton(
              id:       DateTime.now().millisecondsSinceEpoch.toString(),
              name:     'NEW',
              icon:     'gamepad',
              isHold:   true,
              touchX:   500, touchY: 500,
              uiWidth:  110, uiHeight: 90,
              uiPosX:   0,   uiPosY: 0,
              swipeDir: 'none', swipeDist: 100,
              side:     'right',
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
              final b = _buttons[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12)),
                child: Row(children: [
                  Icon(iconFromName(b.icon),
                    color: Colors.white70, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          '${b.side.toUpperCase()}  '
                          'Touch:${b.touchX.toInt()},${b.touchY.toInt()}  '
                          '${b.uiWidth.toInt()}×${b.uiHeight.toInt()}  '
                          'Swipe:${b.swipeDir}  '
                          '${b.isHold ? "Hold" : "Tap"}',
                          style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24)),
                    child: Text(
                      b.side == 'left' ? 'L' : 'R',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit,
                      color: Colors.white38, size: 20),
                    onPressed: () => _editButton(i)),
                  IconButton(
                    icon: const Icon(Icons.delete,
                      color: Colors.red, size: 20),
                    onPressed: () =>
                      setState(() => _buttons.removeAt(i))),
                ]),
              );
            },
          ),
    );
  }
}
