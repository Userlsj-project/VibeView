# 🎬 VibeView - 프로젝트 컨텍스트

> ⚠️ 이 파일은 새 채팅창에서 Claude에게 업로드하여 프로젝트를 이어서 개발할 때 사용합니다.
> 새 채팅창에서 이 파일을 업로드한 후 아래처럼 말하세요:
> "이 파일은 내가 개발 중인 VibeView 졸업작품이야. 이어서 개발해줘."

---

## 🤖 Claude AI 행동 지침 (필독)

> **Claude는 아래 규칙을 반드시 따라야 합니다:**
>
> 1. **코드 전달 전 반드시 검토**: 코드를 작성하기 전에 로직, 문법, 의존성을 스스로 검토하고 문제가 없는 경우에만 전달한다.
> 2. **불확실한 정보는 검색 후 전달**: API 옵션명, 라이브러리 버전, 설정값 등 확신이 없는 정보는 반드시 웹 검색으로 확인 후 전달한다.
> 3. **틀린 정보를 전달했을 경우 즉시 인정**: 이전에 잘못된 정보를 전달했다면 즉시 인정하고 정확한 정보로 교체한다.
> 4. **추측으로 코드를 작성하지 않는다**: 동작 여부가 불확실한 코드는 "확인이 필요합니다"라고 먼저 말하고 검증 방법을 제시한다.
> 5. **파일 전달 시 전체 코드 제공**: 일부만 수정하라고 할 때는 변경된 부분을 명확히 표시하고, 전체 파일이 필요한 경우 전체를 제공한다.
> 6. **컨텍스트 초과 전 CONTEXT.md 업데이트**: 대화가 길어지면 반드시 최신 상태를 반영한 CONTEXT.md를 제공한다.
> 7. **백엔드 코드 확인 요청**: 프론트엔드에서 백엔드 API를 호출하는 코드를 작성하기 전에, 반드시 해당 라우터 파일(`routers/*.py`)의 실제 내용을 확인한 후 작성한다. 확인 전에 추측으로 작성하지 않는다.
> 8. **Pydantic 스키마 확인 후 요청 형식 결정**: API 요청/응답 형식은 반드시 실제 Pydantic 모델을 확인한 후 맞춰서 작성한다.

---

## 📋 코드 정확성을 위해 Claude가 요청할 사항

> 새 기능 개발 시 Claude가 아래 파일들을 보여달라고 요청할 수 있습니다.
> 요청받으면 `type 파일경로` 명령어로 내용을 캡처해서 전달해주세요.

| 상황 | Claude가 요청할 파일 | 명령어 |
|------|------|------|
| 새 API 연동 시 | 해당 라우터 파일 | `type C:\dev\vibeview\server\routers\*.py` |
| 서비스 로직 수정 시 | 해당 서비스 파일 | `type C:\dev\vibeview\server\services\*.py` |
| Flutter 앱 개발 시 | pubspec.yaml | `type C:\dev\vibeview\mobile\pubspec.yaml` |
| DB 연동 시 | main.py 전체 | `type C:\dev\vibeview\server\main.py` |
| 오류 발생 시 | 백엔드 터미널 에러 로그 | uvicorn 실행 터미널 스크린샷 |
| React 빌드 오류 시 | 브라우저 콘솔 에러 | F12 → Console 탭 스크린샷 |

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **프로젝트명** | VibeView |
| **슬로건** | 감정이 조회수를 만든다 |
| **분석 대상** | YouTube Shorts, TikTok, 애니메이션 영상 |
| **분석 요소** | 사람·동물 표정 / 목소리 감정 / 영상 전체 분위기 |
| **결과물** | 웹 대시보드 (React) + Flutter 모바일 앱 |
| **GitHub** | https://github.com/Userlsj-project/VibeView.git |
| **브랜치** | master |
| **로컬 경로** | C:\dev\vibeview |
| **중간 발표** | 2026년 5월 (약 2개월 후) |
| **최종 발표** | 2026년 9월 (약 6개월 후) |

---

