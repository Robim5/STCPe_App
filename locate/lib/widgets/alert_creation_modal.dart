import 'package:flutter/material.dart';
import '../models/arrival_alert.dart';

// shows a full-screen modal to create or edit an arrival alert.
/// returns the [ArrivalAlert] if the user saves, or null if cancelled.
Future<ArrivalAlert?> showAlertCreationModal(
  BuildContext context, {
  ArrivalAlert? existing,
  required List<String> metroLines,
  required Map<String, List<String>> metroStopsByLine,
  required Map<String, List<String>> metroDirectionsByLine,
}) {
  return showModalBottomSheet<ArrivalAlert>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AlertCreationSheet(
      existing: existing,
      metroLines: metroLines,
      metroStopsByLine: metroStopsByLine,
      metroDirectionsByLine: metroDirectionsByLine,
    ),
  );
}

class _AlertCreationSheet extends StatefulWidget {
  final ArrivalAlert? existing;
  final List<String> metroLines;
  final Map<String, List<String>> metroStopsByLine;
  final Map<String, List<String>> metroDirectionsByLine;

  const _AlertCreationSheet({
    this.existing,
    required this.metroLines,
    required this.metroStopsByLine,
    required this.metroDirectionsByLine,
  });

  @override
  State<_AlertCreationSheet> createState() => _AlertCreationSheetState();
}

class _AlertCreationSheetState extends State<_AlertCreationSheet> {
  late String _type; // 'stcp' or 'metro'
  String _stopName = '';
  String? _direction;
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);

  // metro specific
  String? _selectedMetroLine;

  final _stopController = TextEditingController();
  final _lineController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _type = e.type;
      _stopName = e.stopName;
      _stopController.text = e.stopName;
      _lineController.text = e.lineNumber ?? '';
      _direction = e.direction;
      _startTime = _parseTime(e.startTime);
      _endTime = _parseTime(e.endTime);
      if (_type == 'metro' && e.lineNumber != null) {
        _selectedMetroLine = e.lineNumber;
      }
    } else {
      _type = 'stcp';
    }
  }

  @override
  void dispose() {
    _stopController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() {
    if (_stopName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleciona uma paragem.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final alert = ArrivalAlert(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type,
      stopName: _stopName,
      lineNumber: _type == 'metro'
          ? _selectedMetroLine
          : (_lineController.text.trim().isNotEmpty
              ? _lineController.text.trim()
              : null),
      direction: _direction,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
    );
    Navigator.pop(context, alert);
  }

  // build metro-specific stop options
  List<String> get _metroStops {
    if (_selectedMetroLine == null) return [];
    return widget.metroStopsByLine[_selectedMetroLine] ?? [];
  }

  List<String> get _metroDirections {
    if (_selectedMetroLine == null) return [];
    return widget.metroDirectionsByLine[_selectedMetroLine] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existing != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(51),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditing ? 'Editar Aviso' : 'Novo Aviso de Chegada',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),

            // type selector
            Row(
              children: [
                Expanded(
                  child: _TypeChip(
                    label: 'STCP',
                    icon: Icons.directions_bus_rounded,
                    selected: _type == 'stcp',
                    onTap: () => setState(() {
                      _type = 'stcp';
                      _selectedMetroLine = null;
                      _direction = null;
                      _stopName = '';
                      _stopController.clear();
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeChip(
                    label: 'Metro',
                    icon: Icons.subway_rounded,
                    selected: _type == 'metro',
                    onTap: () => setState(() {
                      _type = 'metro';
                      _stopName = '';
                      _stopController.clear();
                      _lineController.clear();
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // metro line selector
            if (_type == 'metro') ...[
              _SectionLabel('Linha (opcional)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.metroLines.map((line) {
                  final selected = _selectedMetroLine == line;
                  return ChoiceChip(
                    label: Text('Linha $line'),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        _selectedMetroLine = v ? line : null;
                        _direction = null;
                        _stopName = '';
                        _stopController.clear();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // direction dropdown
              if (_selectedMetroLine != null && _metroDirections.isNotEmpty) ...[
                _SectionLabel('Direção (opcional)'),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _direction,
                  hint: 'Selecionar direção',
                  items: _metroDirections,
                  onChanged: (v) => setState(() => _direction = v),
                ),
                const SizedBox(height: 16),
              ],

              // stop dropdown
              _SectionLabel('Paragem'),
              const SizedBox(height: 8),
              if (_selectedMetroLine != null && _metroStops.isNotEmpty)
                _buildDropdown(
                  value: _stopName.isNotEmpty ? _stopName : null,
                  hint: 'Selecionar paragem',
                  items: _metroStops,
                  onChanged: (v) {
                    setState(() => _stopName = v ?? '');
                  },
                )
              else
                TextField(
                  controller: _stopController,
                  decoration: _inputDecoration('Nome da paragem'),
                  onChanged: (v) => _stopName = v,
                ),
              const SizedBox(height: 16),
            ],

            // stcp stop and line inputs
            if (_type == 'stcp') ...[
              _SectionLabel('Paragem'),
              const SizedBox(height: 8),
              TextField(
                controller: _stopController,
                decoration: _inputDecoration('Nome da paragem'),
                onChanged: (v) => _stopName = v,
              ),
              const SizedBox(height: 16),

              _SectionLabel('Número da linha (opcional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _lineController,
                decoration: _inputDecoration('Ex: 600'),
              ),
              const SizedBox(height: 16),

              _SectionLabel('Direção (opcional)'),
              const SizedBox(height: 8),
              TextField(
                decoration: _inputDecoration('Ex: Barca'),
                onChanged: (v) =>
                    setState(() => _direction = v.isEmpty ? null : v),
              ),
              const SizedBox(height: 16),
            ],

            // time range
            _SectionLabel('Intervalo de horário'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Das',
                    time: _formatTime(_startTime),
                    onTap: () => _pickTime(true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface.withAlpha(120)),
                ),
                Expanded(
                  child: _TimePicker(
                    label: 'Às',
                    time: _formatTime(_endTime),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(60)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(60)),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(60)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          hint: Text(hint),
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? null
              : Border.all(color: theme.colorScheme.outline.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
