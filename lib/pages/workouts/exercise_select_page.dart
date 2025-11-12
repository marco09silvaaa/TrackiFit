import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseSelectPage extends StatefulWidget {
  const ExerciseSelectPage({super.key});

  @override
  State<ExerciseSelectPage> createState() => _ExerciseSelectPageState();
}

class _ExerciseSelectPageState extends State<ExerciseSelectPage> {
  final Set<String> selectedIds = {}; // IDs dos exercícios selecionados
  final List<Map<String, dynamic>> selected = []; // Dados para retornar

  @override
  Widget build(BuildContext context) {
    final exercisesRef = FirebaseFirestore.instance
        .collection('exercises')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (value, _) => value,
        );

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Adicionar Exercício'),
      ),
      backgroundColor: const Color(0xFF0E0E0F),
      child: SafeArea(
        child: Column(
          children: [
            // 🔹 Lista de exercícios
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: exercisesRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro: ${snapshot.error}',
                        style: const TextStyle(color: CupertinoColors.systemRed),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
                  }

                  final exercises = snapshot.data?.docs ?? [];

                  if (exercises.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum exercício encontrado.',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final doc = exercises[index];
                      final data = doc.data();
                      final id = doc.id;
                      final name = data['name'] ?? 'Unnamed Exercise';
                      final muscle = data['muscleGroup'] ?? '';
                      final selectedFlag = selectedIds.contains(id);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selectedFlag) {
                              selectedIds.remove(id);
                              selected.removeWhere((e) => e['id'] == id);
                            } else {
                              selectedIds.add(id);
                              selected.add({'id': id, ...data});
                            }
                          });
                        },
                        child: Container(
                          color: const Color(0xFF0E0E0F),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 🔹 Linha azul à esquerda se estiver selecionado
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 4,
                                height: 70,
                                color: selectedFlag
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.transparent,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        muscle,
                                        style: const TextStyle(
                                          color: CupertinoColors.systemGrey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(
                                  CupertinoIcons.arrow_up_right,
                                  color: CupertinoColors.systemGrey2,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 🔹 Botão dinâmico inferior
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CupertinoButton.filled(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, selected),
                child: Text(
                  selected.isEmpty
                      ? 'Selecionar exercícios'
                      : 'Adicionar ${selected.length} exercício${selected.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
