import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../data/repositories/log_repository.dart';
import '../../domain/models/activity_log.dart';
import '../providers/providers.dart';

/// Searchable / filterable timeline of every check-in, with edit & delete.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  DateTimeRange? _range;
  List<ActivityLog>? _results;
  bool _loading = false;

  final _logRepo = LogRepository();
  final _dateFmt = DateFormat('MMM d, y  h:mm a');

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  Future<void> _runSearch() async {
    setState(() => _loading = true);
    final results = await _logRepo.search(
      query: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      start: _range?.start,
      end: _range?.end,
    );
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search notes or activity name',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: _pickRange,
                    ),
                  ),
                  onSubmitted: (_) => _runSearch(),
                ),
                if (_range != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${_dateFmt.format(_range!.start)} – ${_dateFmt.format(_range!.end)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() => _range = null);
                            _runSearch();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_results == null || _results!.isEmpty)
                    ? const Center(child: Text('No check-ins found'))
                    : ListView.builder(
                        itemCount: _results!.length,
                        itemBuilder: (context, index) {
                          final log = _results![index];
                          return _LogTile(
                            log: log,
                            dateFmt: _dateFmt,
                            onEdit: () => _editLog(log),
                            onDelete: () => _deleteLog(log),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = picked);
      _runSearch();
    }
  }

  Future<void> _deleteLog(ActivityLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await _logRepo.delete(log.id);
      ref.invalidate(recentLogsProvider);
      _runSearch();
    }
  }

  Future<void> _editLog(ActivityLog log) async {
    final notesController = TextEditingController(text: log.notes ?? '');
    final scoreController = TextEditingController(text: '${log.score}');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit entry', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: scoreController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(labelText: 'Score'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      final newScore = int.tryParse(scoreController.text.trim()) ?? log.score;
      await _logRepo.update(log.copyWith(
        score: newScore,
        notes: notesController.text.trim(),
      ));
      _runSearch();
    }
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.log,
    required this.dateFmt,
    required this.onEdit,
    required this.onDelete,
  });

  final ActivityLog log;
  final DateFormat dateFmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _typeColor() {
    switch (log.type) {
      case ActivityType.good:
        return const Color(0xFF2E7D32);
      case ActivityType.bad:
        return const Color(0xFFC62828);
      case ActivityType.neutral:
        return const Color(0xFF616161);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _typeColor().withOpacity(0.15),
        child: Text(
          log.score >= 0 ? '+${log.score}' : '${log.score}',
          style: TextStyle(color: _typeColor(), fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      title: Text(log.customName ?? '(Saved activity)'),
      subtitle: Text(
        [dateFmt.format(log.timestamp), if ((log.notes ?? '').isNotEmpty) log.notes]
            .join(' · '),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}
