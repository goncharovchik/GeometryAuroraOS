with open('lib/data/game_storage.dart', 'r', encoding='utf-8') as f:
    text = f.read().replace('\r\n', '\n')

old_field = '''  final Map<String, int> _upgradeLevels = {};'''
new_field = '''  final Map<String, int> _upgradeLevels = {};
  bool _flipLandscape = false;'''

assert old_field in text, 'old_field not found'
text = text.replace(old_field, new_field)

old_prop = '''  Color get playerColor1 => _playerColor1;'''
new_prop = '''  bool get flipLandscape => _flipLandscape;
  void toggleFlipLandscape() {
    _flipLandscape = !_flipLandscape;
    notifyListeners();
    save();
  }

  Color get playerColor1 => _playerColor1;'''

assert old_prop in text, 'old_prop not found'
text = text.replace(old_prop, new_prop)

old_save = ''''levelCoinsCollected': _levelCoinsCollected,'''
new_save = ''''levelCoinsCollected': _levelCoinsCollected,
        'flipLandscape': _flipLandscape,'''

assert old_save in text, 'old_save not found'
text = text.replace(old_save, new_save)

old_load = '''        _totalPoints = data['totalPoints'] as int? ?? 0;'''
new_load = '''        _totalPoints = data['totalPoints'] as int? ?? 0;
        _flipLandscape = data['flipLandscape'] as bool? ?? false;'''

assert old_load in text, 'old_load not found'
text = text.replace(old_load, new_load)

with open('lib/data/game_storage.dart', 'w', encoding='utf-8', newline='\r\n') as f:
    f.write(text)
print('game_storage.dart patched!')

