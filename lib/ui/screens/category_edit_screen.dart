import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../core/theme.dart';
import '../widgets/app_snackbar.dart';

class CategoryEditScreen extends StatefulWidget {
  final Category? category; // null if creating new
  final Function(Category) onSave;

  const CategoryEditScreen({super.key, this.category, required this.onSave});

  @override
  State<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late Color _selectedColor;
  bool _isEmojiMode = false;

  final List<String> _standardIcons = [
    'restaurant', 'coffee', 'account_balance_wallet', 'directions_bus', 'shopping_bag',
    'home', 'school', 'medical_services', 'phone_android', 'sports_esports',
    'fitness_center', 'movie', 'flight', 'pets', 'category',
    'shopping_cart', 'local_gas_station', 'electric_bolt', 'celebration', 'theater_comedy',
    'brush', 'card_giftcard', 'vpn_key', 'lightbulb'
  ];

  final List<String> _standardEmojis = [
    '🎀', '🍕', '🍜', '🍣', '🍦', '🍩', '🍎', '🥦',
    '☕', '🍺', '🥤', '🍷', '🍼',
    '🚗', '🚌', '🚂', '✈️', '🚲', '🛴',
    '🏠', '🛒', '🛍️', '🎁', '🕯️', '🧸',
    '🎮', '🎬', '🎤', '🏀', '⚽', '🎨', '🎸', '📚',
    '💊', '🏥', '🦷', '🕶️', '🧴',
    '💼', '💻', '📱', '🔋', '📫', '📍',
    '🐶', '🐱', '🐹', '🐰', '🐥', '🦄',
    '💸', '💰', '💳', '💎', '🔑', '🔒',
    '🎉', '💖', '⭐', '🔥', '🌈', '☁️', '🍀', '✨',
  ];

  final List<Color> _standardColors = [
    // 1st Row: Warm colors
    Colors.red, Colors.redAccent, Colors.pink, Colors.pinkAccent, 
    Colors.deepOrange, Colors.deepOrangeAccent, Colors.orange, Colors.orangeAccent,
    Colors.amber, Colors.yellow, 
    // 2nd Row: Green & Teal
    Colors.lime, Colors.lightGreen, Colors.green, Colors.greenAccent, 
    Colors.teal, Colors.tealAccent, Colors.cyan, Colors.cyanAccent,
    // 3rd Row: Cool colors
    Colors.lightBlue, Colors.lightBlueAccent, Colors.blue, Colors.blueAccent,
    Colors.indigo, Colors.indigoAccent, Colors.purple, Colors.purpleAccent,
    Colors.deepPurple, Colors.deepPurpleAccent,
    // 4th Row: Natural & Neutral
    Colors.brown, Colors.grey, Colors.blueGrey, Colors.black87,
    Colors.white, Colors.transparent,
  ];

  bool _isColorManuallySelected = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? 'category';
    _selectedColor = widget.category?.color ?? _standardColors[0];
    if (widget.category != null) _isColorManuallySelected = true;
    
