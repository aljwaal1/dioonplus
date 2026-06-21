import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'models.dart';
import 'sound_service.dart';
import 'widgets.dart';

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
    final running = <LedgerLine>[];
    double balance = 0;
    final chronological = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    for (final entry in chronological) {
      balance += entry.signedAmount;
      running.add(LedgerLine(entry: entry, balance: balance));
    }
    final visible = running.reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _PersonHeader(person: person, onCopyReminder: onCopyReminder),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Row(
                    children: [
                      Expanded(child: GoldButton(label: 'إضافة عملية', icon: Icons.add_rounded, onPressed: onAdd)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            SoundService.instance.tap();
                            onCopyReminder();
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('نسخ تذكير'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Text(
                        'كشف الحساب',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      StatusBadge(label: '${visible.length} عملية', color: AppColors.teal),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    const EmptyState(
                      title: 'لا توجد تفاصيل',
                      subtitle: 'أضف أول عملية لهذا الشخص.',
                      icon: Icons.fact_check_outlined,
                    )
                  else
                    ...List.generate(visible.length, (index) {
                      return FadeInUp(
                        delayMs: index * 25,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LedgerTile(line: visible[index], onDelete: () => onDelete(visible[index].entry)),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonHeader extends StatelessWidget {
  const _PersonHeader({required this.person, required this.onCopyReminder});

  final PersonSummary person;
  final VoidCallback onCopyReminder;

  @override
  Widget build(BuildContext context) {
    final positive = person.balance >= 0;
    final zero = person.balance == 0;
    final title = zero ? 'الحساب مسدد' : (positive ? 'لي عنده' : 'علي له');
    final tint = zero ? const Color(0xFFC2D5DA) : (positive ? AppColors.goldLight : const Color(0xFFFFC1B8));

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      child: Container(
        decoration: BoxDecoration(gradient: AppGradients.header, boxShadow: AppShadows.header),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        person.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                      ),
                    ),
                    IconButton(
                      tooltip: 'نسخ تذكير',
                      onPressed: () {
                        SoundService.instance.tap();
                        onCopyReminder();
                      },
                      icon: const Icon(Icons.content_copy_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Color(0xFFAFC8CC), fontWeight: FontWeight.w700, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      Text(
                        formatMoney(person.balance.abs()),
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: tint),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${person.count} عملية محفوظة · آخر حركة ${formatDateLong(person.lastDate)}',
                              style: const TextStyle(color: Color(0xFFC2D5DA), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.line, required this.onDelete});

  final LedgerLine line;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final entry = line.entry;
    final balanceColor = line.balance >= 0 ? AppColors.success : AppColors.danger;
    return PremiumCard(
      accentColor: entry.action.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: entry.action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(entry.action.icon, size: 17, color: entry.action.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.action.label,
                  style: TextStyle(fontWeight: FontWeight.w900, color: entry.action.color, fontSize: 13.5),
                ),
              ),
              Text(formatDate(entry.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10)),
              child: Text(entry.note, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                SoundService.instance.remove();
                onDelete();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              label: const Text('حذف'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallLedgerValue extends StatelessWidget {
  const _SmallLedgerValue({required this.title, required this.value, this.color});

  final String title;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textFaint, fontSize: 11.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: color ?? AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 14.5)),
      ],
    );
  }
}
