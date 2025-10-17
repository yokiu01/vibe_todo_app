import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/routine_provider.dart';
import '../../utils/app_colors.dart';
import 'routine_form_screen.dart';
import 'routine_card.dart';

class RoutineManagementScreen extends StatefulWidget {
  const RoutineManagementScreen({super.key});

  @override
  State<RoutineManagementScreen> createState() => _RoutineManagementScreenState();
}

class _RoutineManagementScreenState extends State<RoutineManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineProvider>().fetchRoutines();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<RoutineProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchRoutines(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final activeRoutines = provider.activeRoutines;
          final pausedRoutines = provider.routines
              .where((r) => r.status == 'Paused')
              .toList();

          return CustomScrollView(
            slivers: [
              // Header with stats
              SliverToBoxAdapter(
                child: _buildHeader(provider),
              ),

              // Active Routines Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.accentBlue),
                      const SizedBox(width: 8),
                      Text(
                        '활성 루틴',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${activeRoutines.length}',
                          style: TextStyle(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Active Routines List
              if (activeRoutines.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.repeat,
                            size: 64,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '아직 루틴이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '아래 버튼을 눌러 첫 루틴을 만들어보세요!',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final routine = activeRoutines[index];
                      return RoutineCard(routine: routine);
                    },
                    childCount: activeRoutines.length,
                  ),
                ),

              // Paused Routines (collapsible section)
              if (pausedRoutines.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ExpansionTile(
                      leading: Icon(Icons.pause_circle, color: Colors.orange.shade400),
                      title: Text(
                        '일시정지된 루틴 (${pausedRoutines.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      children: pausedRoutines
                          .map((routine) => RoutineCard(routine: routine, isPaused: true))
                          .toList(),
                    ),
                  ),
                ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoutineForm(context),
        icon: const Icon(Icons.add),
        label: const Text('루틴 추가'),
        backgroundColor: AppColors.accentBlue,
      ),
    );
  }

  Widget _buildHeader(RoutineProvider provider) {
    final activeCount = provider.activeRoutines.length;
    final totalCount = provider.routines.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentBlue,
            AppColors.accentBlue.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '루틴 관리',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '매일 반복되는 작업을 자동화하세요',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('전체 루틴', totalCount.toString(), Icons.list_alt),
              _buildStatItem('활성', activeCount.toString(), Icons.check_circle),
              _buildStatItem('일시정지', (totalCount - activeCount).toString(), Icons.pause_circle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showRoutineForm(BuildContext context, {dynamic routine}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineFormScreen(routine: routine),
      ),
    );
  }
}
