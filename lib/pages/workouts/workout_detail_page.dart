import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'workout_session_page.dart';

class WorkoutDetailPage extends StatefulWidget {
  final String workoutId;
  const WorkoutDetailPage({super.key, required this.workoutId});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  bool startingSession = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .doc(widget.workoutId);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Treino'),
      ),
      backgroundColor: const Color(0xFF0E0E0F),
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: docRef.snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (!snap.hasData || !snap.data!.exists) {
              return const Center(
                child: Text(
                  'Treino não encontrado.',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              );
            }
            final data = snap.data!.data()!;
            final title = (data['title'] as String?)?.trim().isNotEmpty == true
                ? data['title'] as String
                : 'Sem título';
            final note = (data['note'] as String?)?.trim() ?? '';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final exercises = ((data['exercises'] as List<dynamic>?) ?? [])
                .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(
                      e as Map<String, dynamic>),
                )
                .toList();

            final sessionsRef = docRef
                .collection('sessions')
                .orderBy('startedAt', descending: true);

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: sessionsRef.snapshots(),
              builder: (context, sessionsSnap) {
                if (sessionsSnap.hasError && !sessionsSnap.hasData) {
                  return Center(
                    child: Text(
                      'Erro ao carregar sessões: ${sessionsSnap.error}',
                      style:
                          const TextStyle(color: CupertinoColors.systemRed),
                    ),
                  );
                }
                if (sessionsSnap.connectionState == ConnectionState.waiting &&
                    !sessionsSnap.hasData) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                final sessionDocs = sessionsSnap.data?.docs ?? [];
                QueryDocumentSnapshot<Map<String, dynamic>>? activeSessionDoc;
                for (final doc in sessionDocs) {
                  if (doc.data()['status'] == 'active') {
                    activeSessionDoc = doc;
                    break;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (createdAt != null)
                      Text(
                        'Criado em ${_formatDateTime(createdAt)}',
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 13,
                        ),
                      ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        note,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    CupertinoButton.filled(
                      onPressed: startingSession
                          ? null
                          : () => _handleStartSession(
                                docRef,
                                data,
                                exercises,
                                activeSessionDoc,
                              ),
                      child: startingSession
                          ? const CupertinoActivityIndicator()
                          : Text(
                              activeSessionDoc != null
                                  ? 'Retomar sessão ativa'
                                  : 'Começar novo treino',
                            ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Exercícios',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (exercises.isEmpty)
                      const Text(
                        'Ainda não adicionaste exercícios a este treino.',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      )
                    else
                      ...exercises.map(
                        (ex) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex['name'] ?? 'Exercício',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if ((ex['muscleGroup'] as String?)?.isNotEmpty ==
                                  true)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    ex['muscleGroup'],
                                    style: const TextStyle(
                                      color: CupertinoColors.systemGrey2,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sessões recentes',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (sessionsSnap.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Alguns dados não foram carregados: ${sessionsSnap.error}',
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    if (sessionDocs.isEmpty)
                      const Text(
                        'Ainda não existe histórico. Inicia um treino para registares os teus sets!',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      )
                    else
                      ...sessionDocs.map(
                        (doc) {
                          final session = doc.data();
                          final startedAt =
                              (session['startedAt'] as Timestamp?)?.toDate();
                          final endedAt =
                              (session['endedAt'] as Timestamp?)?.toDate();
                          final status = session['status'] as String? ?? '—';
                          final totalSets = (session['totalSets'] as num?)?.toInt() ?? 0;
                          final totalVolume =
                              (session['totalVolume'] as num?)?.toDouble() ?? 0.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      startedAt != null
                                          ? _formatDateTime(startedAt)
                                          : 'Sessão',
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontWeight: FontWeight.w600,
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
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sets: $totalSets · Volume: ${totalVolume.toStringAsFixed(1)} kg',
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                                if (endedAt != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      'Terminada às ${_formatTime(endedAt)}',
                                      style: const TextStyle(
                                        color: CupertinoColors.systemGrey2,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (_) => WorkoutSessionPage(
                                          workoutId: widget.workoutId,
                                          workoutTitle: title,
                                          sessionId: doc.id,
                                          exercises: exercises,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('Ver sessão'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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

  Future<void> _handleStartSession(
    DocumentReference<Map<String, dynamic>> workoutRef,
    Map<String, dynamic> workoutData,
    List<Map<String, dynamic>> exercises,
    QueryDocumentSnapshot<Map<String, dynamic>>? activeSessionDoc,
  ) async {
    try {
      setState(() => startingSession = true);
      DocumentReference<Map<String, dynamic>> sessionRef;
      if (activeSessionDoc != null) {
        sessionRef = activeSessionDoc.reference;
      } else {
        sessionRef = workoutRef.collection('sessions').doc();
        await sessionRef.set({
          'startedAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'workoutId': workoutRef.id,
          'workoutTitle': workoutData['title'] ?? '',
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'totalSets': 0,
          'totalVolume': 0,
        });
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => WorkoutSessionPage(
            workoutId: workoutRef.id,
            workoutTitle: workoutData['title'] ?? 'Treino',
            sessionId: sessionRef.id,
            exercises: exercises,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Erro ao iniciar sessão'),
          content: Text('Não foi possível iniciar o treino: $e'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => startingSession = false);
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final date =
        '${_twoDigits(dt.day)}/${_twoDigits(dt.month)}/${dt.year.toString().padLeft(4, '0')}';
    final time = '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';
    return '$date · $time';
  }

  String _formatTime(DateTime dt) {
    return '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
