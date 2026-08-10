import 'package:bmapp/screens/upload_sxtract_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bom_provider.dart';
import '../services/excel_service.dart';
import 'dashboard_screen.dart';
import 'dump_bom_screen.dart';
import 'iso_wise_screen.dart';
import 'piping_bom_screen.dart';
import 'spool_tracker_screen.dart';
import 'weight_calc_screen.dart';
import 'revision_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Upload & Extract',
    'DUMP BOM',
    'ISO WISE BOM',
    'PIPING BOM',
    'Spool Tracker',
    'Weight Calculator',
    'Revisions & Notes',
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    UploadExtractScreen(),
    DumpBomScreen(),
    IsoWiseScreen(),
    PipingBomScreen(),
    SpoolTrackerScreen(),
    WeightCalcScreen(),
    RevisionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          if(_selectedIndex==3)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download ISO Wise BOM',
              onPressed: () async {
                final bomItems = ref.read(bomProvider);
                if (bomItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ No ISO data available to download'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final result =
                await ExcelExportService.exportIsoWiseBom(bomItems);


                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result != null
                          ? '📥 ISO Wise BOM downloaded successfully'
                          : '❌ Failed to download ISO Wise BOM',
                    ),
                    backgroundColor:
                    result != null ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
          if(_selectedIndex==4)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download PIPING BOM',
              onPressed: () async {
                final bomItems = ref.read(bomProvider);
                if (bomItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ No PIPING BOM data available to download'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final result =
                await ExcelExportService.exportPipeBom(bomItems);


                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result != null
                          ? '📥 PIPING BOM downloaded successfully'
                          : '❌ Failed to download PIPING BOM',
                    ),
                    backgroundColor:
                    result != null ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
        backgroundColor: Colors.white, // Mobile drawer background set to White
        child: _buildNavList(),
      ),
      body: Row(
        children: [
          if (isDesktop) ...[
            SizedBox(
              width: 240,
              child: Drawer(
                backgroundColor: Colors.blue, // Desktop sidebar background set to White
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), // Border-radius remove karne ke liye
                child: _buildNavList(),
              ),
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildNavList() {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0F172A)), // Header retains dark background
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(' ISO DRG', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('GET ALL DETAILS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 8),
                Chip(label: Text('v12 FLUTTER', style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.blue),
              ],
            ),
          ),
          _navItem(0, Icons.dashboard, 'Dashboard'),
          _navItem(1, Icons.upload_file, 'Upload & Extract'),
          _navItem(2, Icons.table_chart, 'DUMP BOM'),
          _navItem(3, Icons.analytics, 'ISO WISE BOM'),
          _navItem(4, Icons.precision_manufacturing, 'PIPING BOM'),
          _navItem(5, Icons.local_shipping, 'Spool Tracker'),
          _navItem(6, Icons.scale, 'Weight Calculator'),
          _navItem(7, Icons.history, 'Revisions & Notes'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? Colors.blue : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? Colors.blue : Colors.black87,
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() => _selectedIndex = index);
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
    );
  }




}

