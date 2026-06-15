import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DebtAdvancedApp());
}

class DebtAdvancedApp extends StatelessWidget {
  const DebtAdvancedApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF316B83);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دفتر الديون المتقدم',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7F7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: const Color(0xFFFCFDFD),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Color(0xFFF4F7F7),
          foregroundColor: Color(0xFF172B31),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFCFDFD),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE0E8E8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9E4E4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9E4E4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: seed, width: 1.4),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: seed.withValues(alpha: 0.14),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: DebtHomeScreen(),
      ),
    );
  }
}

enum DebtAction { receivable, payable, receivedPayment, paidPayment }

extension DebtActionText on DebtAction {
  String get label {
    switch (this) {
      case DebtAction.receivable:
        return 'لي عنده';
      case DebtAction.payable:
        return 'علي له';
      case DebtAction.receivedPayment:
        return 'تسديد منه';
      case DebtAction.paidPayment:
        return 'تسديد مني';
    }
  }

  String get helper {
    switch (this) {
      case DebtAction.receivable:
        return 'أعطيته مبلغًا أو له دين عليك؟ لا، هذا يعني أنه مدين لك.';
      case DebtAction.payable:
        return 'أخذت منه مبلغًا أو أنت مدين له.';
      case DebtAction.receivedPayment:
        return 'دفع لك جزءًا من الدين.';
      case DebtAction.paidPayment:
        return 'دفعت له جزءًا مما عليك.';
    }
  }

  double signedAmount(double amount) {
    switch (this) {
      case DebtAction.receivable:
        return amount;
      case DebtAction.payable:
        return -amount;
      case DebtAction.receivedPayment:
        return -amount;
      case DebtAction.paidPayment:
        return amount;
    }
  }

  Color get color {
    switch (this) {
      case DebtAction.receivable:
        return const Color(0xFF2F7D68);
      case DebtAction.payable:
        return const Color(0xFFB9574F);
      case DebtAction.receivedPayment:
        return const Color(0xFF316B83);
      case DebtAction.paidPayment:
        return const Color(0xFF8A6A20);
    }
  }
}

class DebtEntry {
  const DebtEntry({
    required this.id,
    required this.person,
    required this.phone,
    required this.action,
    required this.amount,
    required this.date,
    required this.note,
  });

  final String id;
  final String person;
  final String phone;
  final DebtAction action;
  final double amount;
  final DateTime date;
  final String note;

  double get signedAmount => action.signedAmount(amount);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'person': person,
      'phone': phone,
      'action': action.name,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory DebtEntry.fromJson(Map<String, dynamic> map) {
    return DebtEntry(
      id: map['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      person: map['person'] as String? ?? 'بدون اسم',
      phone: map['phone'] as String? ?? '',
      action: DebtAction.values.firstWhere(
        (item) => item.name == map['action'],
        orElse: () => DebtAction.receivable,
      ),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      note: map['note'] as String? ?? '',
    );
  }
}

class PersonSummary {
  PersonSummary({
    required this.name,
    required this.phone,
    required this.balance,
    required this.count,
    required this.lastDate,
  });

