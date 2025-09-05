import 'dart:convert';
import 'package:http/http.dart' as http;

class NotionService {
  static const String _baseUrl = 'https://api.notion.com/v1';
  String? _apiKey;
  String? _databaseId;
  
  void setCredentials(String apiKey, String databaseId) {
    _apiKey = apiKey;
    _databaseId = databaseId;
  }
  
  Future<List<Map<String, dynamic>>> getTasks(DateTime startDate, DateTime endDate) async {
    try {
      if (_apiKey == null || _databaseId == null) {
        throw Exception('Notion credentials not set');
      }
      
      final url = Uri.parse('$_baseUrl/databases/$_databaseId/query');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Notion-Version': '2022-06-28',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'filter': {
            'and': [
              {
                'property': 'Date',
                'date': {
                  'on_or_after': startDate.toIso8601String().split('T')[0],
                },
              },
              {
                'property': 'Date',
                'date': {
                  'on_or_before': endDate.toIso8601String().split('T')[0],
                },
              },
            ],
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        
        return results.map((item) {
          final properties = item['properties'];
          return {
            'id': 'notion_${item['id']}',
            'title': _extractTitle(properties),
            'startTime': _extractDateTime(properties, 'Start Time'),
            'endTime': _extractDateTime(properties, 'End Time'),
            'description': _extractText(properties, 'Description'),
            'source': 'notion',
          };
        }).toList();
      } else {
        print('Notion API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Notion Service Error: $e');
      return [];
    }
  }
  
  String _extractTitle(Map<String, dynamic> properties) {
    final titleProperty = properties['Title'] ?? properties['Name'];
    if (titleProperty != null && titleProperty['title'] != null) {
      final titleArray = titleProperty['title'] as List;
      if (titleArray.isNotEmpty) {
        return titleArray[0]['text']['content'] ?? 'Untitled';
      }
    }
    return 'Untitled';
  }
  
  String? _extractText(Map<String, dynamic> properties, String propertyName) {
    final property = properties[propertyName];
    if (property != null && property['rich_text'] != null) {
      final richTextArray = property['rich_text'] as List;
      if (richTextArray.isNotEmpty) {
        return richTextArray[0]['text']['content'];
      }
    }
    return null;
  }
  
  DateTime _extractDateTime(Map<String, dynamic> properties, String propertyName) {
    final property = properties[propertyName];
    if (property != null && property['date'] != null) {
      final dateString = property['date']['start'];
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
    }
    return DateTime.now();
  }
  
  Future<bool> authenticate(String apiKey, String databaseId) async {
    try {
      setCredentials(apiKey, databaseId);
      
      // 간단한 API 호출로 인증 확인
      final url = Uri.parse('$_baseUrl/databases/$databaseId');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Notion-Version': '2022-06-28',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Notion Authentication Error: $e');
      return false;
    }
  }
}


