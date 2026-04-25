# VibeView

> **영상 감정 AI 분석 플랫폼**
> "감정이 조회수를 만든다" — YouTube Shorts·애니메이션 영상 속 감정 신호를 분석해 바이럴 요소를 찾아내는 멀티모달 AI 플랫폼

---

## 목차

1. [프로젝트 개요](#프로젝트-개요)
2. [핵심 기능](#핵심-기능)
3. [시스템 아키텍처](#시스템-아키텍처)
4. [기술 스택](#기술-스택)
5. [폴더 구조](#폴더-구조)
6. [설치 및 실행](#설치-및-실행)
7. [Docker 배포](#docker-배포)
8. [API 명세](#api-명세)
9. [개발 로드맵](#개발-로드맵)

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **프로젝트명** | VibeView |
| **슬로건** | 감정이 조회수를 만든다 |
| **분석 대상** | YouTube Shorts 등 짧은 영상, 애니메이션 영상 |
| **분석 요소** | 얼굴 표정 / 목소리 감정 / 영상 전체 분위기 |
| **결과물** | 웹 대시보드 + Flutter 모바일 앱 |

### 기획 의도

YouTube Shorts 같은 숏폼 플랫폼에서 조회수를 결정하는 핵심 요소는 **감정적 반응**입니다.
기존 분석 도구는 조회수·좋아요 같은 결과 데이터만 제공하며, "왜 이 영상이 바이럴됐는가"에 대한 답을 주지 않습니다.

VibeView는 얼굴 표정, 목소리 톤, 영상 분위기를 AI로 실시간 분석하고 이를 실제 조회수 데이터와 연결해 **바이럴의 원인**을 찾아냅니다.

---

## 핵심 기능

### 1. 멀티모달 감정 분석
- 얼굴 표정 분석 (FER — Deep Learning 기반 7가지 감정 분류)
- 목소리 감정 분석 (Whisper STT + librosa 피치·에너지)
- 영상 전체 분위기 분석 (CLIP 모델)
- 사람·동물(개, 고양이)·애니 캐릭터 자동 분류 (YOLOv8)
- 초 단위 감정 타임라인 생성

### 2. AI 크리에이터 코치 (Gemini API)
- 분석 결과를 기반으로 구체적 개선 피드백 생성
- 예: "3~7초 구간 강아지 눈 맞춤 장면이 핵심입니다. 썸네일로 활용하세요"
- 채팅 인터페이스로 자유 질문 가능

### 3. 바이럴 점수 예측
- 감정 패턴 기반 0~100점 예측 (S/A/B/C/D 등급)
- 얼굴·음성·영상 분위기 종합 분석

### 4. 경쟁 영상 비교 분석
- 내 영상 vs 조회수 100만+ 영상 감정 패턴 비교
- 초반 3초, 중반, 후반부 감정 강도 차이 시각화

### 5. 실시간 감정 트렌드
- 최근 바이럴 영상 감정 패턴 분석
- "지금 유행하는 감정 흐름" 트렌드 제공

### 6. 동물·애니 특화 분석
- YOLOv8으로 피사체 자동 감지
- 동물: 귀, 꼬리, 눈 움직임 기반 감정 분류
- 애니: 캐릭터 표정 특화 모델 적용

---

## 시스템 아키텍처

### 전체 데이터 흐름

```mermaid
flowchart TD
    A([사용자\nURL 입력 또는 영상 업로드])

    A --> B[웹 / 모바일 앱]
    B --> C[FastAPI 백엔드]

    C --> D[영상 전처리\nyt-dlp 다운로드 → OpenCV 프레임 추출 → ffmpeg 음성 분리]

    D --> E[얼굴·객체 분석\nYOLOv8 감지 → 사람 / 동물 / 애니 분류 → FER 표정 인식]
    D --> F[음성 분석\nWhisper 음성→텍스트 → librosa 피치·에너지 → 감정 분류]
    D --> G[영상 분위기 분석\nCLIP 장면 임베딩 → 색감·밝기·속도 점수]

    H([YouTube Data API\n실제 조회수 · 좋아요])

    E & F & G & H --> I[멀티모달 융합 엔진\n얼굴 + 음성 + 영상 분위기 → 초 단위 감정 타임라인]

    I --> J[Gemini API\n감정 해석 + 바이럴 요인 분석 + 크리에이터 피드백 생성]
    I --> K[바이럴 점수 예측\n감정 패턴 분석 → 0~100점]

    J & K --> L[웹 대시보드\n감정 타임라인 · 히트맵 · 경쟁 비교 · 트렌드]
    J & K --> M[Flutter 앱\nAI 코치 챗봇 · 바이럴 점수 · 트렌드 피드]
```

---

### 플랫폼 구성

```mermaid
flowchart LR
    subgraph FE["프론트엔드"]
        W["웹 대시보드 (React)\n─────────────\n감정 타임라인 그래프\n감정 히트맵\n경쟁 영상 비교\n바이럴 점수"]
        M["Flutter 모바일\n─────────────\nURL 공유 즉시 분석\nAI 코치 챗봇\n바이럴 점수 위젯\n트렌드 피드"]
    end

    subgraph BE["백엔드 (FastAPI)"]
        B1["영상 분석 API"]
        B2["AI 코치 API"]
        B3["트렌드 API"]
        B4["사용자 API"]
    end

    subgraph DB["데이터"]
        D1[("PostgreSQL\n분석 결과 저장")]
        D2[("Redis\n캐시")]
    end

    W <--> BE
    M <--> BE
    BE <--> DB
```

---

### AI 분석 파이프라인

```mermaid
flowchart TD
    A([입력 영상]) --> B[YOLOv8\n피사체 자동 감지]

    B --> C["사람 트랙\nFER Deep Learning\n→ 기쁨·슬픔·분노·공포·놀람·혐오·중립"]
    B --> D["동물 트랙\n귀·꼬리·눈 움직임 감지\n→ 행복·불안·흥분·졸림"]
    B --> E["애니 트랙\n과장 표정 보정 모델\n→ 캐릭터 감정 분류"]

    C & D & E --> F["감정 타임라인 생성\n초 단위 감정 벡터 통합"]

    F --> G["Gemini API\n감정 해석 + 개선 피드백"]
    F --> H["바이럴 점수\nS/A/B/C/D 등급"]
```

---

### 배포 구성 (Docker)

```mermaid
flowchart LR
    subgraph Docker["Docker Compose"]
        FE["React 프론트엔드\n:3000 (Nginx)"]
        BE["FastAPI 백엔드\n:8000"]
        DB["PostgreSQL\n:5432"]
    end

    User([사용자]) --> FE
    FE -->|"/api 프록시"| BE
    BE --> DB
    BE -->|"외부 API"| YT["YouTube Data API"]
    BE -->|"외부 API"| GEM["Gemini API"]
```

---

## 기술 스택

| 분류 | 기술 | 용도 |
|------|------|------|
| **모바일** | Flutter (Dart) | iOS / Android 크로스플랫폼 |
| **웹 프론트엔드** | React + Recharts | 대시보드 시각화 |
| **백엔드** | Python, FastAPI | REST API 서버 |
| **얼굴 분석** | FER (Deep Learning) | 7가지 감정 분류 |
| **객체 감지** | YOLOv8 | 사람·동물·애니 분류 |
| **음성 분석** | OpenAI Whisper + librosa | STT + 피치·에너지 감정 |
| **영상 분위기** | CLIP (OpenAI) | 장면 임베딩 분석 |
| **AI 코치** | Google Gemini API (gemini-2.5-flash) | 감정 해석 + 피드백 생성 |
| **영상 처리** | OpenCV + ffmpeg + yt-dlp | 프레임 추출 + 음성 분리 |
| **데이터** | YouTube Data API v3 | 조회수·좋아요 연동 |
| **DB** | PostgreSQL + Redis | 결과 저장 + 캐싱 |
| **배포** | Docker Compose | 컨테이너 배포 |

---

## 폴더 구조

```
vibeview/
├── mobile/                        # Flutter 모바일 앱
│   ├── lib/
│   │   └── main.dart              # 앱 전체 (화면 + 서비스 통합)
│   └── pubspec.yaml
│
├── web/                           # React 웹 대시보드
│   ├── src/
│   │   └── App.js                 # 대시보드 전체 (감정 타임라인, 코치 채팅)
│   └── package.json
│
├── server/                        # FastAPI 백엔드
│   ├── main.py                    # 앱 진입점, CORS 설정
│   ├── routers/
│   │   ├── analyze.py             # 영상 분석 엔드포인트
│   │   ├── coach.py               # AI 코치 엔드포인트
│   │   ├── trend.py               # 트렌드 엔드포인트
│   │   └── user.py                # 사용자 엔드포인트
│   ├── services/
│   │   ├── video_processor.py     # yt-dlp + OpenCV + ffmpeg
│   │   ├── face_analyzer.py       # FER + Gemini Vision
│   │   ├── audio_analyzer.py      # Whisper + librosa
│   │   ├── scene_analyzer.py      # CLIP 영상 분위기
│   │   ├── animal_analyzer.py     # YOLOv8 동물 분석
│   │   ├── fusion_engine.py       # 멀티모달 융합
│   │   ├── viral_predictor.py     # 바이럴 점수 예측
│   │   ├── gemini_coach.py        # Gemini API 코치
│   │   └── youtube_service.py     # YouTube Data API 연동
│   ├── cookies.txt.example        # yt-dlp 쿠키 파일 예시 (실제 파일은 gitignore)
│   ├── env.example                # 환경변수 예시
│   ├── Dockerfile
│   ├── auto_collect.py            # 바이럴 영상 자동 수집 스크립트
│   └── requirements.txt
│
├── web/
│   ├── Dockerfile
│   └── nginx.conf
│
├── docker-compose.yml
├── env.example                    # 루트 환경변수 예시
└── README.md
```

---

## 설치 및 실행

### 요구 사항

| 항목 | 버전 |
|------|------|
| Python | 3.11 이상 |
| Flutter | 3.x 이상 |
| Node.js | 18 이상 |
| Docker | 최신 버전 |
| ffmpeg | 최신 버전 |

### 환경 변수 설정

루트의 `env.example`을 복사해 `.env`로 저장하고 실제 값을 입력합니다.

```bash
cp env.example .env
cp server/env.example server/.env
```

```env
DB_PASSWORD=your_db_password
GEMINI_API_KEY=your_gemini_api_key
GOOGLE_API_KEY=your_google_api_key
YOUTUBE_API_KEY=your_youtube_data_api_key
```

### 백엔드 로컬 실행

```bash
cd server
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### 웹 프론트엔드 로컬 실행

```bash
cd web
npm install
npm start
```

### Flutter 모바일 실행

```bash
cd mobile
flutter pub get
flutter run -d chrome        # 웹 테스트
flutter run                  # 연결된 기기
```

---

## Docker 배포

```bash
# .env 파일 설정 후
docker compose up --build -d

# 서비스 확인
docker compose ps
```

| 서비스 | 주소 |
|--------|------|
| 웹 대시보드 | http://localhost:3000 |
| 백엔드 API | http://localhost:8000 |
| API 문서 | http://localhost:8000/docs |

> yt-dlp 쿠키가 필요한 경우 `server/cookies.txt.example`을 참고해 `server/cookies.txt`를 생성하세요.

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
  "viral_grade": "A",
  "dominant_emotion": "happy",
  "subjects": ["person", "dog"],
  "face_summary": { ... },
  "audio_summary": { ... }
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
Response: { "trends": [...] }  // 최근 감정 트렌드
```

---

## 개발 로드맵

### 중간 발표 목표

```mermaid
gantt
    title VibeView 중간 발표 로드맵
    dateFormat  YYYY-MM-DD
    section 1-2주차
    개발 환경 세팅 & 폴더 구조    :done, 2025-03-19, 5d
    FastAPI 기본 서버             :done, 2025-03-24, 5d
    yt-dlp 영상 다운로드          :done, 2025-03-24, 5d
    section 3-4주차
    FER 얼굴 감정 분석            :done, 2025-03-31, 7d
    Whisper 음성 분석             :done, 2025-03-31, 7d
    YOLOv8 객체 감지              :done, 2025-04-07, 7d
    감정 타임라인 생성            :done, 2025-04-10, 4d
    section 5-6주차
    Gemini API 코치 연동          :done, 2025-04-14, 7d
    멀티모달 융합 엔진            :done, 2025-04-14, 7d
    웹 대시보드 UI                :done, 2025-04-21, 7d
    section 7-8주차
    Flutter 모바일 앱             :done, 2025-04-28, 7d
    통합 테스트 & 발표 준비       :done, 2025-05-05, 10d
    중간 발표                     :milestone, 2025-05-14, 0d
```

### 최종 발표 목표

```mermaid
gantt
    title VibeView 최종 발표 로드맵
    dateFormat  YYYY-MM-DD
    section 6월
    YOLOv8 동물·애니 분류 고도화  :2025-05-21, 14d
    CLIP 영상 분위기 분석         :2025-06-02, 14d
    section 7월
    바이럴 점수 ML 모델           :2025-06-16, 21d
    YouTube API 데이터 연동       :2025-06-23, 14d
    경쟁 영상 비교 기능           :2025-07-07, 14d
    section 8월
    감정 트렌드 분석              :2025-07-21, 14d
    Flutter 앱 완성               :2025-08-04, 14d
    Docker 배포                   :2025-08-11, 7d
    section 9월
    전체 통합 테스트              :2025-08-18, 14d
    성능 최적화 & 발표 준비       :2025-08-25, 17d
    최종 발표                     :milestone, 2025-09-12, 0d
```

---

## 핵심 차별점

- **멀티모달 AI**: 얼굴 + 음성 + 영상 분위기를 동시에 분석 (단일 모달 대비 정확도 향상)
- **실제 데이터 연동**: YouTube Data API로 실제 조회수와 감정 패턴을 연결
- **사람·동물·애니 지원**: YOLOv8 기반 피사체 자동 분류 및 특화 모델 적용
- **크로스플랫폼**: 웹 대시보드 + Flutter 모바일 앱 동시 지원
- **AI 코치**: 단순 분석을 넘어 Gemini API 기반 실용적 개선 제안 제공

---

*VibeView — 감정이 조회수를 만든다*
