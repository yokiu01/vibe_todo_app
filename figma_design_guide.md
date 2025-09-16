# Plan·Do 앱 Figma 디자인 가이드

## 🎨 디자인 시스템

### 컬러 팔레트
```yaml
Primary Colors:
  - Primary Blue: #2563EB
  - Primary Blue Dark: #1D4ED8
  - Primary Blue Light: #3B82F6

Secondary Colors:
  - Success Green: #22C55E
  - Success Green Light: #10B981
  - Warning Orange: #F59E0B
  - Purple: #8B5CF6
  - Cyan: #06B6D4

Neutral Colors:
  - Background: #F8FAFC
  - Surface: #FFFFFF
  - Border: #E2E8F0
  - Text Primary: #1E293B
  - Text Secondary: #64748B
  - Text Muted: #9CA3AF
  - Text Light: #E5E7EB
```

### 타이포그래피
```yaml
Headings:
  - H1: 24px, Bold, #1E293B
  - H2: 18px, Bold, #1E293B
  - H3: 16px, SemiBold, #1E293B

Body Text:
  - Large: 16px, Regular, #1E293B
  - Medium: 14px, Regular, #64748B
  - Small: 12px, Regular, #64748B
  - Caption: 10px, Medium, #64748B

Labels:
  - Button: 14px, SemiBold
  - Tab: 12px, SemiBold
  - Navigation: 10px, Bold
```

### 스페이싱 시스템
```yaml
Spacing Scale:
  - xs: 4px
  - sm: 8px
  - md: 12px
  - lg: 16px
  - xl: 20px
  - 2xl: 24px
  - 3xl: 32px
  - 4xl: 48px
```

### 컴포넌트 스펙

#### 1. 카드 컴포넌트
```yaml
Card:
  - Background: #FFFFFF
  - Border: 1px solid #E2E8F0
  - Border Radius: 12px
  - Padding: 16px
  - Shadow: 0px 2px 8px rgba(0, 0, 0, 0.05)
  - Hover Shadow: 0px 4px 12px rgba(0, 0, 0, 0.1)
```

#### 2. 버튼 컴포넌트
```yaml
Primary Button:
  - Background: #2563EB
  - Text: #FFFFFF
  - Border Radius: 8px
  - Padding: 12px 16px
  - Font: 14px SemiBold

Secondary Button:
  - Background: #E2E8F0
  - Text: #64748B
  - Border Radius: 8px
  - Padding: 12px 16px
  - Font: 14px Medium
```

#### 3. 상태 배지
```yaml
Status Badge:
  - Background: Color with 10% opacity
  - Text: Full color
  - Border Radius: 6px
  - Padding: 4px 8px
  - Font: 10px SemiBold

Status Colors:
  - Task: #3B82F6
  - Project: #10B981
  - Note: #F59E0B
  - Area: #8B5CF6
  - Resource: #06B6D4
  - Completed: #22C55E
```

## 📱 화면별 디자인 가이드

### 1. 홈 화면 (Home Screen)

#### 헤더 섹션
```yaml
Header:
  - Background: #FFFFFF
  - Padding: 20px
  - Border Bottom: 1px solid #E2E8F0

Icon Container:
  - Background: #2563EB with 10% opacity
  - Border Radius: 12px
  - Padding: 12px
  - Icon: 24px, #2563EB

Title:
  - Text: "🏠 홈"
  - Font: 24px Bold, #1E293B

Subtitle:
  - Text: "오늘의 계획과 프로젝트 관리"
  - Font: 14px Regular, #64748B

Status Cards:
  - Layout: 3 columns
  - Background: Color with 10% opacity
  - Border: 1px solid color with 20% opacity
  - Border Radius: 8px
  - Padding: 12px
  - Count: 18px Bold, color
  - Label: 11px Medium, color with 80% opacity
```

#### 탭 바
```yaml
Tab Bar:
  - Background: #FFFFFF
  - Height: 48px
  - Padding: 8px

Active Tab:
  - Background: #2563EB
  - Text: #FFFFFF
  - Border Radius: 8px
  - Padding: 8px

Inactive Tab:
  - Text: #64748B
  - Font: 12px SemiBold

Tab Icons:
  - Size: 18px
  - Spacing: 4px from text
```

#### 콘텐츠 카드
```yaml
Task Card:
  - Background: #FFFFFF
  - Border: 1px solid #E2E8F0 (or #22C55E if completed)
  - Border Radius: 12px
  - Padding: 16px
  - Shadow: 0px 2px 8px rgba(0, 0, 0, 0.05)
  - Margin Bottom: 12px

Card Header:
  - Type Badge: Background with 10% opacity, 6px radius
  - Completion Icon: 20px, #22C55E or #64748B

Card Content:
  - Title: 16px SemiBold, #1E293B (or #22C55E if completed)
  - Description: 14px Regular, #6B7280
  - Max Lines: 2, Ellipsis

Card Footer:
  - Time Icon: 14px, #64748B
  - Time Text: 12px Regular, #64748B
  - Status Badge: Background with 10% opacity, 8px radius
```

