import 'api_client.dart';
import '../models/class_slot.dart';

class PortalService {
  final _api = ApiClient();

  Future<List<ClassSlot>> getMyClasses() async {
    final data = await _api.get('/me/classes') as List;
    return data
        .map((e) => ClassSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}