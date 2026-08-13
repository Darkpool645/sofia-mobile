import 'api_client.dart';
import '../models/group.dart';
import '../models/school_year.dart';

class GroupsService {
  final _api = ApiClient();

  Future<List<SchoolYear>> getSchoolYears() async {
    final data = await _api.get('/school-years') as List;
    return data.map((e) => SchoolYear.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SchoolYear> createSchoolYear({
    required String name,
    required String startDate,
    required String endDate,
    bool active = true,
  }) async {
    final data = await _api.post('/school-years', {
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'active': active,
    }) as Map<String, dynamic>;
    return SchoolYear.fromJson(data);
  }

  Future<List<Group>> getGroups() async {
    final data = await _api.get('/groups') as List;
    return data.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Group> createGroup({
    required String name,
    required String schoolYearId,
  }) async {
    final data = await _api.post('/groups', {
      'name': name,
      'schoolYearId': schoolYearId,
    }) as Map<String, dynamic>;
    return Group.fromJson(data);
  }
}