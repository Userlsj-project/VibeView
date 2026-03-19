# 🎬 VibeView

> **영상 감정 AI 분석 플랫폼**
> "감정이 조회수를 만든다" — 쇼츠·애니 영상 속 감정 신호를 분석해 바이럴 요소를 찾아내는 멀티모달 AI 플랫폼

---

## 목차

1. [프로젝트 개요](#프로젝트-개요)
2. [핵심 기능](#핵심-기능)
3. [시스템 아키텍처](#시스템-아키텍처)
4. [기술 스택](#기술-스택)
5. [폴더 구조](#폴더-구조)
6. [개발 로드맵](#개발-로드맵)
7. [설치 및 실행](#설치-및-실행)
8. [API 명세](#api-명세)
9. [발표 자료 요약](#발표-자료-요약)

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **프로젝트명** | VibeView |
| **슬로건** | 감정이 조회수를 만든다 |
| **분석 대상** | YouTube Shorts, TikTok, 애니메이션 영상 |
| **분석 요소** | 사람·동물 표정 / 목소리 감정 / 영상 전체 분위기 |
| **결과물** | 웹 대시보드 + Flutter 모바일 앱 |
| **중간 발표** | 2025년 5월 (2개월 후) |
| **최종 발표** | 2025년 9월 (6개월 후) |

### 기획 의도

YouTube Shorts, TikTok 등 숏폼 플랫폼에서 조회수를 결정하는 핵심 요소는 **감정적 반응**입니다. 그러나 기존 분석 도구는 조회수·좋아요 같은 결과 데이터만 제공하며, "왜 이 영상이 바이럴됐는가"에 대한 답을 주지 않습니다.

VibeView는 얼굴 표정, 목소리 톤, 영상 분위기를 AI로 실시간 분석하고 이를 실제 조회수 데이터와 연결해 **바이럴의 원인**을 찾아냅니다.

---

## 핵심 기능

### 1. 멀티모달 감정 분석
- 얼굴 표정 분석 (MediaPipe FaceMesh — 468개 랜드마크)
- 목소리 감정 분석 (Whisper STT + librosa 피치·에너지)
- 영상 전체 분위기 분석 (CLIP 모델)
- 사람·동물(개, 고양이)·애니 캐릭터 자동 분류 (YOLOv8)
- 초 단위 감정 타임라인 생성

### 2. AI 크리에이터 코치 (Claude API)
- 분석 결과를 기반으로 구체적 개선 피드백 생성
- 예: "3~7초 구간 강아지 눈 맞춤 장면이 핵심입니다. 썸네일로 활용하세요"
- 채팅 인터페이스로 자유 질문 가능

### 3. 바이럴 점수 예측
- 감정 패턴 + 실제 조회수 데이터 학습
- 업로드 전 바이럴 가능성 0~100점 예측
- 어떤 감정 흐름이 높은 점수를 받는지 시각화

### 4. 경쟁 영상 비교 분석
- 내 영상 vs 조회수 100만+ 영상 감정 패턴 비교
- 초반 3초, 중반, 후반부 감정 강도 차이 시각화

### 5. 실시간 감정 트렌드
- 최근 1주 바이럴 영상 감정 패턴 분석
- "지금 유행하는 감정 흐름" 실시간 트렌드 제공

### 6. 동물·애니 특화 분석
- YOLOv8로 피사체 자동 감지
- 동물: 귀, 꼬리, 눈 움직임 기반 감정 분류
- 애니: 캐릭터 표정 특화 모델 적용

---

## 시스템 아키텍처

### 전체 데이터 흐름

> 영상 URL 하나를 입력하면 AI 분석을 거쳐 바이럴 점수와 코치 피드백까지 자동으로 생성됩니다.

```mermaid
flowchart TD
    A([👤 사용자\nURL 입력 또는 영상 업로드])

    A --> B[📱 웹 / 모바일 앱]
    B --> C[⚙️ FastAPI 백엔드]

    C --> D[🎬 영상 전처리\nyt-dlp 다운로드 → OpenCV 프레임 추출 → ffmpeg 음성 분리]

    D --> E[👁 얼굴·객체 분석\nYOLOv8 감지 → 사람 / 동물 / 애니 분류 → MediaPipe 표정 인식]
    D --> F[🎙 음성 분석\nWhisper 음성→텍스트 → librosa 피치·에너지 → 감정 분류]
    D --> G[🎞 영상 분위기 분석\nCLIP 장면 임베딩 → 색감·밝기·속도 점수]

    H([📊 YouTube Data API\n실제 조회수 · 좋아요])

    E & F & G & H --> I[🔀 멀티모달 융합 엔진\n얼굴 + 음성 + 영상 분위기 → 초 단위 감정 타임라인]

    I --> J[🤖 Claude API\n감정 해석 + 바이럴 요인 분석 + 크리에이터 피드백 생성]
    I --> K[📈 바이럴 점수 예측\nML 모델 → 0~100점]

    J & K --> L[🌐 웹 대시보드\n감정 타임라인 · 히트맵 · 경쟁 비교 · 트렌드]
    J & K --> M[📱 Flutter 앱\nAI 코치 챗봇 · 바이럴 점수 · 트렌드 피드]
```

---

### 플랫폼 구성

> 웹과 모바일 모두 같은 백엔드 API를 공유합니다.

```mermaid
flowchart LR
    subgraph FE["프론트엔드"]
        W["🌐 웹 대시보드\n─────────────\n감정 타임라인 그래프\n감정 히트맵\n경쟁 영상 비교\n트렌드 리포트"]
        M["📱 Flutter 모바일\n─────────────\nURL 공유 즉시 분석\nAI 코치 챗봇\n바이럴 점수 위젯\n트렌드 피드 · 푸시 알림"]
    end

    subgraph BE["백엔드 (FastAPI)"]
        B1["🎬 영상 분석 API"]
        B2["🤖 AI 코치 API"]
        B3["📈 트렌드 API"]
        B4["👤 사용자 API"]
    end

    subgraph DB["데이터"]
        D1[("🗄 PostgreSQL\n분석 결과 저장")]
        D2[("⚡ Redis\n캐시")]
    end

    W <--> BE
    M <--> BE
    BE <--> DB
```

---

### AI 분석 파이프라인

> 피사체(사람·동물·애니)를 자동으로 구분해 각각 최적화된 AI 모델로 분석합니다.

```mermaid
flowchart TD
    A([🎬 입력 영상]) --> B[YOLOv8\n피사체 자동 감지]

    B --> C["👤 사람 트랙\nMediaPipe 얼굴 랜드마크 468개\n→ 기쁨·슬픔·분노·공포·놀람·혐오·중립"]
    B --> D["🐶 동물 트랙\n귀·꼬리·눈 움직임 감지\n→ 행복·불안·흥분·졸림"]
    B --> E["🎨 애니 트랙\n과장 표정 보정 모델\n→ 캐릭터 감정 분류"]

    C & D & E --> F["🔀 감정 타임라인 생성\n초 단위 감정 벡터 통합"]

    F --> G["🤖 Claude API\n감정 해석 + 개선 피드백"]
    F --> H["📈 바이럴 점수\nML 모델 0~100점"]
```

---

## 기술 스택

| 분류 | 기술 | 용도 |
|------|------|------|
| **모바일** | Flutter (Dart) | iOS / Android 크로스플랫폼 |
| **웹 프론트엔드** | React + Recharts | 대시보드 시각화 |
| **백엔드** | Python, FastAPI | REST API 서버 |
| **얼굴 분석** | MediaPipe FaceMesh | 468개 랜드마크 표정 분석 |
| **객체 감지** | YOLOv8 | 사람·동물·애니 분류 |
| **음성 분석** | OpenAI Whisper + librosa | STT + 피치·에너지 감정 |
| **영상 분위기** | CLIP (OpenAI) | 장면 임베딩 분석 |
| **AI 코치** | Claude API (claude-sonnet-4-6) | 감정 해석 + 피드백 생성 |
| **영상 처리** | OpenCV + ffmpeg + yt-dlp | 프레임 추출 + 음성 분리 |
| **데이터** | YouTube Data API v3 | 조회수·좋아요 연동 |
| **DB** | PostgreSQL + Redis | 결과 저장 + 캐싱 |
| **배포** | Docker + AWS EC2 | 컨테이너 배포 |

---

## 폴더 구조

```
vibeview/
├── mobile/                        # Flutter 모바일 앱
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── analyze_screen.dart
│   │   │   ├── result_screen.dart
│   │   │   ├── coach_screen.dart
│   │   │   └── trend_screen.dart
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   │   └── notification_service.dart
│   │   ├── models/
│   │   └── widgets/
│   └── pubspec.yaml
│
├── web/                           # React 웹 대시보드
│   ├── src/
│   │   ├── pages/
│   │   │   ├── Dashboard.tsx
│   │   │   ├── Timeline.tsx
│   │   │   ├── Compare.tsx
│   │   │   └── Trend.tsx
│   │   ├── components/
│   │   └── services/
│   └── package.json
│
├── server/                        # FastAPI 백엔드
│   ├── main.py
│   ├── routers/
│   │   ├── analyze.py
│   │   ├── coach.py
│   │   ├── trend.py
│   │   └── user.py
│   ├── services/
│   │   ├── video_processor.py     # OpenCV + ffmpeg + yt-dlp
│   │   ├── face_analyzer.py       # MediaPipe
│   │   ├── animal_analyzer.py     # YOLOv8 + 동물 모델
│   │   ├── audio_analyzer.py      # Whisper + librosa
│   │   ├── scene_analyzer.py      # CLIP
│   │   ├── fusion_engine.py       # 멀티모달 융합
│   │   ├── viral_predictor.py     # 바이럴 점수 ML 모델
│   │   └── claude_coach.py        # Claude API 연동
│   ├── models/
│   │   └── viral_model.pkl
│   └── requirements.txt
│
├── docker-compose.yml
├── CONTEXT.md
└── README.md
```

---

## 개발 로드맵

### 중간 발표 목표 (2개월: 2025년 3월 → 5월)

```mermaid
gantt
    title VibeView 중간 발표 로드맵 (2개월)
    dateFormat  YYYY-MM-DD
    section 1주차
    개발 환경 세팅           :done, 2025-03-19, 3d
    GitHub 저장소 구성       :done, 2025-03-19, 3d
    폴더 구조 생성           :done, 2025-03-19, 3d
    section 2주차
    FastAPI 기본 서버        :2025-03-24, 5d
    yt-dlp 영상 다운로드     :2025-03-24, 5d
    OpenCV 프레임 추출       :2025-03-26, 4d
    section 3주차
    MediaPipe 얼굴 분석      :2025-03-31, 7d
    Whisper 음성 분석        :2025-03-31, 7d
    section 4주차
    YOLOv8 객체 감지         :2025-04-07, 7d
    감정 타임라인 생성       :2025-04-10, 4d
    section 5주차
    Claude API 코치 연동     :2025-04-14, 7d
    멀티모달 융합 엔진       :2025-04-14, 7d
    section 6주차
    웹 대시보드 기본 UI      :2025-04-21, 7d
    감정 타임라인 시각화     :2025-04-21, 7d
    section 7주차
    Flutter 모바일 기본 UI   :2025-04-28, 7d
    API 연동 (모바일)        :2025-04-28, 7d
    section 8주차
    통합 테스트              :2025-05-05, 5d
    중간 발표 준비           :2025-05-08, 5d
    중간 발표                :milestone, 2025-05-14, 0d
```

**중간 발표 시 시연 가능 기능:**
- YouTube Shorts URL 입력 → 얼굴·음성 감정 분석
- 초 단위 감정 타임라인 웹 시각화
- Claude AI 코치 피드백 (텍스트)
- Flutter 앱 기본 화면 시연

---

### 최종 발표 목표 (6개월: 2025년 3월 → 9월)

```mermaid
gantt
    title VibeView 최종 발표 로드맵 (중간 발표 이후)
    dateFormat  YYYY-MM-DD
    section 중간 발표 이후
    중간 발표 피드백 반영    :2025-05-14, 7d
    section 6월
    YOLOv8 동물·애니 분류   :2025-05-21, 14d
    동물 감정 특화 모델      :2025-06-02, 14d
    CLIP 영상 분위기 분석    :2025-06-02, 14d
    section 7월
    바이럴 점수 ML 모델      :2025-06-16, 21d
    YouTube API 데이터 연동  :2025-06-23, 14d
    경쟁 영상 비교 기능      :2025-07-07, 14d
    section 8월
    감정 트렌드 분석         :2025-07-21, 14d
    Flutter 앱 완성          :2025-08-04, 14d
    푸시 알림 구현           :2025-08-04, 7d
    Docker 배포              :2025-08-11, 7d
    section 9월
    전체 통합 테스트         :2025-08-18, 14d
    성능 최적화              :2025-08-25, 7d
    발표 자료 준비           :2025-09-01, 10d
    최종 발표                :milestone, 2025-09-12, 0d
```

**최종 발표 시 완성 기능 전체:**
- 멀티모달 감정 분석 (얼굴 + 음성 + 영상 분위기)
- 사람 · 동물 · 애니 자동 분류 및 특화 분석
- 바이럴 점수 예측 (ML 모델)
- 경쟁 영상 비교 분석
- 실시간 감정 트렌드
- AI 크리에이터 코치 챗봇
- 웹 대시보드 + Flutter 모바일 앱
- AWS 실서버 배포

---

## 설치 및 실행

### 요구 사항

| 항목 | 버전 |
|------|------|
| Python | 3.11 이상 |
| Flutter | 3.x 이상 |
| Node.js | 18 이상 |
| Docker | 최신 버전 |

### 백엔드 실행

```bash
cd server
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### 웹 프론트엔드 실행

```bash
cd web
npm install
npm run dev
```

### Flutter 모바일 실행

```bash
cd mobile
flutter pub get
flutter run -d chrome        # 웹 테스트
flutter run                  # 연결된 기기
```

### 환경 변수 설정 (.env)

```env
CLAUDE_API_KEY=your_claude_api_key
YOUTUBE_API_KEY=your_youtube_data_api_key
DATABASE_URL=postgresql://user:password@localhost:5432/vibeview
REDIS_URL=redis://localhost:6379
```

---

## API 명세

### 영상 분석

```
POST /api/analyze
Body: { "url": "https://youtube.com/shorts/..." }
Response: {
  "video_id": "...",
  "duration": 30,
  "timeline": [...],        // 초 단위 감정 데이터
  "viral_score": 78,
  "dominant_emotion": "joy",
  "subjects": ["person", "dog"]
}
```

### AI 코치

```
POST /api/coach
Body: { "video_id": "...", "question": "어떻게 개선할까요?" }
Response: { "feedback": "..." }
```

### 트렌드

```
GET /api/trend
Response: { "trends": [...] }  // 최근 7일 감정 트렌드
```

---

## 발표 자료 요약

### 한 줄 소개
> "YouTube Shorts·TikTok 영상의 감정을 AI로 분석해 조회수 상승 요인을 찾아주는 멀티모달 플랫폼"

### 핵심 차별점
- **멀티모달 AI**: 얼굴 + 음성 + 영상 분위기를 동시에 분석 (단일 모달 대비 정확도 향상)
- **실제 데이터 연동**: YouTube Data API로 실제 조회수와 감정 패턴을 연결
- **사람·동물·애니 지원**: YOLOv8 기반 피사체 자동 분류 및 특화 모델 적용
- **크로스플랫폼**: 웹 대시보드 + Flutter 모바일 앱 동시 지원
- **AI 코치**: 단순 분석을 넘어 Claude API 기반 실용적 개선 제안 제공

### 기대 효과
- 크리에이터: 업로드 전 바이럴 가능성 예측, 구체적 개선 방향 제시
- 마케터: 감정 기반 영상 전략 수립
- 연구자: 숏폼 영상과 감정 반응의 상관관계 분석

---

*VibeView — 감정이 조회수를 만든다* 🎬
