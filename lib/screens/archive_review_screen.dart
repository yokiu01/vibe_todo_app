import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/review_provider.dart';
import 'package:intl/intl.dart';

class ArchiveReviewScreen extends StatefulWidget {
  const ArchiveReviewScreen({super.key});

  @override
  State<ArchiveReviewScreen> createState() => _ArchiveReviewScreenState();
}

class _ArchiveReviewScreenState extends State<ArchiveReviewScreen> {
  String _selectedRange = 'this_week';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final reviewProvider = context.read<ReviewProvider>();
    reviewProvider.setPredefinedRange(_selectedRange);
    await reviewProvider.fetchArchiveReviewData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: AppBar(
        title: const Text(
          '📊 회고 및 요약',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3C2A21),
          ),
        ),
        backgroundColor: const Color(0xFFFDF6E3),
        elevation: 0,
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, reviewProvider, child) {
          if (reviewProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B7355)),
              ),
            );
          }

          if (reviewProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    reviewProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Filter
                  _buildDateRangeFilter(reviewProvider),

                  const SizedBox(height: 24),

                  // Period Display
                  _buildPeriodDisplay(reviewProvider),

                  const SizedBox(height: 24),

                  // Do Section: 무엇을 해냈나요?
                  _buildDoSection(reviewProvider),

                  const SizedBox(height: 32),

                  // Divider
                  const Divider(
                    thickness: 2,
                    color: Color(0xFFDDD4C0),
                  ),

                  const SizedBox(height: 32),

                  // See Section: 무엇을 느끼고 배웠나요?
                  _buildSeeSection(reviewProvider),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeFilter(ReviewProvider reviewProvider) {
    final ranges = [
      {'key': 'today', 'label': '오늘'},
      {'key': 'this_week', 'label': '이번 주'},
      {'key': 'last_week', 'label': '지난주'},
      {'key': 'this_month', 'label': '이번 달'},
      {'key': 'last_month', 'label': '지난달'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD4C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.date_range,
                color: Color(0xFF8B7355),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '기간 선택',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3C2A21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ranges.map((range) {
              final isSelected = _selectedRange == range['key'];
              return ChoiceChip(
                label: Text(range['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedRange = range['key']!;
                    });
                    _loadData();
                  }
                },
                selectedColor: const Color(0xFF8B7355),
                backgroundColor: const Color(0xFFEFE7D3),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF3C2A21),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodDisplay(ReviewProvider reviewProvider) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final startStr = dateFormat.format(reviewProvider.startDate);
    final endStr = dateFormat.format(reviewProvider.endDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B7355).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B7355).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month,
            color: Color(0xFF8B7355),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            '$startStr ~ $endStr',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3C2A21),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoSection(ReviewProvider reviewProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '무엇을 해냈나요? (Do)',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C2A21),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Key Metrics Card
        _buildKeyMetricsCard(reviewProvider),

        const SizedBox(height: 16),

        // Project Chart
        if (reviewProvider.projectStats.isNotEmpty)
          _buildProjectChart(reviewProvider),
      ],
    );
  }

  Widget _buildKeyMetricsCard(ReviewProvider reviewProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD4C0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B7355).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  '총 완료한 일',
                  reviewProvider.totalCompletedTasks.toString(),
                  Icons.task_alt,
                  const Color(0xFF10B981),
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: const Color(0xFFDDD4C0),
              ),
              Expanded(
                child: _buildMetricItem(
                  '가장 집중한 프로젝트',
                  reviewProvider.topProject ?? '없음',
                  Icons.star,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8B7355),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProjectChart(ReviewProvider reviewProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD4C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart,
                color: Color(0xFF8B7355),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '프로젝트별 성과',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3C2A21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildBarChart(reviewProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(ReviewProvider reviewProvider) {
    final stats = reviewProvider.projectStats;
    if (stats.isEmpty) {
      return const Center(
        child: Text('데이터가 없습니다'),
      );
    }

    final maxValue = stats.values.reduce((a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF3C2A21),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final projectName = stats.keys.elementAt(groupIndex);
              return BarTooltipItem(
                '$projectName\n${rod.toY.toInt()}개',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= stats.length) return const Text('');
                final projectName = stats.keys.elementAt(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    projectName.length > 8
                        ? '${projectName.substring(0, 7)}...'
                        : projectName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8B7355),
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B7355),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: const Color(0xFFDDD4C0),
              strokeWidth: 1,
            );
          },
        ),
        barGroups: stats.entries.map((entry) {
          final index = stats.keys.toList().indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: const Color(0xFF8B7355),
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSeeSection(ReviewProvider reviewProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.visibility,
                color: Color(0xFF8B5CF6),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '무엇을 느끼고 배웠나요? (See)',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C2A21),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Diary Timeline
        if (reviewProvider.diaryEntries.isEmpty)
          _buildEmptyDiaryState()
        else
          ...reviewProvider.diaryEntries.map((entry) {
            return _buildDiaryCard(entry);
          }),
      ],
    );
  }

  Widget _buildEmptyDiaryState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD4C0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.edit_note,
            size: 64,
            color: const Color(0xFF8B7355).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '이 기간에 작성된 회고가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8B7355),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '매일 하루를 돌아보고 배움을 기록해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9C8B73),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryCard(Map<String, dynamic> entry) {
    try {
      final properties = entry['properties'] as Map<String, dynamic>;
      final titleArray = properties['이름']['title'] as List<dynamic>;
      final dateStr = titleArray.first['plain_text'] as String;
      final pageId = entry['id'] as String;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF6E3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDD4C0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B7355).withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<String>(
              future: context.read<ReviewProvider>().getDiaryContent(pageId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF8B7355),
                        ),
                      ),
                    ),
                  );
                }

                final content = snapshot.data ?? '내용이 없습니다';

                return Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF3C2A21),
                  ),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
