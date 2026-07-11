import 'dart:developer';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    final res = await dio.get(
      'https://api.football-data.org/v4/matches',
      options: Options(headers: {'X-Auth-Token': 'e928923cbe254e8093f3e05ad42b9931'})
    );
    log("Success: \${res.data['matches'].length} matches found.");
  } catch(e) {
    log("Error: \$e");
  }
}
