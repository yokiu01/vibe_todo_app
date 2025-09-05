import 'dart:math';

class QuoteService {
  static final List<Map<String, String>> _quotes = [
    {
      'text': '오늘 할 수 있는 일을 내일로 미루지 마라.',
      'author': '벤저민 프랭클린'
    },
    {
      'text': '성공은 준비된 자에게 찾아온다.',
      'author': '세네카'
    },
    {
      'text': '시간은 가장 귀중한 자원이다.',
      'author': '스티브 잡스'
    },
    {
      'text': '계획 없는 목표는 단지 소망일 뿐이다.',
      'author': '앙투안 드 생텍쥐페리'
    },
    {
      'text': '하루하루를 마지막 날처럼 살아라.',
      'author': '마르쿠스 아우렐리우스'
    },
    {
      'text': '작은 개선이 큰 차이를 만든다.',
      'author': '토니 로빈스'
    },
    {
      'text': '완벽함은 좋은 것의 적이다.',
      'author': '볼테르'
    },
    {
      'text': '행동은 꿈을 현실로 만든다.',
      'author': '파울로 코엘료'
    },
    {
      'text': '오늘의 투자는 내일의 성공이다.',
      'author': '워렌 버핏'
    },
    {
      'text': '시간을 지배하는 자가 인생을 지배한다.',
      'author': '존 레이'
    },
    {
      'text': '계획은 꿈을 현실로 만드는 첫 번째 단계다.',
      'author': '데이비드 알렌'
    },
    {
      'text': '매일 조금씩 성장하면 놀라운 결과가 나온다.',
      'author': '로버트 콜리어'
    },
    {
      'text': '성공은 99%의 노력과 1%의 영감이다.',
      'author': '토마스 에디슨'
    },
    {
      'text': '시간을 아끼는 것은 돈을 버는 것보다 중요하다.',
      'author': '벤저민 프랭클린'
    },
    {
      'text': '오늘의 선택이 내일의 운명을 결정한다.',
      'author': '엘리너 루즈벨트'
    },
  ];

  static Map<String, String> getRandomQuote() {
    final random = Random();
    return _quotes[random.nextInt(_quotes.length)];
  }

  static Map<String, String> getQuoteByDate(DateTime date) {
    // 같은 날짜에는 항상 같은 명언이 나오도록
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = Random(seed);
    return _quotes[random.nextInt(_quotes.length)];
  }
}

