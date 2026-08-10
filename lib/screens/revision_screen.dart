import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bom_provider.dart';

class RevisionScreen extends ConsumerStatefulWidget {
  const RevisionScreen({super.key});

  @override
  ConsumerState<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends ConsumerState<RevisionScreen> {
  final TextEditingController _notesController = TextEditingController();
  final List<String> _snapshots = [];

  void _saveSnapshot() {
    final count = ref.read(bomProvider).length;
    setState(() {
      _snapshots.add('Snapshot #${_snapshots.length + 1} - Total $count BOM rows (${DateTime.now().toString().split('.')[0]})');
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revision Snapshot saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🔄 Revision Snapshots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _saveSnapshot,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Save Snapshot'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: _snapshots.isEmpty
                ? const Center(child: Text('No snapshots saved yet.'))
                : ListView.builder(
              itemCount: _snapshots.length,
              itemBuilder: (context, i) => Card(child: ListTile(title: Text(_snapshots[i]))),
            ),
          ),
          const Divider(height: 32),
          const Text('📝 Project Site Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Write site remarks, client comments, or pending inspection points here...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}