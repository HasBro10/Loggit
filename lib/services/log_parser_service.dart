typedef DeleteIntent = Map<String, dynamic>;

enum LogType { reminder, task, gym, expense, unknown }

class ParsedLog {
  final LogType type;
  final String? action;
  final DateTime? dateTime;
  final double? amount;
  final String? category;
  final String? recurrence;
  final String? raw;
  final bool hasTime; // true if time was present in the input

  ParsedLog({
    required this.type,
    this.action,
    this.dateTime,
    this.amount,
    this.category,
    this.recurrence,
    this.raw,
    this.hasTime = true,
  });
}

class LogParserService {
  static ParsedLog parseUserInput(String input) {
    final normalized = input.trim().toLowerCase();

    // Patterns for each type (add more as you learn)
    final patterns = [
      // Reminders
      {
        'type': LogType.reminder,
        // (1) trigger, (2) to/for, (3) action, (4) date/time
        'regex': RegExp(
          r'(remind me|set reminder|create reminder|reminder|set a reminder|create a reminder|add reminder|new reminder|set up reminder|put reminder|add a reminder|schedule a reminder|set up a reminder|remind me to|remind me about|remind me of)?(?:\s*(to|for))?\s*(.+?)\s*(tomorrow|at\s+\d{1,2}(:\d{2})?\s*(am|pm)?|on\s+\w+|\d{1,2}(st|nd|rd|th)?|next\s+\w+|\d{1,2}(:\d{2})?\s*(am|pm)?\s+\d{1,2}(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)|\d{1,2}(:\d{2})?\s*(am|pm)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}(st|nd|rd|th)?)?$',
          caseSensitive: false,
        ),
      },
      // Standalone time input (for when user just types a time)
      {
        'type': LogType.reminder,
        'regex': RegExp(
          r'^(at\s+)?(\d{1,2})(:(\d{2}))?\s*(am|pm)?$',
          caseSensitive: false,
        ),
      },
      // Standalone date input (for when user just types a date)
      {
        'type': LogType.reminder,
        'regex': RegExp(
          r'^(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)$',
          caseSensitive: false,
        ),
      },
      // Standalone date input (month day format)
      {
        'type': LogType.reminder,
        'regex': RegExp(
          r'^(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(st|nd|rd|th)?$',
          caseSensitive: false,
        ),
      },
      // Combined time and date input (for when user types both together)
      {
        'type': LogType.reminder,
        'regex': RegExp(
          r'^(at\s+)?(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s+(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)$',
          caseSensitive: false,
        ),
      },
      // Combined time and date input (month day format)
      {
        'type': LogType.reminder,
        'regex': RegExp(
          r'^(at\s+)?(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(st|nd|rd|th)?$',
          caseSensitive: false,
        ),
      },
      // Tasks
      {
        'type': LogType.task,
        // (1) trigger, (2) to/for, (3) action, (4) date/time
        'regex': RegExp(
          r'(add|create|set) (a )?task(?:\s*(to|for))?\s*(.+?)\s*(tomorrow|at\s+\d{1,2}(:\d{2})?\s*(am|pm)?|on\s+\w+|\d{1,2}(st|nd|rd|th)?|next\s+\w+)?$',
          caseSensitive: false,
        ),
      },
      // Expenses
      {
        'type': LogType.expense,
        // (1) trigger, (2) amount, (3) decimal, (4) category
        'regex': RegExp(
          r'(spent|pay|bought|purchase|expense)[^a-zA-Z0-9]*(\d+(?:\.\d+)?)(?: on )?(.*)?',
          caseSensitive: false,
        ),
      },
      // Gym logs
      {
        'type': LogType.gym,
        // (1) trigger, (2) action, (3) datetime
        'regex': RegExp(
          r'(gym|workout|exercise|did|completed)[^a-zA-Z0-9]*(.+?)(?: at | on | for )?(.*)?',
          caseSensitive: false,
        ),
      },
    ];

    for (final pattern in patterns) {
      final regex = pattern['regex'] as RegExp;
      final match = regex.firstMatch(normalized);
      if (match != null) {
        print('DEBUG: Full match: ${match.group(0)}');
        for (int i = 0; i <= match.groupCount; i++) {
          print('DEBUG: Group $i: ${match.group(i)}');
        }
        final type = pattern['type'] as LogType;
        String? action;
        String? dateTimeStr;
        String? amountStr;
        String? category;
        bool hasTime = true;
        switch (type) {
          case LogType.reminder:
          case LogType.task:
            // Check if this is a standalone time input first
            print(
              'DEBUG: Checking standalone time - groupCount: ${match.groupCount}',
            );
            print(
              'DEBUG: Group 1: ${match.group(1)}, Group 3: ${match.group(3)}',
            );

            // Simple check: if the entire input matches the standalone time pattern
            final standaloneTimePattern = RegExp(
              r'^(at\s+)?(\d{1,2})(:(\d{2}))?\s*(am|pm)?$',
              caseSensitive: false,
            );
            if (standaloneTimePattern.hasMatch(input.toLowerCase())) {
              print('DEBUG: Input matches standalone time pattern');
              final timeMatch = standaloneTimePattern.firstMatch(
                input.toLowerCase(),
              );
              if (timeMatch != null) {
                int hour = int.parse(timeMatch.group(2)!);
                int minute = timeMatch.group(4) != null
                    ? int.parse(timeMatch.group(4)!)
                    : 0;
                final ampm = timeMatch.group(5);
                if (ampm == 'pm' && hour < 12) hour += 12;
                if (ampm == 'am' && hour == 12) hour = 0;

                final now = DateTime.now();
                return ParsedLog(
                  type: LogType.reminder,
                  action: null,
                  dateTime: DateTime(
                    now.year,
                    now.month,
                    now.day,
                    hour,
                    minute,
                  ),
                  hasTime: true,
                  raw: input,
                );
              }
            }

            if (match.groupCount == 4 &&
                match.group(1) == null &&
                match.group(3) == null) {
              // This is a standalone time input (like "6 pm")
              final timeMatch = RegExp(
                r'^(at\s+)?(\d{1,2})(:(\d{2}))?\s*(am|pm)?$',
                caseSensitive: false,
              ).firstMatch(input.toLowerCase());
              if (timeMatch != null) {
                int hour = int.parse(timeMatch.group(2)!);
                int minute = timeMatch.group(4) != null
                    ? int.parse(timeMatch.group(4)!)
                    : 0;
                final ampm = timeMatch.group(5);
                if (ampm == 'pm' && hour < 12) hour += 12;
                if (ampm == 'am' && hour == 12) hour = 0;

                final now = DateTime.now();
                return ParsedLog(
                  type: LogType.reminder,
                  action: null,
                  dateTime: DateTime(
                    now.year,
                    now.month,
                    now.day,
                    hour,
                    minute,
                  ),
                  hasTime: true,
                  raw: input,
                );
              }
            }
            // Check if this is a standalone date input
            if (match.groupCount == 2 &&
                (match.group(1) != null || match.group(2) != null)) {
              // This could be a standalone date input (like "15th July" or "15 July")
              final dtResult = parseSimpleDateTimeWithTimeFlag(input);
              if (dtResult.dateTime != null) {
                return ParsedLog(
                  type: LogType.reminder,
                  action: null,
                  dateTime: dtResult.dateTime,
                  hasTime: dtResult.hasTime,
                  raw: input,
                );
              }
            }
            // Check if this is a combined time and date input
            if (match.groupCount >= 6) {
              // This could be a combined time and date input (like "6 pm 15 July")
              print(
                'DEBUG: Detected potential combined time+date input: $input',
              );
              final dtResult = parseSimpleDateTimeWithTimeFlag(input);
              if (dtResult.dateTime != null) {
                print(
                  'DEBUG: Successfully parsed combined time+date: ${dtResult.dateTime}, hasTime: ${dtResult.hasTime}',
                );
                return ParsedLog(
                  type: LogType.reminder,
                  action: null,
                  dateTime: dtResult.dateTime,
                  hasTime: dtResult.hasTime,
                  raw: input,
                );
              }
            }
            // --- Enhanced action extraction logic ---
            action = match.group(3) != null ? match.group(3)!.trim() : null;
            dateTimeStr = match.group(4) != null
                ? match.group(4)!.trim()
                : null;
            print('DEBUG: Extracted action: $action');
            print('DEBUG: Extracted dateTimeStr: $dateTimeStr');
            // If 'tomorrow' is present anywhere in the input, ensure dateTimeStr includes it
            if (input.toLowerCase().contains('tomorrow')) {
              dateTimeStr =
                  'tomorrow' +
                  (dateTimeStr != null && dateTimeStr.isNotEmpty
                      ? ' ' + dateTimeStr
                      : '');
              print(
                'DEBUG: Overriding dateTimeStr to include "tomorrow": $dateTimeStr',
              );
            }
            // --- New: Post-process action for multi-sentence and filler removal ---
            if (action != null) {
              // 1. If input contains multiple sentences, use the last non-empty, non-date/time sentence as the action
              final sentences = action.split(RegExp(r'[.!?]'));
              String? candidateAction;
              final dateTimeWords = [
                'tomorrow',
                'today',
                'yesterday',
                'tonight',
                'morning',
                'afternoon',
                'evening',
                'at',
                'on',
                'next',
                'am',
                'pm',
              ];
              for (var i = sentences.length - 1; i >= 0; i--) {
                final s = sentences[i].trim();
                // Skip empty or date/time-only sentences
                if (s.isEmpty) continue;
                final isDateTimeOnly = dateTimeWords.any(
                  (w) =>
                      RegExp(
                        '^' + w + r'(\s|$)',
                        caseSensitive: false,
                      ).hasMatch(s) &&
                      s
                          .replaceAll(RegExp(w, caseSensitive: false), '')
                          .trim()
                          .isEmpty,
                );
                if (!isDateTimeOnly) {
                  candidateAction = s;
                  break;
                }
              }
              if (candidateAction != null && candidateAction.isNotEmpty) {
                action = candidateAction;
              }
              // 2. Remove leading filler phrases
              action = action.replaceFirst(
                RegExp(
                  r'^(i need to|i have to|i must|please|can you|could you|would you|i want to|i should|i will|i am going to|i gotta|i got to|i ought to|i wish to|i plan to|i intend to|i would like to)\s+',
                  caseSensitive: false,
                ),
                '',
              );
              // 3. Remove all standalone date/time words (e.g., 'tomorrow', 'at 2 pm', etc.)
              action = action
                  .replaceAll(
                    RegExp(
                      r'\b(tomorrow|today|yesterday|tonight|morning|afternoon|evening|at\s+\d{1,2}(:\d{2})?\s*(am|pm)?|on\s+\w+|\d{1,2}(st|nd|rd|th)?|next\s+\w+|am|pm)\b',
                      caseSensitive: false,
                    ),
                    '',
                  )
                  .trim();
              // 4. Remove any leading/trailing punctuation or whitespace
              action = action.replaceAll(
                RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'),
                '',
              );
            }
            // --- End enhanced action extraction ---
            // Semantic mapping for natural titles
            if (action != null) {
              final actionMappings = {
                RegExp(r'go to the doctor(s)?', caseSensitive: false):
                    "doctor's appointment",
                RegExp(r'go to the dentist', caseSensitive: false):
                    "dentist appointment",
                RegExp(r'car wash', caseSensitive: false): "car wash",
                RegExp(r'meet (a )?friend(s)?', caseSensitive: false):
                    "meet with friends",
                RegExp(r'restaurant|dinner reservation', caseSensitive: false):
                    "restaurant reservation",
                RegExp(r'work meeting|team meeting', caseSensitive: false):
                    "work meeting",
                RegExp(r'buy groceries|grocery shopping', caseSensitive: false):
                    "grocery shopping",
                RegExp(r'call (.+)', caseSensitive: false): (Match m) =>
                    "call ${m.group(1)}",
                RegExp(r'email (.+)', caseSensitive: false): (Match m) =>
                    "email ${m.group(1)}",
                RegExp(r'pay bills?', caseSensitive: false): "pay bills",
                RegExp(r'pick up (kids?|child)', caseSensitive: false):
                    "pick up kids",
                RegExp(r'walk the dog', caseSensitive: false): "walk the dog",
                RegExp(r'take medicine|take pills', caseSensitive: false):
                    "take medicine",
                RegExp(r'birthday( party)?', caseSensitive: false):
                    "birthday party",
                RegExp(r'anniversary( dinner)?', caseSensitive: false):
                    "anniversary",
                RegExp(r'gym|workout|exercise', caseSensitive: false):
                    "gym session",
                RegExp(r'laundry|do laundry', caseSensitive: false): "laundry",
                RegExp(r'clean (house|the house)', caseSensitive: false):
                    "clean house",
                RegExp(r'study( session)?', caseSensitive: false):
                    "study session",
                RegExp(r'submit report|send report', caseSensitive: false):
                    "submit report",
                RegExp(
                  r'renew (insurance|car insurance)',
                  caseSensitive: false,
                ): "renew insurance",
                RegExp(r'pay rent', caseSensitive: false): "pay rent",
                RegExp(r'book (flight|hotel)', caseSensitive: false):
                    "book travel",
                RegExp(r'grocery delivery', caseSensitive: false):
                    "grocery delivery",
                RegExp(r'hair (appointment|cut|haircut)', caseSensitive: false):
                    "hair appointment",
                RegExp(r'vet appointment', caseSensitive: false):
                    "vet appointment",
                RegExp(r'parent(-| )teacher meeting', caseSensitive: false):
                    "parent-teacher meeting",
                RegExp(r'shopping|go shopping', caseSensitive: false):
                    "shopping",
                RegExp(r'movie night|go to the movies', caseSensitive: false):
                    "movie night",
                RegExp(r'pick up (parcel|package)', caseSensitive: false):
                    "pick up parcel",
                RegExp(r'dentist cleaning', caseSensitive: false):
                    "dentist appointment",
                RegExp(r'oil change', caseSensitive: false): "car maintenance",
                RegExp(r'renew passport', caseSensitive: false):
                    "renew passport",
                RegExp(r'pay credit card', caseSensitive: false):
                    "pay credit card",
                RegExp(r'send flowers', caseSensitive: false): "send flowers",
                RegExp(r'volunteer(ing)?', caseSensitive: false):
                    "volunteering",
                RegExp(r'meditation|meditate', caseSensitive: false):
                    "meditation",
                RegExp(r'yoga class', caseSensitive: false): "yoga class",
                RegExp(r'book club', caseSensitive: false): "book club",
                RegExp(r'parent meeting', caseSensitive: false):
                    "parent meeting",
                RegExp(
                  r'soccer practice|football practice',
                  caseSensitive: false,
                ): "soccer practice",
                RegExp(r'piano lesson|music lesson', caseSensitive: false):
                    "music lesson",
                RegExp(r'library visit', caseSensitive: false): "library visit",
                RegExp(r'walk the cat', caseSensitive: false): "walk the cat",
                RegExp(r'feed the (dog|cat|pets?)', caseSensitive: false):
                    "feed pets",
                RegExp(r'change lightbulb', caseSensitive: false):
                    "change lightbulb",
                RegExp(r'water (plants|the plants)', caseSensitive: false):
                    "water plants",
                RegExp(r'charge (phone|laptop|device)', caseSensitive: false):
                    "charge device",
                RegExp(r'backup (phone|computer|device)', caseSensitive: false):
                    "backup device",
                RegExp(r'update (software|app)', caseSensitive: false):
                    "update software",
                RegExp(r'car (mot|inspection)', caseSensitive: false):
                    "car inspection",
                RegExp(r'renew driving license', caseSensitive: false):
                    "renew driving license",
                RegExp(r'pay parking ticket', caseSensitive: false):
                    "pay parking ticket",
                RegExp(r'dentist checkup', caseSensitive: false):
                    "dentist appointment",
                RegExp(r'eye exam|optician appointment', caseSensitive: false):
                    "eye exam",
                RegExp(r'get groceries delivered', caseSensitive: false):
                    "grocery delivery",
                RegExp(r'take out (trash|rubbish)', caseSensitive: false):
                    "take out trash",
                RegExp(r'recycling day', caseSensitive: false): "recycling day",
                RegExp(r'meal prep|meal planning', caseSensitive: false):
                    "meal prep",
                RegExp(r'pack lunch', caseSensitive: false): "pack lunch",
                RegExp(r'school run', caseSensitive: false): "school run",
                RegExp(r'after school club', caseSensitive: false):
                    "after school club",
                RegExp(r'football match|soccer match', caseSensitive: false):
                    "football match",
                RegExp(r'swimming lesson', caseSensitive: false):
                    "swimming lesson",
                RegExp(r'driving lesson', caseSensitive: false):
                    "driving lesson",
                RegExp(
                  r'renew netflix|renew subscription',
                  caseSensitive: false,
                ): "renew subscription",
                RegExp(r'pay council tax', caseSensitive: false):
                    "pay council tax",
                RegExp(r'pay water bill', caseSensitive: false):
                    "pay water bill",
                RegExp(r'pay electricity bill', caseSensitive: false):
                    "pay electricity bill",
                RegExp(r'pay gas bill', caseSensitive: false): "pay gas bill",
                RegExp(r'pay phone bill', caseSensitive: false):
                    "pay phone bill",
                RegExp(r'pay internet bill', caseSensitive: false):
                    "pay internet bill",
                RegExp(r'pay tv license', caseSensitive: false):
                    "pay TV license",
                RegExp(r'pay insurance', caseSensitive: false): "pay insurance",
                RegExp(r'pay mortgage', caseSensitive: false): "pay mortgage",
                RegExp(r'pay loan', caseSensitive: false): "pay loan",
                RegExp(r'pay tuition', caseSensitive: false): "pay tuition",
                RegExp(r'pay childcare', caseSensitive: false): "pay childcare",
                RegExp(r'pay gym membership', caseSensitive: false):
                    "pay gym membership",
                RegExp(r'pay club fees', caseSensitive: false): "pay club fees",
                RegExp(r'pay subscription', caseSensitive: false):
                    "pay subscription",
                // Dynamic patterns
                RegExp(r'meet (with )?(.+)', caseSensitive: false): (Match m) =>
                    "meet ${m.group(2)}",
                RegExp(r'lunch with (.+)', caseSensitive: false): (Match m) =>
                    "lunch with ${m.group(1)}",
                RegExp(r'dinner with (.+)', caseSensitive: false): (Match m) =>
                    "dinner with ${m.group(1)}",
                RegExp(r'coffee with (.+)', caseSensitive: false): (Match m) =>
                    "coffee with ${m.group(1)}",
                RegExp(r'visit (.+)', caseSensitive: false): (Match m) =>
                    "visit ${m.group(1)}",
                RegExp(r'pick up (.+)', caseSensitive: false): (Match m) =>
                    "pick up ${m.group(1)}",
                RegExp(r'drop off (.+)', caseSensitive: false): (Match m) =>
                    "drop off ${m.group(1)}",
                RegExp(r'return (.+)', caseSensitive: false): (Match m) =>
                    "return ${m.group(1)}",
                RegExp(r'send (.+) to (.+)', caseSensitive: false): (Match m) =>
                    "send ${m.group(1)} to ${m.group(2)}",
                RegExp(r'book (.+)', caseSensitive: false): (Match m) =>
                    "book ${m.group(1)}",
                RegExp(r'order (.+)', caseSensitive: false): (Match m) =>
                    "order ${m.group(1)}",
                RegExp(r'collect (.+)', caseSensitive: false): (Match m) =>
                    "collect ${m.group(1)}",
                RegExp(r'deliver (.+)', caseSensitive: false): (Match m) =>
                    "deliver ${m.group(1)}",
                RegExp(r'pay for (.+)', caseSensitive: false): (Match m) =>
                    "pay for ${m.group(1)}",
                RegExp(r'schedule (.+)', caseSensitive: false): (Match m) =>
                    "schedule ${m.group(1)}",
                RegExp(r'attend (.+)', caseSensitive: false): (Match m) =>
                    "attend ${m.group(1)}",
                RegExp(r'rsvp to (.+)', caseSensitive: false): (Match m) =>
                    "RSVP to ${m.group(1)}",
                RegExp(
                  r'remind (.+) to (.+)',
                  caseSensitive: false,
                ): (Match m) =>
                    "remind ${m.group(1)} to ${m.group(2)}",
              };
              for (final entry in actionMappings.entries) {
                final reg = entry.key;
                final val = entry.value;
                final matchMap = reg.firstMatch(action!);
                if (matchMap != null) {
                  action = val is String ? val : (val as Function)(matchMap);
                  print('DEBUG: Semantic mapping applied, new action: $action');
                  break;
                }
              }
            }
            break;
          case LogType.expense:
            amountStr = match.group(2)?.trim();
            category = match.group(3)?.trim();
            break;
          default:
            break;
        }

        // Parse date/time and amount if present
        DateTime? dateTime;
        hasTime = true;
        if (dateTimeStr != null && dateTimeStr.isNotEmpty) {
          final dtResult = parseSimpleDateTimeWithTimeFlag(dateTimeStr);
          dateTime = dtResult.dateTime;
          hasTime = dtResult.hasTime;
          print('DEBUG: Parsed dateTime: $dateTime, hasTime: $hasTime');
        }
        double? amount;
        if (amountStr != null && amountStr.isNotEmpty) {
          amount = double.tryParse(amountStr);
        }

        return ParsedLog(
          type: type,
          action: action,
          dateTime: dateTime,
          amount: amount,
          category: category,
          raw: input,
          hasTime: hasTime,
        );
      }
    }

    // Fallback: unknown type
    return ParsedLog(type: LogType.unknown, raw: input);
  }