  final String name;
  final String phone;
  final double balance;
  final int count;
  final DateTime lastDate;
}

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

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim()));
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
    return people.where((person) {
      return person.name.contains(_query) || person.phone.contains(_query);
    }).toList();
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

  double get _receivableTotal {
    return _allPeople.where((person) => person.balance > 0).fold(0, (sum, person) => sum + person.balance);
  }

  double get _payableTotal {
    return _allPeople.where((person) => person.balance < 0).fold(0, (sum, person) => sum + person.balance.abs());
  }

  double get _netTotal => _receivableTotal - _payableTotal;

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : IndexedStack(
            index: _tab,
            children: [
              _PeopleView(
                people: _people,
                searchController: _searchController,
                receivable: _receivableTotal,
                payable: _payableTotal,
                net: _netTotal,
                onOpenPerson: _openPerson,
                onAdd: _openEntrySheet,
                onCopyReminder: _copyReminder,
              ),
              _TimelineView(
                entries: _timeline,
                searchController: _searchController,
                onDelete: _deleteEntry,
                onOpenPerson: (name) {
                  final person = _allPeople.firstWhere((item) => item.name == name);
                  _openPerson(person);
                },
              ),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'دفتر الديون المتقدم',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0),
        ),
        actions: [
          IconButton(
            tooltip: 'إضافة عملية',
            onPressed: () => _openEntrySheet(),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(child: body),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntrySheet(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('عملية جديدة'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2_rounded),
            label: 'الأشخاص',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'العمليات',
          ),
        ],
      ),
    );
  }

  Future<void> _openEntrySheet({String? personName, String? phone}) async {
    final entry = await showModalBottomSheet<DebtEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EntrySheet(
        personName: personName,
        phone: phone,
      ),
    );
    if (entry == null) return;
    setState(() => _entries.add(entry));
    await _saveEntries();
  }

  Future<void> _deleteEntry(DebtEntry entry) async {
    setState(() => _entries.removeWhere((item) => item.id == entry.id));
    await _saveEntries();
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
    final text = _reminderText(person);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رسالة التذكير')),
    );
  }
}

class _PeopleView extends StatelessWidget {
  const _PeopleView({
    required this.people,
    required this.searchController,
    required this.receivable,
    required this.payable,
    required this.net,
    required this.onOpenPerson,
    required this.onAdd,
    required this.onCopyReminder,
  });

  final List<PersonSummary> people;
  final TextEditingController searchController;
  final double receivable;
  final double payable;
  final double net;
  final ValueChanged<PersonSummary> onOpenPerson;
  final void Function({String? personName, String? phone}) onAdd;
  final ValueChanged<PersonSummary> onCopyReminder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 92),
      children: [
        const Text(
          'الأرصدة الحالية',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF172B31)),
        ),
        const SizedBox(height: 6),
        const Text(
          'كل شخص يظهر مرة واحدة، والتفاصيل موجودة داخل كشف حسابه.',
          style: TextStyle(color: Color(0xFF62767C), height: 1.45),
        ),
        const SizedBox(height: 16),
        _NetPanel(net: net),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _AmountTile(title: 'لي عند الناس', amount: receivable, color: const Color(0xFF2F7D68))),
            const SizedBox(width: 8),
            Expanded(child: _AmountTile(title: 'علي للناس', amount: payable, color: const Color(0xFFB9574F))),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'بحث باسم الشخص أو رقم الهاتف',
          ),
        ),
        const SizedBox(height: 14),
        if (people.isEmpty)
          const _EmptyState(
            title: 'لا يوجد أشخاص بعد',
            subtitle: 'اضغط عملية جديدة وأضف أول دين أو تسديد.',
          )
        else
          ...people.map(
            (person) => _PersonTile(
              person: person,
              onOpen: () => onOpenPerson(person),
              onAdd: () => onAdd(personName: person.name, phone: person.phone),
              onCopyReminder: () => onCopyReminder(person),
            ),
          ),
      ],
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView({
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
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 92),
      children: [
        const Text(
          'كل العمليات',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF172B31)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'بحث في العمليات',
          ),
        ),
        const SizedBox(height: 14),
        if (entries.isEmpty)
          const _EmptyState(
            title: 'لا توجد عمليات',
            subtitle: 'أضف عملية دين أو تسديد لتظهر هنا.',
          )
        else
          ...entries.map(
            (entry) => _EntryTile(
              entry: entry,
              onDelete: () => onDelete(entry),
              onOpenPerson: () => onOpenPerson(entry.person),
            ),
          ),
      ],
    );
  }
}

