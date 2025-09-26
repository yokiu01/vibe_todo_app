화면: Lock Screen Widget
디자인 시스템: Material Design 3.0 / iOS Human Interface Guidelines
중요:일정 목록은 pds_plan의 내용을 불러옴.

🎨 디자인 시스템 개선
1. 컬러 팔레트 재정의
css/* Primary Colors */
--primary-blue: #4C6EF5
--primary-gradient: linear-gradient(135deg, #4C6EF5 0%, #7C3AED 100%)

/* Status Colors */
--status-now: #10B981 (Emerald-500)
--status-next: #8B5CF6 (Violet-500)
--status-urgent: #EF4444 (Red-500)
--status-normal: #6B7280 (Gray-500)

/* Background & Text */
--bg-primary: #FFFFFF
--bg-secondary: #F8FAFC
--text-primary: #1F2937
--text-secondary: #6B7280
--text-accent: #4C6EF5

/* Card Backgrounds */
--card-now: rgba(16, 185, 129, 0.08)
--card-next: rgba(139, 92, 246, 0.08)
--card-urgent: rgba(239, 68, 68, 0.08)
--card-default: rgba(255, 255, 255, 0.95)
2. 타이포그래피 시스템
css/* Time Display */
.time-display {
  font-family: 'SF Pro Display', 'Roboto';
  font-size: 48px;
  font-weight: 300;
  line-height: 56px;
  letter-spacing: -0.02em;
}

/* Date */
.date-text {
  font-family: 'SF Pro Text', 'Roboto';
  font-size: 14px;
  font-weight: 500;
  line-height: 20px;
  letter-spacing: 0.01em;
  text-transform: uppercase;
}

/* Event Title */
.event-title {
  font-family: 'SF Pro Text', 'Roboto';
  font-size: 16px;
  font-weight: 600;
  line-height: 22px;
  letter-spacing: -0.01em;
}

/* Event Subtitle */
.event-subtitle {
  font-family: 'SF Pro Text', 'Roboto';
  font-size: 13px;
  font-weight: 400;
  line-height: 18px;
  color: var(--text-secondary);
}

🔧 구체적 수정사항
1. 헤더 영역 개선
xml<!-- 기존 시간 표시 영역 -->
<View style="header">
  <!-- 배경에 미묘한 그라디언트 추가 -->
  <LinearGradient colors={['#F8FAFC', '#FFFFFF']} />
  
  <!-- 시간 표시 -->
  <Text style="time-display">18:03</Text>
  <Text style="time-period">PM</Text>
  
  <!-- 날짜와 요일 -->
  <Text style="date-text">THURSDAY, SEPTEMBER 25</Text>
  
  <!-- 새로 추가: 오늘 일정 요약 -->
  <View style="day-summary">
    <Text style="summary-text">4 events today</Text>
    <View style="progress-bar">
      <View style="progress-fill" width="60%" />
    </View>
  </View>
</View>
2. 일정 카드 레이아웃 개선
xml<ScrollView style="events-container">
  <!-- NOW 상태 이벤트 -->
  <View style="event-card event-now">
    <View style="status-indicator">
      <View style="status-dot now" />
      <Text style="status-label">NOW</Text>
    </View>
    
    <View style="event-content">
      <Text style="event-title">Daily Stand-up Meeting</Text>
      <View style="event-meta">
        <Icon name="clock" size={12} color="#6B7280" />
        <Text style="event-time">10:00 AM - 10:45 AM</Text>
        <Icon name="users" size={12} color="#6B7280" />
        <Text style="event-attendees">5 people</Text>
      </View>
    </View>
    
    <View style="event-actions">
      <TouchableOpacity style="action-button">
        <Icon name="video" size={16} />
      </TouchableOpacity>
    </View>
  </View>

  <!-- NEXT 상태 이벤트 -->
  <View style="event-card event-next">
    <View style="status-indicator">
      <View style="status-dot next" />
      <Text style="status-label">NEXT</Text>
      <Text style="countdown">in 15min</Text>
    </View>
    
    <View style="event-content">
      <Text style="event-title">Project Proposal Development</Text>
      <View style="event-meta">
        <Icon name="clock" size={12} />
        <Text style="event-time">11:00 AM - 1:00 PM</Text>
        <Icon name="map-pin" size={12} />
        <Text style="event-location">Conference Room A</Text>
      </View>
    </View>
    
    <View style="event-actions">
      <TouchableOpacity style="action-button">
        <Icon name="navigation" size={16} />
      </TouchableOpacity>
    </View>
  </View>
</ScrollView>
3. 스타일 시트 정의
css/* Event Cards */
.event-card {
  background: var(--card-default);
  border-radius: 16px;
  padding: 16px;
  margin-bottom: 12px;
  border-left: 4px solid transparent;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  backdrop-filter: blur(10px);
}

.event-now {
  background: var(--card-now);
  border-left-color: var(--status-now);
}

.event-next {
  background: var(--card-next);
  border-left-color: var(--status-next);
}

.event-urgent {
  background: var(--card-urgent);
  border-left-color: var(--status-urgent);
}

/* Status Indicators */
.status-indicator {
  flex-direction: row;
  align-items: center;
  margin-bottom: 8px;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 4px;
  margin-right: 8px;
}

.status-dot.now {
  background: var(--status-now);
}

.status-dot.next {
  background: var(--status-next);
}

.status-label {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}

.countdown {
  margin-left: auto;
  font-size: 11px;
  color: var(--status-next);
  font-weight: 600;
}

/* Event Content */
.event-content {
  flex: 1;
}

.event-meta {
  flex-direction: row;
  align-items: center;
  margin-top: 4px;
  gap: 8px;
}

/* Actions */
.event-actions {
  margin-left: 12px;
}

.action-button {
  width: 32px;
  height: 32px;
  border-radius: 16px;
  background: rgba(76, 110, 245, 0.1);
  justify-content: center;
  align-items: center;
}

🚀 추가 구현 요소
1. 마이크로 인터랙션
javascript// 카드 터치 애니메이션
const cardPressAnimation = useRef(new Animated.Value(1)).current;

const onPressIn = () => {
  Animated.spring(cardPressAnimation, {
    toValue: 0.98,
    useNativeDriver: true,
  }).start();
};

const onPressOut = () => {
  Animated.spring(cardPressAnimation, {
    toValue: 1,
    useNativeDriver: true,
  }).start();
};
3. 다크 모드 지원
css@media (prefers-color-scheme: dark) {
  --bg-primary: #1F2937;
  --bg-secondary: #111827;
  --text-primary: #F9FAFB;
  --text-secondary: #D1D5DB;
  --card-default: rgba(31, 41, 55, 0.95);
}

📐 레이아웃 스펙
컨테이너 크기

전체 컨테이너: width: 100%, max-width: 375px
헤더 높이: 120px
이벤트 카드: padding: 16px, margin-bottom: 12px
하단 버튼: height: 52px, border-radius: 26px

간격 시스템

Large: 24px
Medium: 16px
Small: 12px
XSmall: 8px


✅ 구현 체크리스트

 컬러 시스템 적용
 타이포그래피 시스템 적용
 이벤트 카드 리디자인
 상태 표시기 구현
 마이크로 인터랙션 추가
 다크 모드 지원
 AI 추천 UI 구현
 접근성 라벨 추가
 성능 최적화