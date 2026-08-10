import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/spool_provider.dart';

class SpoolTrackerScreen extends ConsumerWidget {
  const SpoolTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spools = ref.watch(spoolProvider);

    final dispatched =
        spools.where((s) => s.dispatchStatus == 'Dispatched').length;

    final inProgress =
        spools.where((s) => s.dispatchStatus == 'In Progress').length;

    final pending =
        spools.where((s) => s.dispatchStatus == 'Pending').length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _metricChip(
                'Total Spools',
                spools.length.toString(),
                Colors.blue,
              ),

              const SizedBox(width: 8),

              _metricChip(
                'Dispatched',
                dispatched.toString(),
                Colors.green,
              ),

              const SizedBox(width: 8),

              _metricChip(
                'In Progress',
                inProgress.toString(),
                Colors.orange,
              ),

              const SizedBox(width: 8),

              _metricChip(
                'Pending',
                pending.toString(),
                Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 16),

        //spool card
          Expanded(
            child: spools.isEmpty
                ? const Center(
              child: Text('No spools available.'),
            )
                : GridView.builder(
              gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,

                // Increased height to prevent overflow
                mainAxisExtent: 260,

                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),

              itemCount: spools.length,

              itemBuilder: (context, index) {
                final spool = spools[index];

                final progress =
                spool.dispatchStatus == 'Dispatched'
                    ? 1.0
                    : spool.dispatchStatus == 'In Progress'
                    ? 0.5
                    : 0.0;

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        // =========================
                        // SPOOL MARK
                        // =========================
                        Text(
                          spool.spoolMarkNo.isEmpty
                              ? 'Mark: N/A'
                              : spool.spoolMarkNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(height: 2),

                        // =========================
                        // DRAWING NUMBER
                        // =========================
                        Text(
                          'DRG: ${spool.drawingNo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // =========================
                        // LINE + MATERIAL
                        // =========================
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (spool.lineNo.isNotEmpty)
                              Chip(
                                materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                                visualDensity:
                                VisualDensity.compact,
                                label: Text(
                                  spool.lineNo,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                  ),
                                ),
                              ),

                            if (spool.material.isNotEmpty)
                              Chip(
                                materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                                visualDensity:
                                VisualDensity.compact,
                                label: Text(
                                  spool.material,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // =========================
                        // PROGRESS
                        // =========================
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor:
                          Colors.grey.shade300,
                          color: progress == 1.0
                              ? Colors.green
                              : Colors.orange,
                        ),

                        const SizedBox(height: 8),

                        // =========================
                        // STATUS
                        // =========================
                        DropdownButton<String>(
                          value: spool.dispatchStatus,
                          isExpanded: true,

                          // Makes dropdown more compact
                          isDense: true,

                          items: const [
                            'Pending',
                            'In Progress',
                            'Dispatched',
                          ].map(
                                (status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(
                                  status,
                                  overflow:
                                  TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ).toList(),

                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(
                                spoolProvider.notifier,
                              )
                                  .updateStatus(
                                index,
                                val,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _metricChip(
      String label,
      String value,
      Color color,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),

        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
          ),
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}