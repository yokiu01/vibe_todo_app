# 🚨 긴급 디자인 수정 지시서 

**상황**: 현재 구현된 화면이 요구사항과 완전히 다름  
**문제점**: 내용 없는 색깔 박스, 한국 서비스인데 영어 표시, pds_plan 데이터 미표시

---

## ❌ 현재 구현의 문제점

1. **기능적 오류**: pds_plan 데이터가 전혀 표시되지 않음
2. **UI 오류**: 의미없는 색깔 박스들만 나열
3. **현지화 오류**: 한국 서비스인데 영어로 표시
4. **사용성 오류**: 사용자가 어떤 일정인지 알 수 없음

---

## ✅ 즉시 수정 사항

### 1. 언어 현지화 (최우선)
```javascript
// 현재 (잘못됨)
date: "THURSDAY, SEPTEMBER 25"
timeFormat: "PM"
summaryText: "4 events today"
completeText: "60% complete"
buttonText: "CLOSE"

// 수정 후
date: "9월 25일 목요일"
timeFormat: "오후" 
summaryText: "오늘 일정 4개"
completeText: "완료율 60%"
buttonText: "닫기"
```

### 2. pds_plan 데이터 연동 (즉시 구현)
```javascript
// pds_plan에서 오늘 일정 가져오기
const todayPlans = pds_plan.filter(plan => 
  plan.date === getCurrentDate()
).sort((a, b) => a.time - b.time);

// 각 일정을 실제 내용으로 표시
{todayPlans.map((plan, index) => (
  <View key={plan.id} style={getEventCardStyle(plan.status)}>
    <View style="status-indicator">
      <View style={`status-dot ${plan.status}`} />
      <Text style="status-label">{getStatusLabel(plan.status)}</Text>
      {plan.status === 'next' && (
        <Text style="countdown">{getTimeUntil(plan.startTime)}</Text>
      )}
    </View>
    
    <View style="event-content">
      <Text style="event-title">{plan.title}</Text>
      <View style="event-meta">
        <Icon name="clock" size={12} />
        <Text style="event-time">
          {formatTime(plan.startTime)} - {formatTime(plan.endTime)}
        </Text>
        {plan.location && (
          <>
            <Icon name="map-pin" size={12} />
            <Text style="event-location">{plan.location}</Text>
          </>
        )}
      </View>
    </View>
    
    <View style="event-actions">
      <TouchableOpacity 
        style="action-button"
        onPress={() => handleQuickAction(plan)}
      >
        <Icon name={getActionIcon(plan.type)} size={16} />
      </TouchableOpacity>
    </View>
  </View>
))}
```

### 3. 상태별 스타일링 함수
```javascript
const getEventCardStyle = (status) => {
  const baseStyle = "event-card";
  switch(status) {
    case 'now': return `${baseStyle} event-now`;
    case 'next': return `${baseStyle} event-next`;  
    case 'urgent': return `${baseStyle} event-urgent`;
    default: return `${baseStyle} event-default`;
  }
};

const getStatusLabel = (status) => {
  switch(status) {
    case 'now': return '진행중';
    case 'next': return '다음';
    case 'urgent': return '긴급';
    case 'upcoming': return '예정';
    default: return '';
  }
};

const getTimeUntil = (startTime) => {
  const diff = new Date(startTime) - new Date();
  const minutes = Math.floor(diff / 60000);
  return `${minutes}분 후`;
};
```

### 4. 실제 데이터 예시
```javascript
// pds_plan 데이터 구조 예시 (이미 있다고 가정)
const samplePdsData = [
  {
    id: 1,
    title: "데일리 스탠드업 미팅",
    startTime: "2025-09-25T10:00:00",
    endTime: "2025-09-25T10:45:00",
    location: "회의실 A",
    type: "meeting",
    status: "now",
    attendees: ["김철수", "이영희", "박민수"]
  },
  {
    id: 2, 
    title: "프로젝트 제안서 작성",
    startTime: "2025-09-25T11:00:00",
    endTime: "2025-09-25T13:00:00",
    location: "개발팀",
    type: "work",
    status: "next"
  },
  {
    id: 3,
    title: "사라와 점심",
    startTime: "2025-09-25T13:00:00", 
    endTime: "2025-09-25T14:00:00",
    location: "강남역 맛집",
    type: "personal",
    status: "upcoming"
  },
  {
    id: 4,
    title: "긴급 고객 통화",
    startTime: "2025-09-25T16:30:00",
    endTime: "2025-09-25T17:00:00", 
    type: "call",
    status: "urgent",
    priority: "high"
  }
];
```

---

## 🔧 완성된 화면 구조

```xml
<View style="lock-screen-container">
  <!-- 헤더: 시간과 날짜 -->
  <View style="header">
    <Text style="time-display">18:28</Text>
    <Text style="time-period">오후</Text>
    <Text style="date-text">9월 25일 목요일</Text>
    
    <!-- 오늘 일정 요약 -->
    <View style="day-summary">
      <Text style="summary-text">오늘 일정 4개</Text>
      <View style="progress-container">
        <View style="progress-bar">
          <View style="progress-fill" width="60%" />
        </View>
        <Text style="progress-text">완료율 60%</Text>
      </View>
    </View>
  </View>

  <!-- 실제 일정 리스트 -->
  <ScrollView style="events-container">
    {/* 여기에 실제 pds_plan 데이터로 만든 일정 카드들 */}
  </ScrollView>

  <!-- 하단 버튼 -->
  <TouchableOpacity style="close-button">
    <Text style="close-button-text">닫기</Text>
  </TouchableOpacity>
</View>
```

---

## ⚠️ 개발자 확인사항

### 즉시 확인할 것:
1. **pds_plan 데이터베이스 연결** 되어 있나?
2. **오늘 날짜 필터링** 로직 구현했나?
3. **한국어 현지화** 파일 적용했나?
4. **실시간 상태 업데이트** (now/next) 구현했나?

### 테스트 케이스:
- [ ] pds_plan에 데이터가 없을 때 빈 상태 표시
- [ ] 진행 중인 일정이 "진행중" 라벨로 표시
- [ ] 다음 일정이 "N분 후" 카운트다운 표시  
- [ ] 모든 텍스트가 한국어로 표시
- [ ] 일정 카드 터치시 적절한 액션 실행

---

## 🎯 완성 기준

**이 화면이 완성되었다고 판단하는 기준:**
1. 사용자가 **실제 일정 내용**을 명확히 볼 수 있음
2. **모든 텍스트가 한국어**로 표시됨
3. **현재 진행중/다음 일정**을 구분해서 볼 수 있음
4. **의미없는 색깔 박스 없음**
5. **pds_plan 데이터가 정확히 반영**됨

현재 구현은 **0% 완성상태**입니다. 위 지시사항을 모두 구현한 후 다시 검토받으세요.