## 개발 환경

| 항목 | 버전/상태 |
|------|------|
| OS | Windows 11 |
| Python | 3.11.9 (C:\Python311) ✅ |
| Flutter | 3.41.4 ✅ |
| Android Studio | Panda 2 ✅ |
| Node.js | v25.8.1 ✅ |
| ffmpeg | master-latest-win64-gpl (C:\ffmpeg_temp\ffmpeg-master-latest-win64-gpl\bin) ✅ |

---

## 기술 스택

| 분류 | 기술 | 용도 |
|------|------|------|
| **모바일** | Flutter (Dart) | iOS/Android 크로스플랫폼 |
| **웹 프론트엔드** | React + Recharts | 대시보드 시각화 |
| **백엔드** | Python, FastAPI | REST API 서버 |
| **AI 코치** | Gemini API (gemini-2.5-flash) | 감정 해석 + 피드백 (무료) |
| **얼굴 분석** | MediaPipe FaceMesh | 표정 분석 |
| **객체 감지** | YOLOv8 | 사람·동물·애니 분류 |
| **음성 분석** | Whisper (로컬, base 모델) + librosa | STT(99개 언어 자동 감지) + 감정 분석 |
| **영상 분위기** | CLIP | 장면 임베딩 |
| **영상 처리** | OpenCV + ffmpeg + yt-dlp | 프레임 추출 + 음성 분리 |
| **데이터** | YouTube Data API v3 | 조회수 연동 |
| **DB** | PostgreSQL + Redis | 저장 + 캐싱 |
| **배포** | Docker + AWS EC2 | 컨테이너 배포 |

---

## 중요 설정

### Gemini API
- **모델명**: `gemini-2.5-flash` (무료 티어 사용 가능 확인됨)
- **API 키**: `.env` 파일에 저장됨
- **환경변수명**: `GEMINI_API_KEY`, `GOOGLE_API_KEY` (둘 다 같은 키로 설정)

### .env 파일 위치
```
C:\dev\vibeview\server\.env
```

### 서버 실행 방법
```bash
cd C:\dev\vibeview\server
uvicorn main:app --reload --port 8000
```

### React 웹 대시보드 실행 방법
```bash
cd C:\dev\vibeview\web
npm start
```

### API 문서 확인
```
http://localhost:8000/docs
```

### yt-dlp YouTube 다운로드 설정
- 쿠키 파일: `C:\dev\vibeview\server\cookies.txt` (Chrome YouTube 로그인 쿠키)
- JS 런타임: Node.js v25.8.1
- **Python API 옵션 (검증 완료):**
  ```python
  "js_runtimes": {"node": {}},       # 딕셔너리 형식 (문자열 리스트 아님)
  "remote_components": {"ejs:github"}, # set 형식 (문자열 아님)
  "cookiefile": "C:\\dev\\vibeview\\server\\cookies.txt",
  "format": "best[height<=720]/best",  # 복잡한 포맷 조건 사용 금지
  ```
- 추가 패키지: `yt-dlp` (최신버전), `yt-dlp-ejs` (pip 설치됨)
- **주의**: `extractor_args`로 js_runtimes 지정하면 동작 안 함. 반드시 위 형식 사용

---

## 폴더 구조

