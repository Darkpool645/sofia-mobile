import 'api_client.dart';
import '../models/family.dart';

class FamilyService {
  final _api = ApiClient();

  Future<List<FamilyChild>> getChildren() async {
    final data = await _api.get('/me/children') as List;
    return data
        .map((e) => FamilyChild.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FeedItem>> getFeed(String childId) async {
    final data = await _api.get('/me/feed?childId=$childId') as List;
    return data
        .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}