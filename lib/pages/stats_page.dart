import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final workoutsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('workouts');
    final sessionsQuery = FirebaseFirestore.instance
        .collectionGroup('sessions')
        .where('userId', isEqualTo: uid);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Estatísticas'),
      ),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: workoutsRef.snapshots(),
          builder: (context, workoutsSnap) {
            if (workoutsSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }
            final workoutsCount = workoutsSnap.data?.docs.length ?? 0;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: sessionsQuery.snapshots(),
              builder: (context, sessionsSnap) {
                if (sessionsSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CupertinoActivityIndicator());
                }

                final sessions = sessionsSnap.data?.docs ?? [];
                final totalSessions = sessions.length;
                double totalVolume = 0;
                int completedSessions = 0;
                double bestVolume = 0;
                QueryDocumentSnapshot<Map<String, dynamic>>? lastSession;

                for (final doc in sessions) {
                  final data = doc.data();
                  final volume = (data['totalVolume'] as num?)?.toDouble() ?? 0.0;
                  totalVolume += volume;
                  if (volume > bestVolume) bestVolume = volume;
                  if (data['status'] == 'completed') completedSessions++;
                  if (lastSession == null) {
                    lastSession = doc;
                  } else {
                    final currentStartedAt =
                        (doc.data()['startedAt'] as Timestamp?)?.toDate();
                    final previousStartedAt =
                        (lastSession!.data()['startedAt'] as Timestamp?)?.toDate();
                    if (currentStartedAt != null && previousStartedAt != null) {
                      if (currentStartedAt.isAfter(previousStartedAt)) {
                        lastSession = doc;
                      }
                    }
                  }
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    const Text(
                      'Resumo',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Treinos criados',
                            value: workoutsCount.toString(),
                            color: const Color(0xFF0A84FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Sessões',
                            value: totalSessions.toString(),
                            color: const Color(0xFF32D74B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Volume total',
                            value: '${totalVolume.toStringAsFixed(1)} kg',
                            color: const Color(0xFFFF9F0A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Sessões concluídas',
                            value: completedSessions.toString(),
                            color: const Color(0xFFFF375F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Melhor sessão',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (sessions.isEmpty)
                      const Text(
                        'Ainda não registaste sessões. Começa um treino para ver estatísticas aqui.',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${bestVolume.toStringAsFixed(1)} kg movidos',
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${completedSessions} sessões concluídas',
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Última sessão',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (lastSession == null)
                      const Text(
                        'Sem sessões recentes.',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lastSession!.data()['workoutTitle'] as String? ??
                                  'Treino',
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDate(
                                (lastSession!.data()['startedAt'] as Timestamp?)
                                    ?.toDate(),
                              ),
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Volume: ${(lastSession!.data()['totalVolume'] as num?)?.toStringAsFixed(1) ?? '0.0'} kg',
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final date =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
