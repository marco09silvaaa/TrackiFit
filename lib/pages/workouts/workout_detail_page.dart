import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show Divider;


class WorkoutDetailPage extends StatelessWidget {
  final String workoutId;
  const WorkoutDetailPage({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .doc(workoutId);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Workout'),
      ),
      child: SafeArea(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: docRef.get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (!snap.hasData || !snap.data!.exists) {
              return const Center(child: Text('Workout não encontrado.'));
            }
            final data = snap.data!.data()!;
            final title = data['title'] as String? ?? 'Sem título';
            final note = data['note'] as String? ?? '';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                if (createdAt != null)
                  Text('Criado em: ${createdAt.toLocal()}',
                      style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13)),
                const SizedBox(height: 16),
                if (note.isNotEmpty) Text(note),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                const Text('Exercícios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                  'Ainda não há exercícios aqui. (Vamos adicionar isto já a seguir!)',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
