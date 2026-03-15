import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/firebase/firestore_service.dart';

class SocialRepository {
  SocialRepository({
    LocalDatabaseService? localDatabaseService,
    FirestoreService? firestoreService,
  })  : _localDatabaseService =
            localDatabaseService ?? LocalDatabaseService.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  final LocalDatabaseService _localDatabaseService;
  final FirestoreService _firestoreService;
}