class PersonDetailsScreen extends StatelessWidget {
  const PersonDetailsScreen({
    super.key,
    required this.person,
    required this.entries,
    required this.onAdd,
    required this.onDelete,
    required this.onCopyReminder,
  });

  final PersonSummary person;
  final List<DebtEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<DebtEntry> onDelete;
  final VoidCallback onCopyReminder;

  @override
  Widget build(BuildContext context) {
    final running = <_LedgerLine>[];
    double balance = 0;
    final chronological = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    for (final entry in chronological) {
      balance += entry.signedAmount;
      running.add(_LedgerLine(entry: entry, balance: balance));
    }
    final visible = running.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'نسخ تذكير',
            onPressed: onCopyReminder,
            icon: const Icon(Icons.content_copy_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
        children: [
          _PersonBalancePanel(person: person),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة عملية'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopyReminder,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('نسخ تذكير'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'كشف الحساب',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF172B31)),
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            const _EmptyState(
              title: 'لا توجد تفاصيل',
              subtitle: 'أضف أول عملية لهذا الشخص.',
            )
          else
            ...visible.map(
              (line) => _LedgerTile(
                line: line,
                onDelete: () => onDelete(line.entry),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('عملية'),
      ),
    );
  }
}

class _EntrySheet extends StatefulWidget {
  const _EntrySheet({
    this.personName,
    this.phone,
  });

  final String? personName;
  final String? phone;

  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DebtAction _action = DebtAction.receivable;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _personController.text = widget.personName ?? '';
    _phoneController.text = widget.phone ?? '';
  }

  @override
  void dispose() {
    _personController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFDFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E8E8)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'عملية جديدة',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _personController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'اسم الشخص'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'اكتب اسم الشخص';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف اختياري'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<DebtAction>(
                  initialValue: _action,
                  decoration: const InputDecoration(labelText: 'نوع العملية'),
                  items: DebtAction.values
                      .map((action) => DropdownMenuItem(value: action, child: Text(action.label)))
                      .toList(),
                  onChanged: (value) => setState(() => _action = value ?? _action),
                ),
                const SizedBox(height: 8),
                Text(
                  _action.helper,
                  style: const TextStyle(color: Color(0xFF62767C), fontSize: 12, height: 1.45),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: const InputDecoration(labelText: 'المبلغ', suffixText: 'د.أ'),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) return 'اكتب مبلغًا صحيحًا';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text('التاريخ: ${formatDate(_date)}'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'ملاحظة اختيارية'),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('حفظ العملية'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final entry = DebtEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      person: _personController.text.trim(),
      phone: _phoneController.text.trim(),
      action: _action,
      amount: double.parse(_amountController.text),
      date: _date,
      note: _noteController.text.trim(),
    );
    Navigator.pop(context, entry);
  }
}

class _NetPanel extends StatelessWidget {
  const _NetPanel({required this.net});

  final double net;

