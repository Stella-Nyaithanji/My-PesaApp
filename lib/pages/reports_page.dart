import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:my_pesa_app/pages/firestore_collections_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State createState() => ReportsPageState();
}

class ReportsPageState extends State {
  final FirestoreCollectionsService _service = FirestoreCollectionsService();
  double _totalRevenue = 0.0;
  double _totalCost = 0.0;
  double _profit = 0.0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    try {
      // Fetch all sales records
      final salesDocs = await _service.fetchSalesRecords();

      double revenue = 0.0;
      double cost = 0.0;

      for (var doc in salesDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        for (var raw in items) {
          final item = raw as Map<String, dynamic>;
          final qty = (item['quantity'] ?? 0).toDouble();
          final sellPrice = (item['sellingPrice'] ?? 0).toDouble();
          final buyPrice = (item['buyingPrice'] ?? 0).toDouble();
          revenue += qty * sellPrice;
          cost += qty * buyPrice;
        }
      }

      setState(() {
        _totalRevenue = revenue;
        _totalCost = cost;
        _profit = revenue - cost;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  AppBar _buildGradientAppBar() {
    return AppBar(
      title: const Text('Reports'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildGradientAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : _error != null
                ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ----- Metric Cards with Icons & Tooltips -----
                      _buildMetricCard(
                        icon: Icons.shopping_cart,
                        title: 'Total Sales',
                        description: 'How much you earned from selling goods',
                        value: 'KSH ${_totalRevenue.toStringAsFixed(2)}',
                        valueColor: Colors.teal,
                      ),
                      const SizedBox(height: 12),
                      _buildMetricCard(
                        icon: Icons.inventory,
                        title: 'Total Cost',
                        description: 'How much it cost you to buy stock',
                        value: 'KSH ${_totalCost.toStringAsFixed(2)}',
                        valueColor: Colors.orange.shade700,
                      ),
                      const SizedBox(height: 12),
                      _buildMetricCard(
                        icon: Icons.attach_money,
                        title: 'Profit',
                        description: 'Revenue minus cost',
                        value: 'KSH ${_profit.toStringAsFixed(2)}',
                        valueColor: _profit >= 0 ? Colors.green : Colors.red,
                      ),

                      const SizedBox(height: 20),

                      // ----- Pie Chart -----
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Sales vs Cost vs Profit',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 180,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 4,
                                    centerSpaceRadius: 0,
                                    sections: [
                                      PieChartSectionData(
                                        value: _totalRevenue,
                                        title: 'Sales',
                                        color: Colors.teal,
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: _totalCost,
                                        title: 'Cost',
                                        color: Colors.orange.shade700,
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: _profit.abs(),
                                        title: 'Profit',
                                        color: _profit >= 0 ? Colors.green : Colors.red,
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String description,
    required String value,
    Color? valueColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: valueColor ?? Colors.teal),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Tooltip(message: description, child: const Icon(Icons.info_outline, size: 18, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: valueColor ?? Colors.teal)),
          ],
        ),
      ),
    );
  }
}
