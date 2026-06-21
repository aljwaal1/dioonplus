import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'entry_sheet.dart';
import 'models.dart';
import 'person_details_screen.dart';
import 'sound_service.dart';
import 'widgets.dart';

class DebtHomeScreen extends StatefulWidget {
  const DebtHomeScreen({super.key});

  @override
  State<DebtHomeScreen> createState() => _DebtHomeScreenState();
}

class _DebtHomeScreenState extends State<DebtHomeScreen> {
  static const _storageKey = 'debt_advanced_entries_v1';

  final List<DebtEntry> _entries = [];
  final _searchController = TextEditingController();
  int _tab = 0;
  bool _loading = true;
  String _query = '';
  bool _soundOn = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim()));
  }

  Future<void> _bootstrap() async {
    await SoundService.instance.init();
    _soundOn = SoundService.instance.enabled;
    await _loadEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null && saved.isNotEmpty) {
      final decoded = jsonDecode(saved) as List<dynamic>;
      _entries
        ..clear()
        ..addAll(decoded.map((item) => DebtEntry.fromJson(item as Map<String, dynamic>)));
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_entries.map((item) => item.toJson()).toList()));
  }

  List<PersonSummary> get _allPeople {
    final map = <String, List<DebtEntry>>{};
    for (final entry in _entries) {
      map.putIfAbsent(entry.person, () => []).add(entry);
    }
    final people = map.entries.map((group) {
      final list = group.value;
      list.sort((a, b) => b.date.compareTo(a.date));
      final balance = list.fold<double>(0, (sum, entry) => sum + entry.signedAmount);
      final phone = list.firstWhere((entry) => entry.phone.trim().isNotEmpty, orElse: () => list.first).phone;
      return PersonSummary(
        name: group.key,
        phone: phone,
        balance: balance,
        count: list.length,
        lastDate: list.first.date,
      );
    }).toList();
    people.sort((a, b) => b.lastDate.compareTo(a.lastDate));
    return people;
  }

  List<PersonSummary> get _people {
    final people = _allPeople;
    if (_query.isEmpty) return people;
    return people.where((person) => person.name.contains(_query) || person.phone.contains(_query)).toList();
  }

  List<DebtEntry> get _timeline {
    final list = [..._entries]..sort((a, b) => b.date.compareTo(a.date));
    if (_query.isEmpty) return list;
    return list.where((entry) {
      return entry.person.contains(_query) ||
          entry.phone.contains(_query) ||
          entry.note.contains(_query) ||
          entry.action.label.contains(_query);
    }).toList();
  }

  double get _receivableTotal =>
      _allPeople.where((p) => p.balance > 0).fold(0, (sum, p) => sum + p.balance);

  double get _payableTotal =>
      _allPeople.where((p) => p.balance < 0).fold(0, (sum, p) => sum + p.balance.abs());

  double get _netTotal => _receivableTotal - _payableTotal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _TopHeader(
            tab: _tab,
            net: _netTotal,
            receivable: _receivableTotal,
            payable: _payableTotal,
            soundOn: _soundOn,
            onToggleSound: _toggleSound,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : IndexedStack(
                      index: _tab,
                      children: [
                        _PeopleListBody(
                          people: _people,
                          searchController: _searchController,
                          onOpenPerson: _openPerson,
                          onAdd: _openEntrySheet,
                          onCopyReminder: _copyReminder,
                        ),
                        _TimelineListBody(
                          entries: _timeline,
                          searchController: _searchController,
                          onDelete: _deleteEntry,
                          onOpenPerson: (name) {
                            final person = _allPeople.firstWhere((item) => item.name == name);
                            _openPerson(person);
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: _GoldFab(onPressed: () => _openEntrySheet()),
      ),
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: _tab,
        onSelected: (index) {
          SoundService.instance.tap();
          setState(() => _tab = index);
        },
      ),
    );
  }

  Future<void> _toggleSound() async {
    final next = !_soundOn;
    await SoundService.instance.setEnabled(next);
    setState(() => _soundOn = next);
    if (next) SoundService.instance.tap();
  }

  Future<void> _openEntrySheet({String? personName, String? phone}) async {
    final entry = await showModalBottomSheet<DebtEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EntrySheet(personName: personName, phone: phone),
    );
    if (entry == null) return;
    setState(() => _entries.add(entry));
    await _saveEntries();
  }

  Future<void> _deleteEntry(DebtEntry entry) async {
    final confirmed = await _confirmDeleteEntry(entry);
    if (!confirmed) return;

    await SoundService.instance.remove();
    setState(() => _entries.removeWhere((item) => item.id == entry.id));
    await _saveEntries();
  }

  Future<bool> _confirmDeleteEntry(DebtEntry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تأكيد الحذف',
          textAlign: TextAlign.right,
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'هل أنت متأكد من حذف عملية ${entry.person} بمبلغ ${formatMoney(entry.amount)}؟',
          textAlign: TextAlign.right,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('حذف'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _openPerson(PersonSummary person) {
    final entries = _entries.where((entry) => entry.person == person.name).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: PersonDetailsScreen(
            person: person,
            entries: entries,
            onAdd: () => _openEntrySheet(personName: person.name, phone: person.phone),
            onDelete: _deleteEntry,
            onCopyReminder: () => _copyReminder(person),
          ),
        ),
      ),
    );
  }

  Future<void> _copyReminder(PersonSummary person) async {
    final text = reminderText(person);
    await Clipboard.setData(ClipboardData(text: text));
    SoundService.instance.tap();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.goldLight, size: 18),
            SizedBox(width: 8),
            Text('تم نسخ رسالة التذكير'),
          ],
        ),
      ),
    );
  }
}

