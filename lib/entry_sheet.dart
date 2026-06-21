import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'models.dart';
import 'sound_service.dart';
import 'widgets.dart';

class EntrySheet extends StatefulWidget {
  const EntrySheet({super.key, this.personName, this.phone});

  final String? personName;
  final String? phone;

  @override
  State<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<EntrySheet> {
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
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: EdgeInsets.fromLTRB(18, 12, 18, bottom + 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.floating,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.navyDark, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'عملية جديدة',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _personController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'اسم الشخص',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'اكتب اسم الشخص';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف (اختياري)',
                    prefixIcon: Icon(Icons.call_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'نوع العملية',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _ActionGrid(
                  selected: _action,
                  onSelected: (action) {
                    HapticFeedback.selectionClick();
                    setState(() => _action = action);
                  },
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: ValueKey(_action),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _action.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: _action.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _action.helper,
                            style: TextStyle(color: _action.color, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    suffixText: 'د.أ',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) return 'اكتب مبلغًا صحيحًا';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined, size: 19),
                  label: Text('التاريخ: ${formatDate(_date)}'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة (اختياري)',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                GoldButton(label: 'حفظ العملية', icon: Icons.check_circle_outline_rounded, onPressed: _submit),
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.teal),
        ),
        child: child!,
      ),
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
    SoundService.instance.success();
    Navigator.pop(context, entry);
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.selected, required this.onSelected});

  final DebtAction selected;
  final ValueChanged<DebtAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DebtAction.values.map((action) {
        final isSelected = action == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onSelected(action),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? action.color : action.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? action.color : action.color.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: action.color.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(action.icon, size: 18, color: isSelected ? Colors.white : action.color),
                    const SizedBox(height: 4),
                    Text(
                      action.shortLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : action.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
