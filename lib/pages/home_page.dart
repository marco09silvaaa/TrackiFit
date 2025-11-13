import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import 'workouts/workout_create_page.dart';
import 'workouts/workout_detail_page.dart';
import 'workouts/workouts_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user!.uid;
    final workoutsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .orderBy('createdAt', descending: true)
        .limit(5);
    final sessionsQuery = FirebaseFirestore.instance
        .collectionGroup('sessions')
        .where('userId', isEqualTo: uid);

    final greeting = _greetingMessage();
    final displayName = user.displayName ?? user.email ?? 'Atleta';

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('TrackiFit'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text(
              '$greeting,',
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayName,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    label: 'Novo treino',
                    icon: CupertinoIcons.add_circled_solid,
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => const WorkoutCreatePage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    label: 'Ver treinos',
                    icon: CupertinoIcons.list_bullet,
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => const WorkoutsPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Planos recentes',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: workoutsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CupertinoActivityIndicator()),
                  );
                }
                final workouts = snapshot.data?.docs ?? [];
                if (workouts.isEmpty) {
                  return const Text(
                    'Ainda não criaste treinos. Começa com um plano rápido!',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  );
                }

                return Column(
                  children: workouts.map((doc) {
                    final data = doc.data();
                    final title = (data['title'] as String?)?.isNotEmpty == true
                        ? data['title'] as String
                        : 'Sem título';
                    final note = (data['note'] as String?)?.trim();
                    final exercises =
                        ((data['exercises'] as List<dynamic>?) ?? []).length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$exercises exercícios',
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey2,
                            ),
                          ),
                          if (note != null && note.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                note,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) =>
                                    WorkoutDetailPage(workoutId: doc.id),
                              ),
                            ),
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Abrir plano'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Última sessão',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: sessionsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CupertinoActivityIndicator()),
                  );
                }

                final sessions = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                    snapshot.data?.docs ?? []);
                if (sessions.isEmpty) {
                  return const Text(
                    'Quando começares a registar treinos, o resumo aparece aqui.',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  );
                }

                sessions.sort((a, b) {
                  final aDate = (a.data()['startedAt'] as Timestamp?)?.toDate();
                  final bDate = (b.data()['startedAt'] as Timestamp?)?.toDate();
                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  return bDate.compareTo(aDate);
                });

                final session = sessions.first;
                final data = session.data();
                final startedAt = (data['startedAt'] as Timestamp?)?.toDate();
                final status = data['status'] as String? ?? 'active';
                final totalVolume =
                    (data['totalVolume'] as num?)?.toDouble() ?? 0.0;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['workoutTitle'] as String? ?? 'Treino',
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'completed'
                                  ? CupertinoColors.activeGreen
                                      .withOpacity(0.15)
                                  : CupertinoColors.activeBlue
                                      .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status == 'completed'
                                  ? 'Concluída'
                                  : 'Em curso',
                              style: TextStyle(
                                color: status == 'completed'
                                    ? CupertinoColors.activeGreen
                                    : CupertinoColors.activeBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (startedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _formatDate(startedAt),
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Volume: ${totalVolume.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _greetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 19) return 'Boa tarde';
    return 'Boa noite';
  }

  String _formatDate(DateTime dt) {
    final date =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: CupertinoColors.activeBlue),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