/// Hero header: dark navy/teal gradient with rounded bottom corners,
/// containing the app identity, a sound toggle, and the live balance
/// summary as frosted-glass chips.
class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.tab,
    required this.net,
    required this.receivable,
    required this.payable,
    required this.soundOn,
    required this.onToggleSound,
  });

  final int tab;
  final double net;
  final double receivable;
  final double payable;
  final bool soundOn;
  final VoidCallback onToggleSound;

  @override
  Widget build(BuildContext context) {
    final positive = net >= 0;
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      child: Container(
        decoration: BoxDecoration(gradient: AppGradients.header, boxShadow: AppShadows.header),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: AppShadows.gold,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.navyDark, size: 21),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'دفتر الديون',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          Text(
                            'إدارة الديون والتسديدات باحترافية',
                            style: TextStyle(color: Color(0xFFAFC8CC), fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    _HeaderIconButton(
                      icon: soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      onPressed: onToggleSound,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  tab == 0 ? 'الصافي الإجمالي' : 'سجل كل العمليات',
                  style: const TextStyle(color: Color(0xFFAFC8CC), fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                const SizedBox(height: 6),
                Text(
                  formatMoney(net),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: positive ? AppColors.goldLight : const Color(0xFFFFA89E)),
                    const SizedBox(width: 6),
                    Text(
                      positive ? 'إجمالي ما لك أعلى من ما عليك' : 'إجمالي ما عليك أعلى من ما لك',
                      style: const TextStyle(color: Color(0xFFC2D5DA), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _GlassChip(
                        title: 'لي عند الناس',
                        value: receivable,
                        icon: Icons.south_west_rounded,
                        tint: AppColors.goldLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GlassChip(
                        title: 'علي للناس',
                        value: payable,
                        icon: Icons.north_east_rounded,
                        tint: const Color(0xFFFFC1B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.title, required this.value, required this.icon, required this.tint});

  final String title;
  final double value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: tint),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFFC2D5DA), fontSize: 11, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            formatMoney(value),
            style: TextStyle(color: tint, fontWeight: FontWeight.w900, fontSize: 15.5),
          ),
        ],
      ),
    );
  }
}

