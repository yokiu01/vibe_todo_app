# Vibe Todo App - 레이아웃 구조 설명

## 📱 앱 개요
**Vibe Todo App**은 개인 생산성 관리를 위한 Flutter 기반 모바일 애플리케이션입니다. Notion API와 연동하여 할일, 프로젝트, 노트를 체계적으로 관리할 수 있습니다.

## 🏗️ 전체 앱 구조

### 1. 메인 앱 진입점 (`main.dart`)
```
ProductivityApp (StatefulWidget)
├── MultiProvider (상태 관리)
│   ├── ItemProvider
│   ├── DailyPlanProvider  
│   ├── ReviewProvider
│   ├── PDSDiaryProvider
│   └── AIProvider
└── MaterialApp
    ├── ThemeData (브라운 계열 컬러 스킴)
    ├── Localization (한국어/영어)
    └── MainNavigation (홈 화면)
```

### 2. 네비게이션 구조 (`main_navigation.dart`)
```
MainNavigation (Scaffold)
├── IndexedStack (화면 스택 관리)
│   ├── HomeScreen (홈)
│   ├── CollectionClarificationScreen (수집)
│   ├── PlanScreen (계획)
│   └── ArchiveScreen (아카이브)
└── BottomNavigationBar (커스텀 네비게이션)
    ├── 홈 (🏠) - 브라운 색상
    ├── 수집 (💡) - 오렌지 색상
    ├── 계획 (📅) - 블루 색상
    └── 아카이브 (📦) - 그린 색상
```

## 📄 각 화면별 상세 구조

### 1. 홈 화면 (`home_screen.dart`)
```
HomeScreen
├── Header (제목 + 설명)
├── TabBar (5개 탭)
│   ├── Today (오늘의 할일)
│   ├── Pin (고정된 노트)
│   ├── Project (프로젝트)
│   ├── Area (영역)
│   └── Resource (자원)
└── TabBarView
    ├── _buildTodayPage() - 오늘 날짜 할일 표시
    ├── _buildPinPage() - 고정된 노트 표시
    ├── _buildProjectPage() - 진행중인 프로젝트 표시
    ├── _buildAreaPage() - 영역 관리 목록
    └── _buildResourcePage() - 자원 및 참고 자료
```

**주요 기능:**
- Notion API 연동으로 실시간 데이터 표시
- 각 탭별로 다른 데이터베이스 쿼리
- Pull-to-refresh 지원
- 태스크 상세 보기 다이얼로그

### 2. 수집 화면 (`collection_clarification_screen.dart`)
```
CollectionClarificationScreen
├── Header (제목 + 설명)
├── 입력 영역
│   ├── TextField (텍스트 입력)
│   └── InteractiveButton (추가 버튼)
├── 수집함 섹션
│   └── NotionTask 리스트 (오늘 수집된 항목들)
└── 명료화 섹션
    └── NotionTask 리스트 (명료화 대기 항목들)
```

**주요 기능:**
- 빠른 아이디어 수집
- GTD 방법론 기반 명료화 프로세스
- Notion 데이터베이스 자동 분류

### 3. 계획 화면 (`plan_screen.dart`)
```
PlanScreen
├── Header (제목 + 설명)
├── TabBar (3개 탭)
│   ├── Task Management
│   ├── PDS Plan
│   └── PDS Do/See
└── TabBarView
    ├── TaskManagementScreen
    ├── PDSPlanScreen
    └── PDSDoSeeScreen
```

**주요 기능:**
- 할일 관리 시스템
- PDS (Plan-Do-See) 방법론 구현
- 프로젝트 기반 계획 수립

### 4. 아카이브 화면 (`archive_screen.dart`)
```
ArchiveScreen
├── Header (제목 + 설명)
├── TabBar (3개 탭)
│   ├── 목표 나침반
│   ├── 노트 관리함
│   └── 아이스박스
└── TabBarView
    ├── 목표 관리 시스템
    ├── 노트 아카이브
    └── 장기 보관 아이템
```

**주요 기능:**
- 완료된 작업 아카이브
- 목표 추적 시스템
- 장기 보관 아이템 관리

## 🎨 디자인 시스템