  // --- 2. Simple Date/Time Parsing ---
  // Returns both DateTime and a flag indicating if time was present
  static _DateTimeWithFlag parseSimpleDateTimeWithTimeFlag(String input) {
    final now = DateTime.now();
    final lower = input.toLowerCase().trim();

    // e.g. "tomorrow at 2pm"
    if (lower.contains('tomorrow')) {
      final timeMatch = RegExp(
        r'at (\d{1,2})(:(\d{2}))?\s*(am|pm)?',
      ).firstMatch(lower);
      int hour = 9;
      int minute = 0;
      bool hasTime = false;
      if (timeMatch != null) {
        hour = int.parse(timeMatch.group(1)!);
        minute = timeMatch.group(3) != null
            ? int.parse(timeMatch.group(3)!)
            : 0;
        final ampm = timeMatch.group(4);
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
        hasTime = true;
      }
      final tomorrow = now.add(Duration(days: 1));
      return _DateTimeWithFlag(
        DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          hasTime ? hour : 0,
          hasTime ? minute : 0,
        ),
        hasTime,
      );
    }

    // --- New: Month name date parsing ---
    // e.g. "14th July", "July 14", "14 July at 2pm"
    final monthNames = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    final monthShort = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    // Patterns: day month, month day
    final dayMonthPattern = RegExp(
      r'(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)(?:\s+at\s+(\d{1,2})(:(\d{2}))?\s*(am|pm)?)?',
      caseSensitive: false,
    );
    final monthDayPattern = RegExp(
      r'(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(st|nd|rd|th)?(?:\s+at\s+(\d{1,2})(:(\d{2}))?\s*(am|pm)?)?',
      caseSensitive: false,
    );
    Match? match = dayMonthPattern.firstMatch(lower);
    if (match != null) {
      int day = int.parse(match.group(1)!);
      String monthStr = match.group(3)!.toLowerCase();
      int month = monthNames.indexOf(monthStr) + 1;
      if (month == 0) month = monthShort.indexOf(monthStr) + 1;
      int year = now.year;
      // If this date has already passed, use next year
      DateTime candidate = DateTime(year, month, day);
      if (candidate.isBefore(now)) year++;
      int hour = 0;
      int minute = 0;
      bool hasTime = false;
      if (match.group(4) != null) {
        hour = int.parse(match.group(4)!);
        minute = match.group(6) != null ? int.parse(match.group(6)!) : 0;
        final ampm = match.group(7);
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
        hasTime = true;
      }
      print('DEBUG: Parsed date - day: $day, month: $month, year: $year');
      print('DEBUG: Original input: $input, lower: $lower');
      print('DEBUG: Match groups: ${match.groups([1, 2, 3])}');
      return _DateTimeWithFlag(
        DateTime(year, month, day, hasTime ? hour : 0, hasTime ? minute : 0),
        hasTime,
      );
    }
    match = monthDayPattern.firstMatch(lower);
    if (match != null) {
      String monthStr = match.group(1)!.toLowerCase();
      int month = monthNames.indexOf(monthStr) + 1;
      if (month == 0) month = monthShort.indexOf(monthStr) + 1;
      int day = int.parse(match.group(2)!);
      int year = now.year;
      DateTime candidate = DateTime(year, month, day);
      if (candidate.isBefore(now)) year++;
      int hour = 0;
      int minute = 0;
      bool hasTime = false;
      if (match.group(4) != null) {
        hour = int.parse(match.group(4)!);
        minute = match.group(6) != null ? int.parse(match.group(6)!) : 0;
        final ampm = match.group(7);
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
        hasTime = true;
      }
      return _DateTimeWithFlag(
        DateTime(year, month, day, hasTime ? hour : 0, hasTime ? minute : 0),
        hasTime,
      );
    }
    // --- End month name date parsing ---