class _GoldFab extends StatelessWidget {
  const _GoldFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        SoundService.instance.tap();
        onPressed();
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          gradient: AppGradients.gold,
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppShadows.gold,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: AppColors.navyDark),
            SizedBox(width: 6),
            Text('عملية جديدة', style: TextStyle(color: AppColors.navyDark, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

/// Floating pill-shaped bottom navigation bar replacing the stock
/// Material NavigationBar for a softer, premium silhouette.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.groups_2_outlined, Icons.groups_2_rounded, 'الأشخاص'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'العمليات'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppShadows.floating,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = index == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.navy : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.$2 : item.$1,
                          size: 20,
                          color: selected ? AppColors.goldLight : AppColors.textFaint,
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.$3,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _PeopleListBody extends StatelessWidget {
  const _PeopleListBody({
    required this.people,
    required this.searchController,
    required this.onOpenPerson,
    required this.onAdd,
    required this.onCopyReminder,
  });

  final List<PersonSummary> people;
  final TextEditingController searchController;
  final ValueChanged<PersonSummary> onOpenPerson;
  final void Function({String? personName, String? phone}) onAdd;
  final ValueChanged<PersonSummary> onCopyReminder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        PillSearchField(controller: searchController, label: 'بحث باسم الشخص أو رقم الهاتف'),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'الأشخاص',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            const Spacer(),
            StatusBadge(label: '${people.length} شخص', color: AppColors.teal),
          ],
        ),
        const SizedBox(height: 12),
        if (people.isEmpty)
          const EmptyState(
            title: 'لا يوجد أشخاص بعد',
            subtitle: 'اضغط زر "عملية جديدة" وأضف أول دين أو تسديد.',
            icon: Icons.groups_2_outlined,
          )
        else
          ...List.generate(people.length, (index) {
            final person = people[index];
            return FadeInUp(
              delayMs: index * 25,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PersonTile(
                  person: person,
                  onOpen: () => onOpenPerson(person),
                  onAdd: () => onAdd(personName: person.name, phone: person.phone),
                  onCopyReminder: () => onCopyReminder(person),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _TimelineListBody extends StatelessWidget {
  const _TimelineListBody({
    required this.entries,
    required this.searchController,
    required this.onDelete,
    required this.onOpenPerson,
  });

  final List<DebtEntry> entries;
  final TextEditingController searchController;
  final ValueChanged<DebtEntry> onDelete;
  final ValueChanged<String> onOpenPerson;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        PillSearchField(controller: searchController, label: 'بحث في العمليات'),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'كل العمليات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            const Spacer(),
            StatusBadge(label: '${entries.length} عملية', color: AppColors.teal),
          ],
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const EmptyState(
            title: 'لا توجد عمليات',
            subtitle: 'أضف عملية دين أو تسديد لتظهر هنا.',
            icon: Icons.receipt_long_outlined,
          )
        else
          ...List.generate(entries.length, (index) {
            final entry = entries[index];
            return FadeInUp(
              delayMs: index * 20,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EntryTile(
                  entry: entry,
                  onDelete: () => onDelete(entry),
                  onOpenPerson: () => onOpenPerson(entry.person),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.person,
    required this.onOpen,
    required this.onAdd,
    required this.onCopyReminder,
  });

  final PersonSummary person;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final VoidCallback onCopyReminder;

  @override
  Widget build(BuildContext context) {
    final positive = person.balance >= 0;
    final zero = person.balance == 0;
    final status = zero ? 'مسدد' : (positive ? 'لي عنده' : 'علي له');
    final color = zero ? AppColors.textFaint : (positive ? AppColors.success : AppColors.danger);
    return PremiumCard(
      onTap: onOpen,
      accentColor: color,
      child: Row(
        children: [
          GradientAvatar(letter: person.name.characters.first),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontSize: 15),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    StatusBadge(label: status, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${person.count} عملية · آخر حركة ${formatDate(person.lastDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(person.balance.abs()),
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14.5),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniIconButton(icon: Icons.add_rounded, onTap: onAdd, tooltip: 'عملية'),
                  const SizedBox(width: 2),
                  _MiniIconButton(icon: Icons.copy_rounded, onTap: onCopyReminder, tooltip: 'نسخ تذكير'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({required this.icon, required this.onTap, required this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          SoundService.instance.tap();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 17, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onDelete, required this.onOpenPerson});

  final DebtEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onOpenPerson;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accentColor: entry.action.color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onOpenPerson,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: entry.action.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(entry.action.icon, color: entry.action.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.person,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontSize: 14.5),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.action.label} · ${formatDate(entry.date)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(entry.amount),
                style: TextStyle(color: entry.action.color, fontWeight: FontWeight.w900, fontSize: 14),
              ),
              _MiniIconButton(icon: Icons.delete_outline_rounded, onTap: onDelete, tooltip: 'حذف'),
            ],
          ),
        ],
      ),
    );
  }
}
