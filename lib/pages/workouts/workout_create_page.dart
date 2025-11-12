// lib/pages/workouts/workout_create_page.dart
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutCreatePage extends StatefulWidget {
  const WorkoutCreatePage({super.key});

  @override
  State<WorkoutCreatePage> createState() => _WorkoutCreatePageState();
}

class _WorkoutCreatePageState extends State<WorkoutCreatePage> {
  final titleCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  bool isSaving = false;

  Future<void> _save() async {
    final title = titleCtrl.text.trim();
    final note = noteCtrl.text.trim();

    if (title.isEmpty) {
      _alert('O título é obrigatório.');
      return;
    }

    setState(() => isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final workoutsCol = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('workouts');

      await workoutsCol.add({
        'title': title,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        // espaço futuro para exercícios:
        // 'exercises': [],
      });

      Navigator.pop(context); // volta para a lista
    } catch (e) {
      _alert('Falha ao criar workout: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _alert(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Aviso'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Criar Workout'),
        trailing: isSaving
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _save,
                child: const Text('Guardar'),
              ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CupertinoTextField(
                controller: titleCtrl,
                placeholder: 'Título (ex: Costas + Bíceps)',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: noteCtrl,
                placeholder: 'Notas (opcional)',
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