```
C:\dev\vibeview\
├── server\
│   ├── main.py                    ✅ 완료
│   ├── requirements.txt           ✅ 완료
│   ├── cookies.txt                ✅ 완료 (Chrome YouTube 쿠키, 공유 금지)
│   ├── .env                       ✅ 완료 (API 키 설정됨)
│   ├── routers\
│   │   ├── __init__.py            ✅ 완료
│   │   ├── analyze.py             ✅ 완료 (face + audio 분석 연결)
│   │   ├── coach.py               ✅ 완료 (Gemini API 연동)
│   │   ├── trend.py               ✅ 완료 (기본 구조)
│   │   └── user.py                ✅ 완료 (기본 구조)
│   └── services\
│       ├── gemini_coach.py        ✅ 완료 (Gemini API 연동, 테스트 성공)
│       ├── video_processor.py     ✅ 완료 (yt-dlp + OpenCV + ffmpeg, 테스트 성공)
│       ├── face_analyzer.py       ✅ 완료 (MediaPipe FaceMesh)
│       ├── audio_analyzer.py      ✅ 완료 (Whisper base + librosa)
│       ├── animal_analyzer.py     ⬜ 미구현
│       ├── scene_analyzer.py      ⬜ 미구현
│       ├── fusion_engine.py       ⬜ 미구현
│       └── viral_predictor.py     ⬜ 미구현
├── web\                           ✅ 진행 중
│   └── src\
│       ├── App.js                 ✅ 완료 (감정 대시보드 UI)
│       ├── App.css                ✅ 완료
│       └── index.css              ✅ 완료
├── mobile\                        ⬜ 미구현
├── README.md                      ✅ 완료
└── CONTEXT.md                     ✅ 이 파일
```

---

## requirements.txt 내용

```
# Web Framework
fastapi==0.115.0
uvicorn==0.30.6

# HTTP
httpx==0.27.2
python-multipart==0.0.9

# AI / ML
google-generativeai==0.8.3
torch==2.4.1
torchvision==0.19.1
transformers==4.45.1
ultralytics==8.2.103
mediapipe==0.10.14
librosa==0.10.2
opencv-python==4.10.0.84
Pillow==10.4.0
openai-whisper

# Video Processing
yt-dlp
yt-dlp-ejs

# Database
sqlalchemy==2.0.35
asyncpg==0.29.0
redis==5.1.1

# Utils
python-dotenv==1.0.1
pydantic==2.9.2
pydantic-settings==2.5.2
```

---

## API 엔드포인트 현황

| 메서드 | 경로 | 상태 | 설명 |
|--------|------|------|------|
| POST | /api/analyze | ✅ 동작 확인 | 영상 URL → 감정 분석 전체 파이프라인 |
| POST | /api/coach | ✅ 동작 확인 | Gemini AI 코치 피드백 |
| GET | /api/trend | ⬜ 기본 구조 | 감정 트렌드 |
| GET | /api/user | ⬜ 기본 구조 | 사용자 정보 |

### /api/analyze 요청 형식
```json
{ "url": "https://youtube.com/shorts/..." }
```

### /api/analyze 응답 구조 (실제 테스트 확인)
```json
{
  "status": "success",
  "video_info": {"duration": float, "fps": float, "width": int, "height": int, "total_frames": int},
  "face_summary": {
    "emotion_distribution": {"neutral": float, ...},
    "avg_valence": float,
    "peak_emotion": {"timestamp": float, "emotion": str, "valence": float}
  },
  "audio_summary": {
    "avg_valence": float,
    "dominant_emotion": str,
    "tempo": float,
    "language": str,
    "full_text": str
  },
  "emotion_timeline": [
    {"timestamp": float, "face_emotion": str, "face_valence": float,
     "face_count": int, "audio_emotion": str, "audio_valence": float, "audio_energy": float}
  ]
}
```

### /api/coach 요청 형식 (Pydantic 모델 확인 완료)
```json
{
  "video_id": "string",
  "emotion_data": {
    "face_summary": {...},
    "audio_summary": {...},
    "video_info": {...}
  },
  "question": "string (optional, None 가능)"
}
```

### /api/coach 응답 형식
```json
{ "feedback": "string" }
```

---

## React 웹 대시보드 현황

### 설치된 패키지
```
react, recharts, axios
```

### 구현된 기능
- YouTube URL 입력 → 백엔드 `/api/analyze` 호출
- 영상 기본 정보 표시 (duration, fps, resolution, frames)
- 얼굴 감정 분포 바 차트 + peak emotion 표시
- 음성 감정 (dominant, tempo, language, transcript) 표시
- 초 단위 감정 타임라인 LineChart (Recharts)
- Gemini AI 코치 피드백 (`/api/coach` 연동)
- 로딩 스피너, 에러 메시지 처리
- 반응형 레이아웃 (768px, 480px 미디어쿼리)
- 다크 사이버 테마 (Space Mono + Syne 폰트)