    // Check if current icon is an emoji
    _isEmojiMode = widget.category?.iconData == null && widget.category != null;
  }

  void _autoSelectColor(String name) {
    if (_isColorManuallySelected || name.isEmpty) return;
    setState(() {
      _selectedColor = _standardColors[name.length % _standardColors.length];
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.show(context, '카테고리 이름을 입력해주세요.');
      return;
    }

    final category = Category(
      id: widget.category?.id ?? '',
      name: name,
      icon: _selectedIcon,
      color: _selectedColor,
    );
    widget.onSave(category);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.category == null ? '카테고리 추가' : '카테고리 수정'),
          actions: [
            TextButton(
              onPressed: _save,
              child: const Text('저장', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _selectedColor == Colors.transparent ? Colors.grey.withOpacity(0.05) : _selectedColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == Colors.transparent ? Colors.grey.withOpacity(0.2) : _selectedColor.withOpacity(0.3), 
                          width: 2
                        ),
                      ),
                      child: Center(
                        child: _isEmoji(_selectedIcon)
                            ? Text(_selectedIcon, style: const TextStyle(fontSize: 40))
                            : Icon(_getIconData(_selectedIcon), color: _selectedColor, size: 40),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nameController.text.isEmpty ? '새 카테고리' : _nameController.text,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Name Input
              const Text('카테고리 이름', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '이동 통신, 운동 등',
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  _autoSelectColor(val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 32),
              
              // Icon Picker Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('아이콘 선택', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  TextButton.icon(
                    onPressed: () => setState(() => _isEmojiMode = !_isEmojiMode),
                    icon: Icon(_isEmojiMode ? Icons.grid_view : Icons.emoji_emotions_outlined),
                    label: Text(_isEmojiMode ? '기본 아이콘' : '이모지 선택'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (_isEmojiMode) 
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _standardEmojis.length,
                  itemBuilder: (context, index) {
                    final emoji = _standardEmojis[index];
                    final isSelected = _selectedIcon == emoji;
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = emoji),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? _selectedColor.withOpacity(0.2) : theme.colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: _selectedColor, width: 2) : null,
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    );
                  },
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _standardIcons.length,
                  itemBuilder: (context, index) {
                    final iconName = _standardIcons[index];
                    final isSelected = _selectedIcon == iconName;
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = iconName),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? _selectedColor.withValues(alpha: 0.2) : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: _selectedColor, width: 2) : null,
                        ),
                        child: Icon(_getIconData(iconName), color: isSelected ? _selectedColor : Colors.grey),
                      ),
                    );
                  },
                ),
              
              const SizedBox(height: 32),
              
              // Color Picker
              const Text('배경 색상', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _standardColors.map((color) {
                  final isSelected = _selectedColor.value == color.value;
                  return InkWell(
                    onTap: () => setState(() {
                      _selectedColor = color;
                      _isColorManuallySelected = true;
                    }),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color == Colors.transparent ? null : color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected 
                            ? theme.colorScheme.onSurface 
                            : (color == Colors.white || color == Colors.transparent ? theme.dividerColor : Colors.transparent), 
                          width: isSelected ? 2 : 1
                        ),
                        boxShadow: isSelected && color != Colors.transparent ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)] : null,
                      ),
                      child: color == Colors.transparent 
                        ? Icon(Icons.block, size: 20, color: isSelected ? theme.colorScheme.onSurface : Colors.grey)
                        : (isSelected ? Icon(Icons.check, color: color == Colors.white ? Colors.black : Colors.white, size: 20) : null),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  bool _isEmoji(String text) {
    if (text.isEmpty) return false;
    return !_standardIcons.contains(text);
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'restaurant': return Icons.restaurant;
      case 'coffee': return Icons.coffee;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'directions_bus': return Icons.directions_bus;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'home': return Icons.home;
      case 'school': return Icons.school;
      case 'medical_services': return Icons.medical_services;
      case 'phone_android': return Icons.phone_android;
      case 'sports_esports': return Icons.sports_esports;
      case 'fitness_center': return Icons.fitness_center;
      case 'movie': return Icons.movie;
      case 'flight': return Icons.flight_takeoff;
      case 'pets': return Icons.pets;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'electric_bolt': return Icons.electric_bolt;
      case 'celebration': return Icons.celebration;
      case 'theater_comedy': return Icons.theater_comedy;
      case 'brush': return Icons.brush;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'vpn_key': return Icons.vpn_key;
      case 'lightbulb': return Icons.lightbulb;
      case 'more_horiz':
      case 'more_horizontal': return Icons.more_horiz;
      case 'swap_horiz': return Icons.swap_horiz;
      case 'local_bar': return Icons.local_bar;
      case 'subscriptions': return Icons.subscriptions;
      case 'child_care': return Icons.child_care;
      case 'bolt': return Icons.bolt;
      case 'description': return Icons.description;
      default: return Icons.category;
    }
  }
}
