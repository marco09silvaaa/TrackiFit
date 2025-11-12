import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'workout_create_page.dart';
import 'workout_detail_page.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});
  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  bool collapsed = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final workoutsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .orderBy('createdAt', descending: true);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0E0E0F), // fundo dark
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Treinos'),
        backgroundColor: Color(0xFF161617),
        border: null,
      ),
      child: SafeArea(
        bottom: false,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: workoutsRef.snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // --- Ações Rápidas ---
                const _SectionTitle('Criar'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        icon: CupertinoIcons.doc_append,
                        label: 'Novo Treino',
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (_) => const WorkoutCreatePage()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const SizedBox(width: 0),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Rotinas ---
                const _SectionTitle('Treinos'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => collapsed = !collapsed),
                  child: Row(
                    children: [
                      Icon(
                        collapsed
                            ? CupertinoIcons.chevron_right
                            : CupertinoIcons.chevron_down,
                        size: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Meus Treinos (${docs.length})',
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else if (docs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Nenhum treino criado.',
                        style: TextStyle(color: CupertinoColors.inactiveGray),
                      ),
                    ),
                  )
                else if (!collapsed)
                  ...docs.map((d) {
                    final data = d.data();
                    final title = (data['title'] as String?)?.trim();
                    final note = (data['note'] as String?)?.trim();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _WorkoutCard(
                        title: title?.isNotEmpty == true ? title! : 'Sem título',
                        subtitle:
                            (note?.isNotEmpty == true) ? note! : '—',
                        onOpen: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) =>
                                WorkoutDetailPage(workoutId: d.id),
                          ),
                        ),
                        onStart: () {
                          // aqui no futuro: criar sessão/instância de treino
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) =>
                                  WorkoutDetailPage(workoutId: d.id),
                            ),
                          );
                        },
                        onMore: () => _showMore(context, uid, d.id),
                      ),
                    );
                  }),
                const SizedBox(height: 60),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showMore(BuildContext context, String uid, String workoutId) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('workouts')
                  .doc(workoutId)
                  .delete();
            },
            child: const Text('Eliminar'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: CupertinoColors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: CupertinoColors.white),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: CupertinoColors.white)),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onOpen;
  final VoidCallback onStart;
  final VoidCallback onMore;

  const _WorkoutCard({
    required this.title,
    required this.subtitle,
    required this.onOpen,
    required this.onStart,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(4),
                  onPressed: onMore,
                  child: const Icon(
                    CupertinoIcons.ellipsis_vertical,
                    size: 18,
                    color: CupertinoColors.systemGrey2,
                  ),
                )
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 14,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: const Color(0xFF0A84FF), // azul iOS
                borderRadius: BorderRadius.circular(12),
                onPressed: onStart,
                child: const Text(
                  'Começar Treino',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
