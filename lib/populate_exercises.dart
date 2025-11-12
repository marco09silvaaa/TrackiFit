import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> populateExercises() async {
  final firestore = FirebaseFirestore.instance;
  final exercisesCollection = firestore.collection('exercises');

  final List<Map<String, dynamic>> exercises = [
    {
      'name': 'Incline Bench Press (Dumbbell)',
      'muscleGroup': 'Chest',
      'equipment': 'Dumbbell',
      'imageUrl': '',
    },
    {
      'name': 'Pec Deck Machine (Fly)',
      'muscleGroup': 'Chest',
      'equipment': 'Machine',
      'imageUrl': '',
    },
    {
      'name': 'Lat Pulldown',
      'muscleGroup': 'Back',
      'equipment': 'Machine',
      'imageUrl': '',
    },
    {
      'name': 'Seated Row (Iso-Lateral Machine)',
      'muscleGroup': 'Upper Back',
      'equipment': 'Machine',
      'imageUrl': '',
    },
    {
      'name': 'Preacher Curl (Barbell)',
      'muscleGroup': 'Biceps',
      'equipment': 'Barbell',
      'imageUrl': '',
    },
    {
      'name': 'Hammer Curl (Rope Cable)',
      'muscleGroup': 'Biceps',
      'equipment': 'Cable',
      'imageUrl': '',
    },
    {
      'name': 'Triceps Pushdown (Cable)',
      'muscleGroup': 'Triceps',
      'equipment': 'Cable',
      'imageUrl': '',
    },
    {
      'name': 'Shoulder Press (Seated Machine)',
      'muscleGroup': 'Shoulders',
      'equipment': 'Machine',
      'imageUrl': '',
    },
    {
      'name': 'Lateral Raise (Dumbbell)',
      'muscleGroup': 'Shoulders',
      'equipment': 'Dumbbell',
      'imageUrl': '',
    },
    {
      'name': 'Barbell Squat',
      'muscleGroup': 'Legs',
      'equipment': 'Barbell',
      'imageUrl': '',
    },
  ];


  for (final exercise in exercises) {
    await exercisesCollection.add(exercise);
  }

  print('✅ Exercícios adicionados com sucesso!');
}