### CORS 설정 필요 여부
- 현재 로컬 개발 환경에서는 문제없음
- 배포 시 백엔드 `main.py`에 CORS 설정 추가 필요

---

## 작업 현황

- [x] 개발 환경 세팅 (Python 3.11, Flutter, Node.js, ffmpeg)
- [x] GitHub 저장소 연결 (VibeView, master 브랜치)
- [x] 폴더 구조 생성
- [x] FastAPI 기본 서버 구현 및 실행 확인
- [x] Gemini API 연동 및 테스트 성공 (gemini-2.5-flash)
- [x] AI 코치 API 엔드포인트 구현 (/api/coach)
- [x] 영상 처리 (yt-dlp + OpenCV + ffmpeg) — 테스트 성공
- [x] 얼굴 감정 분석 (MediaPipe FaceMesh)
- [x] 음성 감정 분석 (Whisper base + librosa)
- [x] 영상 분석 API 완성 (/api/analyze) — 200 응답 확인
- [x] React 웹 대시보드 기본 UI 완성 — 실제 분석 동작 확인
- [x] .gitignore 설정 완료
- [ ] React AI 코치 버튼 동작 최종 확인 (coach.py 스키마 맞춤 완료, 테스트 필요)
- [ ] scene_analyzer.py (YOLOv8 + CLIP)
- [ ] fusion_engine.py (멀티모달 융합)
- [ ] Flutter 모바일 앱
- [ ] YouTube Data API 연동
- [ ] 바이럴 점수 ML 모델
- [ ] 감정 트렌드 API

---

## 중간 발표까지 완성 목표 기능 (2026년 5월)

1. YouTube Shorts URL 입력 → 영상 다운로드 ✅
2. 얼굴 + 음성 감정 분석 ✅
3. 초 단위 감정 타임라인 생성 ✅
4. Gemini AI 코치 피드백 ✅ (백엔드), ⬜ (프론트 최종 확인 필요)
5. 웹 대시보드 기본 UI ✅
6. Flutter 앱 기본 화면 ⬜

---

## 다음 작업 순서 (중간 발표 우선순위)

1. **AI 코치 버튼 최종 확인** — 수정된 App.js 적용 후 동작 테스트
2. **Flutter 앱** - 기본 화면 (URL 입력 + 결과 표시)
3. **scene_analyzer.py** - YOLOv8 + CLIP
4. **fusion_engine.py** - 멀티모달 감정 융합
5. **viral_predictor.py** - 바이럴 점수 예측

---

## 새 채팅창 사용법

이 파일을 업로드한 후:
```
이 파일은 내가 개발 중인 VibeView 졸업작품이야.
중간 발표가 5월이라 시간이 없어.
이어서 개발해줘.
코드 작성 전에 관련 백엔드 파일 확인이 필요하면 먼저 요청해줘.
새 채팅창도 컨텍스트가 넘어가기 전에 이 CONTEXT.md를 업데이트해서 줘.
```

---

## 주의사항

- 코드 전달 전 반드시 정확성 검토 후 전달
- **새 API 연동 전 반드시 라우터 파일 내용 확인 요청할 것**
- Gemini 모델명: `gemini-2.5-flash` (다른 버전 사용 금지)
- pip 대신 항상 `pip install` 사용 (Python 3.11 경로: C:\Python311)
- 서버는 `uvicorn main:app --reload --port 8000` 으로 실행
- yt-dlp Python API js_runtimes: `{"node": {}}` 딕셔너리 형식 (검증 완료)
- yt-dlp Python API remote_components: `{"ejs:github"}` set 형식 (검증 완료)
- yt-dlp format: `"best[height<=720]/best"` 사용 (복잡한 포맷 조건 사용 금지)
- cookies.txt는 절대 외부에 공유하지 말 것
- 새 채팅창에서도 컨텍스트 초과 전에 반드시 CONTEXT.md 업데이트 버전 제공
