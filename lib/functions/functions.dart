import 'dart:convert';
import 'package:azuracastadmin/models/cpustats.dart';
import 'package:azuracastadmin/models/historyfiles.dart';
import 'package:azuracastadmin/models/listeners.dart';
import 'package:azuracastadmin/models/listoffiles.dart';
import 'package:azuracastadmin/models/nextsongs.dart';
import 'package:azuracastadmin/models/nowplaying.dart';
import 'package:azuracastadmin/models/radiostations.dart';
import 'package:azuracastadmin/models/stationsstatus.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

void printError(String text) {
  print('\x1B[31m$text\x1B[0m');
}

void printWarning(String text) {
  print('\x1B[33m$text\x1B[0m');
}

Future<Response> getResponse({
  required String url,
  required String path,
  String? apiKey,
  int? id,
}) async {
  var response;
  if (apiKey != null && id == null) {
    final headers = {
      'accept': 'application/json',
      'X-API-Key': '${apiKey}',
    };
    response =
        await http.get(Uri.parse('${url}/api/${path}'), headers: headers);
  } else if (id != null && apiKey == null) {
    response = await http.get(Uri.parse('${url}/api/${path}/${id}'));
  } else if (apiKey != null && id != null) {
    final headers = {
      'accept': 'application/json',
      'X-API-Key': '${apiKey}',
    };
    response = await http.get(Uri.parse('${url}/api/station/${id}/${path}'),
        headers: headers);
  } else {
    response = await http.get(Uri.parse('${url}/api/${path}'));
  }

  return response;
}

Future<CpuStats> fetchCpuStats(String url, String path, String apiKey) async {
  Response response = await getResponse(url: url, path: path, apiKey: apiKey);
  if (response.statusCode == 200) {
    CpuStats cpuStats = CpuStats.fromJson(jsonDecode(response.body));
    return cpuStats;
  } else {
    throw Exception('Failed');
  }
}

Future<List<RadioStations>> fetchRadioStations(String url, String path) async {
  Response response = await getResponse(url: url, path: path);
  if (response.statusCode == 200) {
    List<RadioStations> radioStations = (json.decode(response.body) as List)
        .map((i) => RadioStations.fromJson(i))
        .toList();

    return radioStations;
  } else {
    throw Exception('Failed');
  }
}

Future<NowPlaying> fetchNowPlaying(String url, String path, int id) async {
  Response response = await getResponse(url: url, path: path, id: id);
  if (response.statusCode == 200) {
    return NowPlaying.fromJson(jsonDecode(response.body));
  } else {
    printError('error here id ${id}');
    throw Exception('Failed');
  }
}

Future<List<NextSongs>> fetchNextSongs(
    String url, String path, String apiKey, int id) async {
  Response response =
      await getResponse(url: url, path: path, apiKey: apiKey, id: id);
  if (response.statusCode == 200) {
    List<NextSongs> nextSongs = (json.decode(response.body) as List)
        .map((i) => NextSongs.fromJson(i))
        .toList();

    return nextSongs;
  } else {
    throw Exception('Failed');
  }
}

Future<StationStatus> fetchStatus(
    String url, String path, String apiKey, int id) async {
  final headers = {
    'accept': 'application/json',
    'X-API-Key': '${apiKey}',
  };
  var response = await http.get(Uri.parse('${url}/api/station/${id}/${path}'),
      headers: headers);
  if (response.statusCode == 200) {
    return StationStatus.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed');
  }
}

Future<Response> postAdminActions(
    String url, String path, String apiKey, int id, String action) async {
  var response = await http.post(headers: <String, String>{
    'accept': 'application/json',
    'X-API-Key': '${apiKey}',
  }, Uri.parse('${url}/api/station/${id}/${path}/${action}'));
  return response;
}

Future<List<ActiveListeners>> fetchListeners(
    String url, String path, String apiKey, int id) async {
  Response response =
      await getResponse(url: url, path: path, apiKey: apiKey, id: id);
  if (response.statusCode == 200) {
    List<ActiveListeners> activeListeners = (json.decode(response.body) as List)
        .map((i) => ActiveListeners.fromJson(i))
        .toList();

    return activeListeners;
  } else {
    throw Exception('Failed');
  }
}

Future<List<ListOfFiles>> fetchListOfFiles(
    String url, String path, String apiKey, int id) async {
  Response response =
      await getResponse(url: url, path: path, apiKey: apiKey, id: id);
  if (response.statusCode == 200) {
    List<ListOfFiles> listOfFiles = (json.decode(response.body) as List)
        .map((i) => ListOfFiles.fromJson(i))
        .toList();

    return listOfFiles;
  } else {
    throw Exception('Failed');
  }
}

Future<List<HistoryFiles>> fetchHistoryFiles(
    String url, String apiKey, int id, String startDate, String endDate) async {
  final headers = {
    'accept': 'application/json',
    'X-API-Key': '${apiKey}',
  };
  Response response = await http.get(
      Uri.parse(
          '${url}/api/station/${id}/history?start=${startDate}&end=${endDate}'),
      headers: headers);
  printError('respo is ${response.body}');
  if (response.statusCode == 200) {
    List<HistoryFiles> historyFiles = (json.decode(response.body) as List)
        .map((i) => HistoryFiles.fromJson(i))
        .toList();

    return historyFiles;
  } else {
    throw Exception('Failed');
  }
}