### 2. 네비게이션 바 (Bottom Navigation)

#### 홈 버튼 (특별 디자인)
```yaml
Home Button:
  - Size: 72x72px
  - Position: 12px above other buttons
  - Background: Gradient (#2563EB to #1D4ED8) or White
  - Border: 3px solid #1E40AF or #E2E8F0
  - Border Radius: 36px
  - Shadow: 0px 6px 16px rgba(0, 0, 0, 0.15)
  - Icon: 26px, White or #2563EB
  - Text: 10px Bold, White or #2563EB
```

#### 일반 버튼
```yaml
Regular Button:
  - Width: 60px
  - Height: 60px
  - Background: #2563EB (active) or Transparent
  - Border Radius: 18px
  - Icon Container: 36x36px, 10px radius
  - Icon: 20px, White or #64748B
  - Text: 10px, White or #64748B
  - Shadow: 0px 2px 8px rgba(37, 99, 235, 0.3) if active
```

### 3. 계획 화면 (Plan Screen)

#### 헤더
```yaml
Header:
  - Background: #F8FAFC
  - Padding: 16px
  - Title: "📅 계획"
  - Font: 24px Bold, #1E293B
```

#### 탭 바
```yaml
Tab Container:
  - Background: #E2E8F0
  - Border Radius: 8px
  - Margin: 16px
  - Padding: 4px

Active Tab:
  - Background: #FFFFFF
  - Text: #2563EB
  - Border Radius: 6px

Inactive Tab:
  - Text: #64748B
  - Font: 14px SemiBold
```

### 4. 점검 화면 (Review Screen)

#### 헤더
```yaml
Header:
  - Background: #F8FAFC
  - Padding: 16px
  - Title: "✅ 점검"
  - Font: 24px Bold, #1E293B

Completion Badge:
  - Background: #059669
  - Text: "XX%"
  - Font: 14px Bold, White
  - Border Radius: 20px
  - Padding: 6px 12px
```

#### 타입 선택기
```yaml
Type Selector:
  - Layout: 3 equal columns
  - Margin: 4px between buttons

Type Button:
  - Background: #2563EB (active) or #E2E8F0
  - Text: White (active) or #64748B
  - Border Radius: 8px
  - Padding: 12px vertical
  - Font: 14px Medium
```

#### 진행률 바
```yaml
Progress Bar:
  - Background: #E2E8F0
  - Height: 6px
  - Border Radius: 3px
  - Margin: 8px 16px

Progress Fill:
  - Background: #059669
  - Border Radius: 3px
  - Width: Based on completion percentage
```

#### 단계 카드
```yaml
Step Card:
  - Background: #FFFFFF or #F0FDF4 (if completed)
  - Border: 1px solid #E2E8F0 or #059669 (if completed)
  - Border Radius: 12px
  - Padding: 16px
  - Margin Bottom: 12px

Step Number:
  - Size: 32x32px
  - Background: #E2E8F0 or #059669 (if completed)
  - Border Radius: 16px
  - Text: Step number or "✓"
  - Font: 14px Bold, #64748B or White

Step Content:
  - Title: 16px SemiBold, #1E293B or #059669
  - Description: 14px Regular, #64748B or #16A34A
  - Line Height: 1.4
```

## 🎯 Figma 작업 순서

### 1단계: 디자인 시스템 구축
1. 컬러 스타일 생성
2. 타이포그래피 스타일 생성
3. 스페이싱 시스템 설정
4. 아이콘 라이브러리 준비

### 2단계: 컴포넌트 제작
1. 카드 컴포넌트
2. 버튼 컴포넌트
3. 상태 배지 컴포넌트
4. 입력 필드 컴포넌트

### 3단계: 화면 와이어프레임
1. 홈 화면
2. 네비게이션 바
3. 계획 화면
4. 점검 화면

### 4단계: 상호작용 디자인
1. 호버 상태
2. 활성 상태
3. 로딩 상태
4. 에러 상태

### 5단계: 반응형 디자인
1. 모바일 (375px)
2. 태블릿 (768px)
3. 데스크톱 (1024px)

## 📐 그리드 시스템

### 모바일 그리드
```yaml
Grid:
  - Columns: 4
  - Gutter: 16px
  - Margin: 16px
  - Max Width: 375px
```

### 컴포넌트 간격
```yaml
Vertical Spacing:
  - Section to Section: 24px
  - Card to Card: 12px
  - Element to Element: 8px

Horizontal Spacing:
  - Screen Edge: 16px 
  - Card Padding: 16px
  - Element Padding: 12px
```

이 가이드를 참고하여 Figma에서 디자인을 시작하시면 됩니다. 특정 화면이나 컴포넌트에 대해 더 자세한 디자인 가이드가 필요하시면 말씀해 주세요!


