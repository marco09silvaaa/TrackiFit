import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class WorkoutSessionPage extends StatefulWidget {
  final String workoutId;
  final String sessionId;
  final String workoutTitle;
  final List<Map<String, dynamic>> exercises;

  const WorkoutSessionPage({
    super.key,
    required this.workoutId,
    required this.sessionId,
    required this.workoutTitle,
    required this.exercises,
  });

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  bool finishing = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final sessionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .doc(widget.workoutId)
        .collection('sessions')
        .doc(widget.sessionId);

    final setsQuery = sessionRef.collection('sets').orderBy('createdAt');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: sessionRef.snapshots(),
      builder: (context, sessionSnap) {
        if (sessionSnap.connectionState == ConnectionState.waiting) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        if (!sessionSnap.hasData || !sessionSnap.data!.exists) {
          return const CupertinoPageScaffold(
            child: Center(
              child: Text(
                'Sessão não encontrada.',
                style: TextStyle(color: CupertinoColors.systemGrey),
              ),
            ),
          );
        }

        final sessionData = sessionSnap.data!.data()!;
        final status = sessionData['status'] as String? ?? 'active';
        final totalSets = (sessionData['totalSets'] as num?)?.toInt() ?? 0;
        final totalVolume =
            (sessionData['totalVolume'] as num?)?.toDouble() ?? 0.0;

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(widget.workoutTitle),
            trailing: status == 'completed'
                ? null
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed:
                        finishing ? null : () => _finishSession(sessionRef),
                    child: finishing
                        ? const CupertinoActivityIndicator()
                        : const Text('Terminar'),
                  ),
          ),
          backgroundColor: const Color(0xFF0E0E0F),
          child: SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: setsQuery.snapshots(),
              builder: (context, setsSnap) {
                if (setsSnap.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar sets: ${setsSnap.error}',
                      style: const TextStyle(color: CupertinoColors.systemRed),
                    ),
                  );
                }
                if (setsSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                final setDocs = setsSnap.data?.docs ?? [];
                final setsByExercise = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

                for (final doc in setDocs) {
                  final data = doc.data();
                  final exerciseId = data['exerciseId']?.toString() ?? '';
                  setsByExercise.putIfAbsent(exerciseId, () => []).add(doc);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sets registados',
                                style: TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$totalSets',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Volume total',
                                style: TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${totalVolume.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (widget.exercises.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Este treino ainda não tem exercícios associados. Adiciona-os ao plano para registares sets.',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (widget.exercises.isNotEmpty)
                    ...widget.exercises.map((exercise) {
                      final exerciseId = exercise['id']?.toString() ?? exercise['name'];
                      final exerciseSets = setsByExercise[exerciseId] ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise['name'] ?? 'Exercício',
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if ((exercise['muscleGroup'] as String?)?.isNotEmpty == true)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            exercise['muscleGroup'],
                                            style: const TextStyle(
                                              color: CupertinoColors.systemGrey2,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: status == 'completed'
                                      ? null
                                      : () => _addSet(sessionRef, exercise),
                                  child: const Icon(
                                    CupertinoIcons.add_circled_solid,
                                    color: CupertinoColors.activeBlue,
                                    size: 26,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (exerciseSets.isEmpty)
                              const Text(
                                'Sem sets registados ainda.',
                                style: TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 14,
                                ),
                              )
                            else
                              ...exerciseSets.map((setDoc) {
                                final data = setDoc.data();
                                final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
                                final reps = (data['reps'] as num?)?.toInt() ?? 0;
                                final createdAt =
                                    (data['createdAt'] as Timestamp?)?.toDate();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C2C2E),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${weight.toStringAsFixed(1)} kg · $reps reps',
                                              style: const TextStyle(
                                                color: CupertinoColors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (createdAt != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Text(
                                                  _formatTime(createdAt),
                                                  style: const TextStyle(
                                                    color: CupertinoColors.systemGrey2,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (status != 'completed')
                                        CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _removeSet(
                                            sessionRef,
                                            setDoc,
                                            weight,
                                            reps,
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.delete,
                                            color: CupertinoColors.destructiveRed,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      );
                    }).toList(),
                    if (status == 'completed')
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Sessão terminada. Podes rever ou editar os dados a qualquer momento.',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _addSet(
    DocumentReference<Map<String, dynamic>> sessionRef,
    Map<String, dynamic> exercise,
  ) async {
    final weightController = TextEditingController();
    final repsController = TextEditingController();
    String? error;

    final result = await showCupertinoDialog<Map<String, num>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return CupertinoAlertDialog(
              title: Text('Adicionar set — ${exercise['name'] ?? ''}'),
              content: Column(
                children: [
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    placeholder: 'Peso (kg)',
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    placeholder: 'Repetições',
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    final weight = double.tryParse(
                        weightController.text.replaceAll(',', '.'));
                    final reps = int.tryParse(repsController.text);

                    if (weight == null || reps == null) {
                      setStateDialog(() {
                        error = 'Introduz um peso e repetições válidos.';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, {
                      'weight': weight,
                      'reps': reps,
                    });
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final weight = (result['weight'] ?? 0).toDouble();
    final reps = (result['reps'] ?? 0).toInt();
    final exerciseId = exercise['id']?.toString() ?? exercise['name'];

    try {
      await sessionRef.collection('sets').add({
        'exerciseId': exerciseId,
        'exerciseName': exercise['name'],
        'weight': weight,
        'reps': reps,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await sessionRef.update({
        'totalSets': FieldValue.increment(1),
        'totalVolume': FieldValue.increment(weight * reps),
      });
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Erro ao adicionar set'),
          content: Text('Tenta novamente. Detalhes: $e'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _removeSet(
    DocumentReference<Map<String, dynamic>> sessionRef,
    QueryDocumentSnapshot<Map<String, dynamic>> setDoc,
    double weight,
    int reps,
  ) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remover set'),
        content: const Text('Queres mesmo eliminar este registo?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await setDoc.reference.delete();
      await sessionRef.update({
        'totalSets': FieldValue.increment(-1),
        'totalVolume': FieldValue.increment(-(weight * reps)),
      });
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Erro ao remover'),
          content: Text('Não foi possível eliminar o set: $e'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _finishSession(
    DocumentReference<Map<String, dynamic>> sessionRef,
  ) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Terminar sessão'),
        content: const Text(
            'Marcar a sessão como concluída impede novas alterações (podes reabrir mais tarde).'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => finishing = true);
      await sessionRef.update({
        'status': 'completed',
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Erro ao terminar sessão'),
          content: Text('Não foi possível concluir: $e'),
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
        setState(() => finishing = false);
      }
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