  @override
  Widget build(BuildContext context) {
    final positive = net >= 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF182F36),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الصافي',
            style: TextStyle(color: Color(0xFFC2D5DA), fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            formatMoney(net),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            positive ? 'إجمالي ما لك أعلى من ما عليك.' : 'إجمالي ما عليك أعلى من ما لك.',
            style: TextStyle(color: positive ? const Color(0xFFBFE8D8) : const Color(0xFFFFD7D2)),
          ),
        ],
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF62767C), fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              formatMoney(amount),
              style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
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
    final status = person.balance == 0 ? 'مسدد' : (positive ? 'لي عنده' : 'علي له');
    final color = person.balance == 0
        ? const Color(0xFF62767C)
        : positive
            ? const Color(0xFF2F7D68)
            : const Color(0xFFB9574F);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Text(person.name.characters.first),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF172B31)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$status · ${person.count} عملية · آخر حركة ${formatDate(person.lastDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF62767C), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(person.balance.abs()),
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'عملية',
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded, size: 20),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'نسخ تذكير',
                        onPressed: onCopyReminder,
                        icon: const Icon(Icons.copy_rounded, size: 19),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.onDelete,
    required this.onOpenPerson,
  });

  final DebtEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onOpenPerson;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: entry.action.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_iconFor(entry.action), color: entry.action.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: onOpenPerson,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.person,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF172B31)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.action.label} · ${formatDate(entry.date)}',
                      style: const TextStyle(color: Color(0xFF62767C), fontSize: 12),
                    ),
                    if (entry.note.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF7B8B90), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(entry.amount),
                  style: TextStyle(color: entry.action.color, fontWeight: FontWeight.w900),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'حذف',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonBalancePanel extends StatelessWidget {
  const _PersonBalancePanel({required this.person});

  final PersonSummary person;

  @override
  Widget build(BuildContext context) {
    final positive = person.balance >= 0;
    final zero = person.balance == 0;
    final title = zero ? 'الحساب مسدد' : (positive ? 'لي عنده' : 'علي له');
    final color = zero
        ? const Color(0xFF62767C)
        : positive
            ? const Color(0xFF2F7D68)
            : const Color(0xFFB9574F);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF182F36),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFFC2D5DA), fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            formatMoney(person.balance.abs()),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${person.count} عملية محفوظة لهذا الشخص',
                  style: const TextStyle(color: Color(0xFFC2D5DA)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerLine {
  const _LedgerLine({
    required this.entry,
    required this.balance,
  });

  final DebtEntry entry;
  final double balance;
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({
    required this.line,
    required this.onDelete,
  });

  final _LedgerLine line;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final entry = line.entry;
    final balanceColor = line.balance >= 0 ? const Color(0xFF2F7D68) : const Color(0xFFB9574F);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.action.label,
                    style: TextStyle(fontWeight: FontWeight.w900, color: entry.action.color),
                  ),
                ),
                Text(formatDate(entry.date), style: const TextStyle(color: Color(0xFF62767C), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _SmallLedgerValue(title: 'المبلغ', value: formatMoney(entry.amount))),
                Expanded(
                  child: _SmallLedgerValue(
                    title: 'الرصيد بعد العملية',
                    value: formatMoney(line.balance.abs()),
                    color: balanceColor,
                  ),
                ),
              ],
            ),
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(entry.note, style: const TextStyle(color: Color(0xFF62767C))),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('حذف'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallLedgerValue extends StatelessWidget {
  const _SmallLedgerValue({
    required this.title,
    required this.value,
    this.color,
  });

  final String title;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF7B8B90), fontSize: 12)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(color: color ?? const Color(0xFF172B31), fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 34, color: Color(0xFF809197)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF62767C), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(DebtAction action) {
  switch (action) {
    case DebtAction.receivable:
      return Icons.south_west_rounded;
    case DebtAction.payable:
      return Icons.north_east_rounded;
    case DebtAction.receivedPayment:
      return Icons.payments_rounded;
    case DebtAction.paidPayment:
      return Icons.outbox_rounded;
  }
}

String _reminderText(PersonSummary person) {
  if (person.balance == 0) {
    return 'مرحبًا ${person.name}، حسابنا مسدد ولا يوجد مبلغ قائم. شكرًا لك.';
  }
  if (person.balance > 0) {
    return 'مرحبًا ${person.name}، للتذكير يوجد مبلغ ${formatMoney(person.balance)} مستحق لي. شكرًا لك.';
  }
  return 'مرحبًا ${person.name}، للتذكير يوجد مبلغ ${formatMoney(person.balance.abs())} مستحق لك علي. شكرًا لك.';
}

String formatMoney(double value) {
  final sign = value < 0 ? '-' : '';
  final absValue = value.abs();
  final number = absValue == absValue.roundToDouble()
      ? absValue.toStringAsFixed(0)
      : absValue.toStringAsFixed(2);
  return '$sign$number د.أ';
}

String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
