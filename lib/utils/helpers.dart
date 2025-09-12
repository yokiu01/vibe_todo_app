import 'dart:math';

class Helpers {
  static String generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '$timestamp-$random';
  }

  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '${hours}시간 ${mins}분';
    }
    return '${mins}분';
  }

  static bool isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }

  static int getDaysOverdue(DateTime dueDate) {
    final now = DateTime.now();
    return now.difference(dueDate).inDays;
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  static String getWeekdayName(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  static String getMonthName(DateTime date) {
    const months = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    return months[date.month - 1];
  }

  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static DateTime getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  static DateTime getEndOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static List<DateTime> getDaysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = start;
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return days;
  }

  static String getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return '매우 높음';
      case 2:
        return '높음';
      case 3:
        return '보통';
      case 4:
        return '낮음';
      case 5:
        return '매우 낮음';
      default:
        return '보통';
    }
  }

  static String getEnergyLevelText(String energyLevel) {
    switch (energyLevel) {
      case 'high':
        return '높음';
      case 'medium':
        return '보통';
      case 'low':
        return '낮음';
      default:
        return '보통';
    }
  }

  static String getContextText(String context) {
    switch (context) {
      case 'home':
        return '집';
      case 'office':
        return '사무실';
      case 'computer':
        return '컴퓨터';
      case 'errands':
        return '외출';
      case 'calls':
        return '전화';
      case 'anywhere':
        return '어디서나';
      default:
        return '어디서나';
    }
  }

  static String getStatusText(String status) {
    switch (status) {
      case 'inbox':
        return '수집함';
      case 'clarified':
        return '명료화됨';
      case 'active':
        return '진행중';
      case 'completed':
        return '완료';
      case 'archived':
        return '보관됨';
      case 'someday':
        return '언젠가';
      case 'waiting':
        return '대기중';
      default:
        return '수집함';
    }
  }

  static String getTypeText(String type) {
    switch (type) {
      case 'goal':
        return '목표';
      case 'project':
        return '프로젝트';
      case 'task':
        return '할일';
      case 'note':
        return '노트';
      case 'area':
        return '영역';
      case 'resource':
        return '자원';
      default:
        return '할일';
    }
  }
}