    // --- New: Combined time and date parsing ---
    // e.g. "6 pm 15 July", "2:30 pm July 15"
    final combinedTimeDatePattern1 = RegExp(
      r'(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s+(\d{1,2})(st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)',
      caseSensitive: false,
    );
    final combinedTimeDatePattern2 = RegExp(
      r'(\d{1,2})(:(\d{2}))?\s*(am|pm)?\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(st|nd|rd|th)?',
      caseSensitive: false,
    );

    match = combinedTimeDatePattern1.firstMatch(lower);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      final ampm = match.group(4);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;

      int day = int.parse(match.group(5)!);
      String monthStr = match.group(7)!.toLowerCase();
      int month = monthNames.indexOf(monthStr) + 1;
      if (month == 0) month = monthShort.indexOf(monthStr) + 1;
      int year = now.year;
      DateTime candidate = DateTime(year, month, day);
      if (candidate.isBefore(now)) year++;

      return _DateTimeWithFlag(DateTime(year, month, day, hour, minute), true);
    }

    match = combinedTimeDatePattern2.firstMatch(lower);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      final ampm = match.group(4);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;

      String monthStr = match.group(5)!.toLowerCase();
      int month = monthNames.indexOf(monthStr) + 1;
      if (month == 0) month = monthShort.indexOf(monthStr) + 1;
      int day = int.parse(match.group(6)!);
      int year = now.year;
      DateTime candidate = DateTime(year, month, day);
      if (candidate.isBefore(now)) year++;

      return _DateTimeWithFlag(DateTime(year, month, day, hour, minute), true);
    }
    // --- End combined time and date parsing ---

    // e.g. "on the 18th", "for 19th"
    final dateMatch = RegExp(r'(\d{1,2})(st|nd|rd|th)?').firstMatch(lower);
    if (dateMatch != null) {
      final day = int.parse(dateMatch.group(1)!);
      int month = now.month;
      int year = now.year;
      // If today is after the day, roll over to next month
      if (now.day > day) {
        if (month == 12) {
          month = 1;
          year += 1;
        } else {
          month += 1;
        }
      }
      // If the day is not valid for the month, fallback to current month
      int maxDay = DateTime(year, month + 1, 0).day;
      final safeDay = day <= maxDay ? day : maxDay;
      // Check for time
      final timeMatch = RegExp(
        r'at (\d{1,2})(:(\d{2}))?\s*(am|pm)?',
      ).firstMatch(lower);
      bool hasTime = false;
      int hour = 0;
      int minute = 0;
      if (timeMatch != null) {
        hour = int.parse(timeMatch.group(1)!);
        minute = timeMatch.group(3) != null
            ? int.parse(timeMatch.group(3)!)
            : 0;
        final ampm = timeMatch.group(4);
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
        hasTime = true;
      }
      return _DateTimeWithFlag(
        DateTime(
          year,
          month,
          safeDay,
          hasTime ? hour : 0,
          hasTime ? minute : 0,
        ),
        hasTime,
      );
    }

    // e.g. "at 2pm"
    final timeMatch = RegExp(
      r'at (\d{1,2})(:(\d{2}))?\s*(am|pm)?',
    ).firstMatch(lower);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = timeMatch.group(3) != null
          ? int.parse(timeMatch.group(3)!)
          : 0;
      final ampm = timeMatch.group(4);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      return _DateTimeWithFlag(
        DateTime(now.year, now.month, now.day, hour, minute),
        true,
      );
    }

    // If no recognizable date/time, return null (do not default to today)
    return _DateTimeWithFlag(null, false);
  }
}

class _DateTimeWithFlag {
  final DateTime? dateTime;
  final bool hasTime;
  _DateTimeWithFlag(this.dateTime, this.hasTime);
}