### 컬러 팔레트
```dart
Primary Colors:
- Primary Brown: #8B7355
- Primary Brown Light: #D4A574
- Background: #F5F1E8
- Card Background: #FDF6E3
- Border Color: #DDD4C0

Tab Colors:
- 홈: #8B7355 (브라운)
- 수집: #F5A623 (오렌지)
- 계획: #4A90E2 (블루)
- 아카이브: #7ED321 (그린)
```

### 타이포그래피
- 제목: 24px, FontWeight.bold
- 부제목: 14px, FontWeight.normal
- 본문: 16px, FontWeight.w600
- 라벨: 12px, FontWeight.w500

### 컴포넌트 스타일
- 카드: 둥근 모서리 (12px), 그림자 효과
- 버튼: 둥근 모서리 (12px), 그라데이션 배경
- 입력 필드: 둥근 모서리 (12px), 테두리 스타일

## 🔧 상태 관리

### Provider 패턴 사용
```dart
MultiProvider:
├── ItemProvider: 로컬 할일 관리
├── DailyPlanProvider: 일일 계획 관리
├── ReviewProvider: 리뷰 시스템
├── PDSDiaryProvider: PDS 일지 관리
└── AIProvider: AI 기능 관리
```

### 데이터 흐름
1. **Notion API** → **NotionAuthService** → **화면 상태**
2. **로컬 데이터베이스** → **Provider** → **화면 상태**
3. **사용자 입력** → **서비스 레이어** → **Notion API**

## 📱 반응형 디자인

### 화면 크기 대응
- `MediaQuery`를 활용한 동적 크기 조정
- 작은 화면에서 텍스트 크기 자동 축소
- 탭바 아이콘 크기 조정

### 네비게이션 최적화
- `IndexedStack`으로 화면 상태 유지
- 부드러운 애니메이션 전환
- 탭별 고유 색상으로 시각적 구분

## 🔄 데이터 동기화

### Notion API 연동
- 실시간 데이터 동기화
- 오프라인 상태 처리
- 에러 핸들링 및 재시도 로직

### 로컬 캐싱
- SQLite 데이터베이스 활용
- 오프라인 모드 지원
- 데이터 충돌 해결

## 🚀 성능 최적화

### 렌더링 최적화
- `const` 생성자 활용
- 불필요한 리빌드 방지
- 지연 로딩 구현

### 메모리 관리
- 컨트롤러 적절한 해제
- 이미지 캐싱 최적화
- 메모리 누수 방지

## 📋 주요 기능

### 1. 할일 관리
- 오늘의 할일 표시
- 상태별 필터링
- 완료/미완료 토글

### 2. 프로젝트 관리
- 진행중인 프로젝트 추적
- 관련 할일 연결
- 마일스톤 관리

### 3. 노트 시스템
- 빠른 메모 작성
- 고정 기능
- 검색 및 분류

### 4. 아카이브
- 완료된 작업 보관
- 목표 추적
- 장기 보관 아이템

## 🔧 기술 스택

### 프론트엔드
- **Flutter**: 크로스 플랫폼 UI 프레임워크
- **Provider**: 상태 관리
- **Material Design**: UI 디자인 시스템

### 백엔드 연동
- **Notion API**: 데이터 저장 및 동기화
- **SQLite**: 로컬 데이터베이스
- **HTTP**: API 통신

### 유틸리티
- **Intl**: 국제화 및 날짜 포맷팅
- **SharedPreferences**: 설정 저장
- **Permission Handler**: 권한 관리

## 📱 사용자 경험

### 직관적인 네비게이션
- 하단 탭바로 주요 기능 접근
- 각 탭별 고유 색상으로 구분
- 부드러운 애니메이션 전환

### 효율적인 데이터 입력
- 빠른 텍스트 입력
- 원터치 액션
- 자동 분류 시스템

### 시각적 피드백
- 로딩 스켈레톤
- 상태별 색상 구분
- 진행률 표시

이 구조는 사용자의 생산성 향상을 위해 GTD(Getting Things Done) 방법론과 PDS(Plan-Do-See) 방법론을 기반으로 설계되었으며, Notion과의 연동을 통해 강력한 데이터 관리 기능을 제공합니다.
