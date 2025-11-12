import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'exercise_select_page.dart'; // página que vais criar a seguir

class WorkoutCreatePage extends StatefulWidget {
  const WorkoutCreatePage({super.key});

  @override
  State<WorkoutCreatePage> createState() => _WorkoutCreatePageState();
}

class _WorkoutCreatePageState extends State<WorkoutCreatePage> {
  final titleController = TextEditingController();
  final List<Map<String, dynamic>> selectedExercises = [];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Create Workout'),
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              ex['name'],
                              style: const TextStyle(
                                  color: CupertinoColors.white, fontSize: 18),
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
                            selectedExercises.addAll(result);
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
}
