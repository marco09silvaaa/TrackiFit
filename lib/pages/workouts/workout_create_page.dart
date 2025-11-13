import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'exercise_select_page.dart';

class WorkoutCreatePage extends StatefulWidget {
  const WorkoutCreatePage({super.key});

  @override
  State<WorkoutCreatePage> createState() => _WorkoutCreatePageState();
}

class _WorkoutCreatePageState extends State<WorkoutCreatePage> {
  final titleController = TextEditingController();
  final noteController = TextEditingController();
  final List<Map<String, dynamic>> selectedExercises = [];
  bool saving = false;

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Criar Treino'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: saving ? null : _saveWorkout,
          child: saving
              ? const CupertinoActivityIndicator()
              : const Text('Guardar'),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Workout Title',
                  style: TextStyle(color: CupertinoColors.white, fontSize: 16)),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: titleController,
                placeholder: 'Enter workout name...',
              ),
              const SizedBox(height: 16),
              const Text('Notas',
                  style: TextStyle(color: CupertinoColors.white, fontSize: 16)),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: noteController,
                placeholder: 'Detalhes do treino (opcional)',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Lista de exercícios escolhidos
              Expanded(
                child: selectedExercises.isEmpty
                    ? const Center(
                        child: Text(
                          'No exercises added yet',
                          style: TextStyle(color: CupertinoColors.inactiveGray),
                        ),
                      )
                    : ListView.builder(
                        itemCount: selectedExercises.length,
                        itemBuilder: (context, index) {
                          final ex = selectedExercises[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
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
                                      if (ex['muscleGroup'] != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
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
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      selectedExercises.removeAt(index);
                                    });
                                  },
                                  child: const Icon(
                                    CupertinoIcons.delete,
                                    color: CupertinoColors.destructiveRed,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () async {
                        // Abre página de seleção de exercícios
                        final result = await Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const ExerciseSelectPage(),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            final newExercises = (result as List)
                                .map<Map<String, dynamic>>((e) =>
                                    Map<String, dynamic>.from(
                                        e as Map<String, dynamic>))
                                .toList();
                            final existingIds = selectedExercises
                                .map((e) => e['id']?.toString() ?? e['name'])
                                .toSet();
                            for (final ex in newExercises) {
                              final id = ex['id']?.toString() ?? ex['name'];
                              if (existingIds.contains(id)) continue;
                              existingIds.add(id);
                              selectedExercises.add(ex);
                            }
                          });
                        }
                      },
                      child: const Text('+ Add Exercise'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveWorkout() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      await showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Título obrigatório'),
          content:
              const Text('Dá um nome ao treino antes de o guardares.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
      return;
    }

    if (selectedExercises.isEmpty) {
      await showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Nenhum exercício'),
          content: const Text(
              'Adiciona pelo menos um exercício para criar o treino.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Percebi'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      setState(() => saving = true);
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final workoutsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('workouts');

      await workoutsRef.add({
        'title': title,
        'note': noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'exercises': selectedExercises
            .map((e) => {
                  'id': e['id'],
                  'name': e['name'],
                  'muscleGroup': e['muscleGroup'],
                })
            .toList(),
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Erro ao guardar'),
          content: Text('Não foi possível guardar o treino: $e'),
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
        setState(() => saving = false);
      }
    }
  }
}
