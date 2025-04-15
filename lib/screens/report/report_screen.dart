import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moodyr/models/diary_entry_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DiaryEntry> _diaryEntries = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _storage = const FlutterSecureStorage();
  final String _apiBaseUrl = 'http://10.0.2.2:3000/api';

  // cores para humores
  final Map<String, Color> _moodColors = {
    'Feliz': Colors.amber.shade500,
    'Ansioso': Colors.orange.shade600,
    'Calmo': Colors.blue.shade500,
    'Triste': Colors.indigo.shade500,
    'Animado': Colors.pink.shade500,
    'Grato': Colors.green.shade600,
    'Com Raiva': Colors.red.shade600,
  };
  
  // ícones para humores
  final Map<String, IconData> _moodIcons = {
    'Feliz': Icons.emoji_emotions,
    'Ansioso': Icons.upcoming,
    'Calmo': Icons.nightlight,
    'Triste': Icons.sentiment_very_dissatisfied,
    'Animado': Icons.celebration,
    'Grato': Icons.favorite,
    'Com Raiva': Icons.flash_on,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Função auxiliar token JWT
  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Função auxiliar criar headers com o token
  Future<Map<String, String>> _getHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Buscar entradas da API
  Future<void> _fetchEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/diary'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _diaryEntries = data.map((item) {
            return DiaryEntry(
              id: item['id'].toString(),
              content: item['conteudo'],
              date: DateTime.parse(item['data_entrada']),
              mood: item['humor'],
            );
          }).toList();
          
          // Ordenar por data
          _diaryEntries.sort((a, b) => a.date.compareTo(b.date));
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao buscar dados. Tente novamente.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro de conexão: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights de Humor', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade300,
                Colors.blue.shade300,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Geral'),
            Tab(text: 'Resumo'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchEntries,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade400,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : _diaryEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Sem dados suficientes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Adicione mais entradas no seu diário para gerar relatórios e insights',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade50,
                            Colors.blue.shade50,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildSummaryTab(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildOverviewTab() {
    // Contagem de emoções
    Map<String, int> moodCounts = {};
    for (var entry in _diaryEntries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Distribuição de Emoções',
            child: SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: moodCounts.entries.map((entry) {
                    return PieChartSectionData(
                      color: _moodColors[entry.key] ?? Colors.grey,
                      value: entry.value.toDouble(),
                      title: '${entry.key}: ${entry.value}',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Estatísticas Rápidas',
            child: Column(
              children: [
                _buildStatisticTile(
                  icon: Icons.note_alt,
                  title: 'Total de Entradas',
                  value: _diaryEntries.length.toString(),
                ),
                const Divider(),
                _buildStatisticTile(
                  icon: Icons.emoji_emotions,
                  title: 'Humor Mais Comum',
                  value: moodCounts.entries.isEmpty 
                      ? '-' 
                      : moodCounts.entries
                          .reduce((a, b) => a.value > b.value ? a : b)
                          .key,
                  color: moodCounts.entries.isEmpty 
                      ? null 
                      : _moodColors[moodCounts.entries
                          .reduce((a, b) => a.value > b.value ? a : b)
                          .key],
                ),
                const Divider(),
                _buildStatisticTile(
                  icon: Icons.calendar_today,
                  title: 'Período Analisado',
                  value: _diaryEntries.isEmpty 
                      ? '-' 
                      : '${DateFormat('dd/MM/yy').format(_diaryEntries.first.date)} até ${DateFormat('dd/MM/yy').format(_diaryEntries.last.date)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    // dia da semana
    Map<int, int> dayOfWeekFrequency = {};
    Map<int, Map<String, int>> dayOfWeekMoods = {};
    
    for (var entry in _diaryEntries) {
      int dayOfWeek = entry.date.weekday;
      dayOfWeekFrequency[dayOfWeek] = (dayOfWeekFrequency[dayOfWeek] ?? 0) + 1;
      
      dayOfWeekMoods.putIfAbsent(dayOfWeek, () => {});
      dayOfWeekMoods[dayOfWeek]![entry.mood] = (dayOfWeekMoods[dayOfWeek]![entry.mood] ?? 0) + 1;
    }

    final List<String> weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Frequência por Dia da Semana',
            child: AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (dayOfWeekFrequency.isEmpty ? 1 : dayOfWeekFrequency.values.reduce(max) + 1).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 == 0) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 10,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < weekdays.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                weekdays[value.toInt()],
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barGroups: List.generate(7, (index) {
                    final int dayIndex = index + 1; // 1-7 para segunda-domingo
                    final int count = dayOfWeekFrequency[dayIndex] ?? 0;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade300,
                              Colors.blue.shade300,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Resumo Mensal',
            child: _buildMonthlyMoodSummary(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticTile({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (color ?? Colors.deepPurple.shade400).withOpacity(0.1),
            child: Icon(icon, color: color ?? Colors.deepPurple.shade400),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple.shade400, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyMoodSummary() {
    // Agrupar por mês
    Map<String, Map<String, int>> monthlyMoods = {};
    
    for (var entry in _diaryEntries) {
      String month = DateFormat('MMM/yy', 'pt_BR').format(entry.date);
      monthlyMoods.putIfAbsent(month, () => {});
      monthlyMoods[month]![entry.mood] = (monthlyMoods[month]![entry.mood] ?? 0) + 1;
    }
    
    // últimos 3 meses
    List<String> months = monthlyMoods.keys.toList();
    months.sort(); // Ordenar cronologicamente
    
    if (months.length > 3) {
      months = months.sublist(months.length - 3);
    }
    
    return Column(
      children: months.map((month) {
        // humor predominante do mês
        String? dominantMood;
        int maxCount = 0;
        
        monthlyMoods[month]!.forEach((mood, count) {
          if (count > maxCount) {
            maxCount = count;
            dominantMood = mood;
          }
        });
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _moodColors[dominantMood]?.withOpacity(0.2),
              child: Text(
                month.substring(0, 3),
                style: TextStyle(
                  color: _moodColors[dominantMood],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              'Humor predominante: $dominantMood',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Total de entradas: ${monthlyMoods[month]!.values.reduce((a, b) => a + b)}'),
            trailing: Icon(_moodIcons[dominantMood ?? 'Feliz'], color: _moodColors[dominantMood]),
          ),
        );
      }).toList(),
    );
  }
} 