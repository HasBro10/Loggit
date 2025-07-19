import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // SECURITY: API key should be set via environment variable
  // Run with: flutter run --dart-define=GROQ_API_KEY=your_actual_key_here
  // Or set in your IDE's run configuration
  static const String _groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE',
  );
  static const String _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';

  static const String _systemPrompt = '''
You are Loggit, an AI assistant for managing tasks, reminders, and expenses. Your job is to extract the user's intent and all relevant details from their message, no matter the word order or phrasing.

RULES:
- Always extract the main intent: create_task, create_reminder, log_expense, view_reminders, or view_tasks.
- Always extract the title or description (e.g., "bowling", "doctor appointment").
- Always extract the due date or reminder date if mentioned (e.g., "tomorrow", "1st of August", "next Monday").
- Always extract the time if mentioned (e.g., "9 pm", "21:00").
- For reminder queries, extract the timeframe (e.g., "this week", "today", "tomorrow", "next month", "this month", "next 2 weeks", "next 3 weeks", "all").
- Ignore the order of words; the user may say date/time before or after the title.
- Remove all date/time words from the title.
- For expenses, extract the amount and category if present.
- If user provides only time (like "7 pm", "9:30 am") and there's no clear context, assume they want to create a reminder for that time today.
- Respond ONLY with a single valid JSON object, no comments or extra text.

EXAMPLES:
User: create a task for the 1st of August bowling at 9 pm
Response: {"intent": "create_task", "fields": {"title": "bowling", "dueDate": "2025-08-01", "timeOfDay": "21:00"}}

User: create a reminder for the 27th of August to call John at 1 pm
Response: {"intent": "create_reminder", "fields": {"title": "call John", "reminderDate": "2025-08-27", "reminderTime": "13:00"}}

User: remind me tomorrow at 8 am to call mum
Response: {"intent": "create_reminder", "fields": {"title": "call mum", "reminderTime": "tomorrow 08:00"}}

User: create a task for August 15th meeting at 3 pm
Response: {"intent": "create_task", "fields": {"title": "meeting", "dueDate": "2025-08-15", "timeOfDay": "15:00"}}

User: remind me on the 10th of September to buy groceries at 5 pm
Response: {"intent": "create_reminder", "fields": {"title": "buy groceries", "reminderDate": "2025-09-10", "reminderTime": "17:00"}}

User: create a reminder for the 5th of January 2026 to call Peter
Response: {"intent": "create_reminder", "fields": {"title": "call Peter", "reminderDate": "2026-01-05"}}

User: log expense coffee 3.50
Response: {"intent": "log_expense", "fields": {"title": "coffee", "amount": 3.50}}

User: show me this week's reminders
Response: {"intent": "view_reminders", "fields": {"timeframe": "this week"}}

User: what are my reminders for today
Response: {"intent": "view_reminders", "fields": {"timeframe": "today"}}

User: tell me tomorrow's reminders
Response: {"intent": "view_reminders", "fields": {"timeframe": "tomorrow"}}

User: show me next month's reminders
Response: {"intent": "view_reminders", "fields": {"timeframe": "next month"}}

User: what are my reminders for this month
Response: {"intent": "view_reminders", "fields": {"timeframe": "this month"}}

User: show me all my reminders
Response: {"intent": "view_reminders", "fields": {"timeframe": "all"}}

User: list all reminders
Response: {"intent": "view_reminders", "fields": {"timeframe": "all"}}

User: what are my reminders for the next 2 weeks
Response: {"intent": "view_reminders", "fields": {"timeframe": "next 2 weeks"}}

User: show me reminders for the next 3 weeks
Response: {"intent": "view_reminders", "fields": {"timeframe": "next 3 weeks"}}

User: what are my reminders for the next 5 weeks
Response: {"intent": "view_reminders", "fields": {"timeframe": "next 5 weeks"}}

User: show me my tasks for this week
Response: {"intent": "view_tasks", "fields": {"timeframe": "this week"}}

User: what are my tasks for today
Response: {"intent": "view_tasks", "fields": {"timeframe": "today"}}

User: show me my tasks for tomorrow
Response: {"intent": "view_tasks", "fields": {"timeframe": "tomorrow"}}

User: what are my tasks for next week
Response: {"intent": "view_tasks", "fields": {"timeframe": "next week"}}

User: show me all my tasks
Response: {"intent": "view_tasks", "fields": {"timeframe": "all"}}

User: 7 pm
Response: {"intent": "create_reminder", "fields": {"title": "reminder", "reminderTime": "today 19:00"}}

User: 9:30 am
Response: {"intent": "create_reminder", "fields": {"title": "reminder", "reminderTime": "today 09:30"}}

User: 3:45 pm
Response: {"intent": "create_reminder", "fields": {"title": "reminder", "reminderTime": "today 15:45"}}
''';

  static Future<Map<String, dynamic>> processUserMessage(String message) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_groqApiKey',
    };
    final body = jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': message},
      ],
      'max_tokens': 512,
      'temperature': 0.2,
    });
    try {
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        try {
          return jsonDecode(content);
        } catch (e) {
          print('DEBUG: Failed to parse AI response: ${e.toString()}');
          return {'error': 'Failed to parse AI response', 'raw': content};
        }
      } else {
        print(
          'DEBUG: Groq API error. Status: ${response.statusCode}, Body: ${response.body}',
        );
        return {
          'error': 'Groq API error',
          'status': response.statusCode,
          'body': response.body,
        };
      }
    } catch (e) {
      print('DEBUG: Exception in Groq API call: ${e.toString()}');
      return {'error': 'Exception in Groq API call', 'exception': e.toString()};
    }
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_groqEndpoint/api/tags'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
