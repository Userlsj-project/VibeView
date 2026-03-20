# VibeView - 프로젝트 컨텍스트

> 이 파일은 새 채팅창에서 Claude에게 업로드하여 프로젝트를 이어서 개발할 때 사용합니다.
> 새 채팅창에서 이 파일을 업로드한 후 아래처럼 말하세요:
> "이 파일은 내가 개발 중인 VibeView 졸업작품이야. 로드맵 순서대로 이어서 개발해줘."

---

## Claude AI 행동 지침 (필독)

Claude는 아래 규칙을 반드시 따라야 합니다:

1. **코드 전달 전 반드시 검토**: 코드를 작성하기 전에 로직, 문법, 의존성을 스스로 검토하고 문제가 없는 경우에만 전달한다.
2. **불확실한 정보는 검색 후 전달**: API 옵션명, 라이브러리 버전, 설정값 등 확신이 없는 정보는 반드시 웹 검색으로 확인 후 전달한다.
3. **틀린 정보를 전달했을 경우 즉시 인정**: 이전에 잘못된 정보를 전달했다면 즉시 인정하고 정확한 정보로 교체한다.
4. **추측으로 코드를 작성하지 않는다**: 동작 여부가 불확실한 코드는 "확인이 필요합니다"라고 먼저 말하고 검증 방법을 제시한다.
5. **파일 전달 시 전체 코드 제공**: 일부만 수정하라고 할 때는 변경된 부분을 명확히 표시하고, 전체 파일이 필요한 경우 전체를 제공한다.
6. **컨텍스트 초과 전 CONTEXT.md 업데이트**: 대화가 길어지면 반드시 최신 상태를 반영한 CONTEXT.md를 제공한다.
7. **백엔드 코드 확인 요청**: 프론트엔드에서 백엔드 API를 호출하는 코드를 작성하기 전에, 반드시 해당 라우터 파일의 실제 내용을 확인한 후 작성한다.
8. **Pydantic 스키마 확인 후 요청 형식 결정**: API 요청/응답 형식은 반드시 실제 Pydantic 모델을 확인한 후 맞춰서 작성한다.
9. **로드맵 순서 준수**: 아래 개발 로드맵 순서대로 진행한다. 새 채팅창이 시작되면 현재 완료된 단계를 확인하고 다음 단계를 안내한다.
10. **[중요] 작업 전 필요한 정보를 먼저 요청한다**: 작업을 시작하기 전에 필요한 파일, 현재 코드 상태, 설정값 등을 사전에 파악하고 사용자에게 먼저 요청한다. 나중에 "확인이 필요했다"고 말하지 않는다.
11. **Flutter 파일 수정 시 반드시 오류 검증**: Dart 파일 작성 후 반드시 아래 항목을 검증한다. (1) CustomPainter 내부에서 전역 k* 상수 직접 사용 여부 - static const 별칭 필요 (2) Color를 Paint 자리에 직접 전달 여부 (3) 메서드 파라미터에 없는 변수(r 등) 사용 여부 (4) const 위젯 안에 non-const 표현식 사용 여부 (5) 브라켓/괄호 쌍 일치 여부

---

## 코드 정확성을 위해 Claude가 요청할 사항

새 기능 개발 시 Claude가 아래 파일들을 보여달라고 요청합니다.
요청받으면 `type 파일경로` 명령어로 내용을 캡처해서 전달해주세요.

| 상황 | Claude가 요청할 파일 | 명령어 |
|------|------|------|
| 새 API 연동 시 | 해당 라우터 파일 | `type C:\dev\vibeview\server\routers\파일명.py` |
| 서비스 로직 수정 시 | 해당 서비스 파일 | `type C:\dev\vibeview\server\services\파일명.py` |
| CORS / 미들웨어 수정 시 | main.py 전체 | `type C:\dev\vibeview\server\main.py` |
| Flutter 앱 수정 시 | pubspec.yaml | `type C:\dev\vibeview\mobile\pubspec.yaml` |
| 오류 발생 시 | 백엔드 터미널 에러 로그 | uvicorn 실행 터미널 스크린샷 |
| Flutter 오류 시 | 터미널 전체 오류 | flutter run 터미널 스크린샷 |
| React 오류 시 | 브라우저 콘솔 에러 | F12 -> Console 탭 스크린샷 |

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **프로젝트명** | VibeView |
| **슬로건** | 감정이 조회수를 만든다 |
| **분석 대상** | YouTube Shorts, TikTok, 애니메이션 영상 |
| **분석 요소** | 사람/동물 표정, 목소리 감정, 영상 전체 분위기 |
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
| Python | 3.11.9 (C:\Python311) |
| Flutter | 3.41.4 |
| Android Studio | Panda 2 |
| Node.js | v25.8.1 |
| ffmpeg | master-latest-win64-gpl (C:\ffmpeg_temp\ffmpeg-master-latest-win64-gpl\bin) |
| Android SDK | 36.1.0 |
| Android 에뮬레이터 | Medium_Phone_API_36.1 |

---

## 기술 스택

| 분류 | 기술 | 용도 |
|------|------|------|
| **모바일** | Flutter (Dart) | iOS/Android 크로스플랫폼 |
| **웹 프론트엔드** | React + Recharts | 대시보드 시각화 |
| **백엔드** | Python, FastAPI | REST API 서버 |
| **AI 코치** | Gemini API (gemini-2.5-flash) | 감정 해석 + 피드백 (무료) |
| **얼굴 분석** | MediaPipe FaceMesh | 표정 분석 |
| **객체 감지** | YOLOv8 | 사람/동물/애니 분류 |
| **음성 분석** | Whisper (로컬, base 모델) + librosa | STT + 감정 분석 |
| **영상 분위기** | CLIP | 장면 임베딩 |
| **영상 처리** | OpenCV + ffmpeg + yt-dlp | 프레임 추출 + 음성 분리 |
| **데이터** | YouTube Data API v3 | 조회수 연동 |
| **DB** | PostgreSQL + Redis | 저장 + 캐싱 |
| **배포** | Docker + AWS EC2 | 컨테이너 배포 |

---

## 중요 설정

### Gemini API
- 모델명: gemini-2.5-flash (무료 티어 사용 가능 확인됨, 다른 버전 사용 금지)
- API 키: .env 파일에 저장됨
- 환경변수명: GEMINI_API_KEY, GOOGLE_API_KEY (둘 다 같은 키로 설정)

### 서버 실행 방법
```
터미널 1 - 백엔드:
cd C:\dev\vibeview\server
uvicorn main:app --reload --port 8000

터미널 2 - 프론트엔드 (웹):
cd C:\dev\vibeview\web
npm start

터미널 3 - Flutter 앱:
flutter emulators --launch Medium_Phone_API_36.1
cd C:\dev\vibeview\mobile
flutter run
```

### API 문서 확인
http://localhost:8000/docs

### Flutter 에뮬레이터 API 주소
- 에뮬레이터에서 localhost는 10.0.2.2로 접근 (이미 코드에 반영됨)
- const String kApiBase = 'http://10.0.2.2:8000';

### Gradle 설정 (학교 네트워크 주의)
- gradle-8.14-all.zip 파일을 직접 다운로드해서 아래 경로에 넣어야 함
- 경로: C:\Users\이성준\.gradle\wrapper\dists\gradle-8.14-all\c2qonpi39x1mddn7hk5gh9iqj\
- 학교 네트워크에서는 자동 다운로드가 막힘

### yt-dlp YouTube 다운로드 설정
- 쿠키 파일: C:\dev\vibeview\server\cookies.txt (Chrome YouTube 로그인 쿠키, 공유 금지)
- Python API 옵션 (검증 완료):
```python
"js_runtimes": {"node": {}},
"remote_components": {"ejs:github"},
"cookiefile": "C:\\dev\\vibeview\\server\\cookies.txt",
"format": "best[height<=720]/best",
```
- 주의: extractor_args로 js_runtimes 지정하면 동작 안 함. 반드시 위 형식 사용

---

## 폴더 구조

```
C:\dev\vibeview\
├── server\
│   ├── main.py                    완료 (CORS 설정 포함)
│   ├── requirements.txt           완료
│   ├── cookies.txt                완료 (공유 금지)
│   ├── .env                       완료 (API 키 설정됨)
│   ├── routers\
│   │   ├── __init__.py            완료
│   │   ├── analyze.py             완료
│   │   ├── coach.py               완료
│   │   ├── trend.py               완료 (기본 구조)
│   │   └── user.py                완료 (기본 구조)
│   └── services\
│       ├── gemini_coach.py        완료
│       ├── video_processor.py     완료
│       ├── face_analyzer.py       완료
│       ├── audio_analyzer.py      완료
│       ├── animal_analyzer.py     미구현
│       ├── scene_analyzer.py      미구현
│       ├── fusion_engine.py       미구현
│       └── viral_predictor.py     미구현
├── web\                           완료 (React 대시보드)
│   └── src\
│       ├── App.js                 완료
│       ├── App.css                완료
│       └── index.css              완료
├── mobile\                        완료 (Flutter 앱 기본 동작)
│   ├── lib\
│   │   └── main.dart              완료 (SD 수인 캐릭터 + 감정 분석 연동)
│   └── pubspec.yaml               완료 (http 패키지 포함)
├── README.md                      완료
└── CONTEXT.md                     이 파일
```

---

## API 엔드포인트 현황

| 메서드 | 경로 | 상태 | 설명 |
|--------|------|------|------|
| POST | /api/analyze | 동작 확인 | 영상 URL -> 감정 분석 전체 파이프라인 |
| POST | /api/coach | 동작 확인 | Gemini AI 코치 피드백 |
| GET | /api/trend | 기본 구조 | 감정 트렌드 (미구현) |
| GET | /api/user | 기본 구조 | 사용자 정보 (미구현) |

### /api/analyze 요청
```json
{ "url": "https://youtube.com/shorts/..." }
```

### /api/analyze 응답 구조
```json
{
  "status": "success",
  "video_info": {"duration": float, "fps": float, "width": int, "height": int, "total_frames": int},
  "face_summary": {
    "emotion_distribution": {"happy": float, "neutral": float, ...},
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

### /api/coach 요청 (Pydantic 모델 확인 완료)
```json
{
  "video_id": "string",
  "emotion_data": { "face_summary": {}, "audio_summary": {}, "video_info": {} },
  "question": "string (optional, None 가능)"
}
```

### /api/coach 응답
```json
{ "feedback": "string" }
```

---

## Flutter 앱 현황

### 구현된 기능
- URL 입력 화면 (홈)
- 백엔드 /api/analyze 호출 (타임아웃 5분)
- 결과 화면: 비디오 정보, 얼굴 감정 바, 음성 감정, 타임라인 바 차트
- Gemini AI 코치 버튼 (/api/coach 연동)
- SD 수인 캐릭터 (CustomPainter, 사람 기반 백호)
- 감정별 표정 5종: idle, thinking, happy, sad, surprised, angry
- 둥실둥실 float 애니메이션 + thinking 시 빙글빙글 회전
- 밝은 민트/화이트 테마

### Flutter 패키지
```yaml
dependencies:
  flutter: sdk
  http: ^1.6.0
```

### 캐릭터 관련 향후 계획
- 현재: CustomPainter로 그린 SD 수인 캐릭터 (임시)
- 향후 (앱 기능 완성 후): AI 이미지 생성 툴로 고퀄리티 PNG 캐릭터 제작
  - 감정별 5종 PNG 이미지 (idle, happy, sad, surprised, angry, thinking)
  - 캐릭터 종류 4종 추가 예정 (백호, 강아지, 고양이, 판다)
  - 앱 시작 시 랜덤으로 캐릭터 1종 등장
  - Image.asset()으로 교체 예정
- PNG 교체 작업은 Phase 3 (최종 발표 전) 진행

---

## 개발 로드맵 (Claude가 이 순서대로 진행합니다)

새 채팅창 시작 시 Claude는 아래 단계 중 현재 위치를 확인하고 다음 단계를 안내합니다.
각 단계 완료 시 완료로 표시하고 CONTEXT.md를 업데이트합니다.

### Phase 1 - 중간 발표 필수 (~ 2026년 5월)

| 단계 | 작업 | 상태 | 비고 |
|------|------|------|------|
| 1-1 | FastAPI 백엔드 기본 서버 | 완료 | |
| 1-2 | 영상 처리 (yt-dlp + OpenCV) | 완료 | |
| 1-3 | 얼굴 감정 분석 (MediaPipe) | 완료 | |
| 1-4 | 음성 감정 분석 (Whisper + librosa) | 완료 | |
| 1-5 | Gemini AI 코치 연동 | 완료 | |
| 1-6 | React 웹 대시보드 | 완료 | 감정 타임라인 + AI 코치 UI |
| 1-7 | 백엔드 CORS 설정 | 완료 | main.py에 이미 설정됨 |
| 1-8 | Flutter 앱 기본 화면 | 완료 | 감정 분석 + AI 코치 동작 확인 |

### Phase 2 - 중간~최종 발표 (2026년 5월~9월)

| 단계 | 작업 | 상태 | 비고 |
|------|------|------|------|
| 2-1 | scene_analyzer.py | 미완료 [다음 작업] | YOLOv8 + CLIP 장면 분석 |
| 2-2 | fusion_engine.py | 미완료 | 얼굴+음성+장면 멀티모달 융합 |
| 2-3 | viral_predictor.py | 미완료 | 바이럴 점수 ML 예측 모델 |
| 2-4 | YouTube Data API 연동 | 미완료 | 실제 조회수 데이터 연동 |
| 2-5 | 감정 트렌드 API | 미완료 | /api/trend 구현 + DB 저장 |
| 2-6 | PostgreSQL DB 연동 | 미완료 | 분석 결과 영구 저장 |
| 2-7 | React 대시보드 고도화 | 미완료 | 바이럴 점수, 트렌드 차트 추가 |
| 2-8 | Flutter 앱 고도화 | 미완료 | 바이럴 점수 표시, UX 개선 |

### Phase 3 - 최종 발표 준비 (2026년 8월~9월)

| 단계 | 작업 | 상태 | 비고 |
|------|------|------|------|
| 3-1 | 캐릭터 PNG 교체 | 미완료 | AI 이미지로 고퀄리티 캐릭터 제작 |
| 3-2 | 캐릭터 4종 추가 | 미완료 | 백호/강아지/고양이/판다 랜덤 등장 |
| 3-3 | Docker 컨테이너화 | 미완료 | 백엔드 + 프론트엔드 |
| 3-4 | AWS EC2 배포 | 미완료 | 실제 서버 배포 |
| 3-5 | Flutter 앱 완성 | 미완료 | 전체 기능 탑재 + 캐릭터 완성 |
| 3-6 | 발표 자료 준비 | 미완료 | 데모 시나리오 포함 |

---

### 다음 작업: 2-1 scene_analyzer.py

**작업 내용:**
- YOLOv8으로 영상 내 사람/동물/객체 감지
- CLIP으로 장면 분위기 임베딩
- 결과를 /api/analyze 응답에 scene_summary 추가

**작업 시작 전 Claude가 먼저 확인할 것:**
```
type C:\dev\vibeview\server\services\video_processor.py
type C:\dev\vibeview\server\routers\analyze.py
```

---

## 작업 현황 체크리스트

- [x] 개발 환경 세팅
- [x] GitHub 저장소 연결
- [x] FastAPI 기본 서버
- [x] Gemini API 연동
- [x] 영상 처리 파이프라인 (yt-dlp + OpenCV + ffmpeg)
- [x] 얼굴 감정 분석 (MediaPipe FaceMesh)
- [x] 음성 감정 분석 (Whisper base + librosa)
- [x] /api/analyze 완성 및 동작 확인
- [x] /api/coach 완성 및 동작 확인
- [x] React 웹 대시보드 완성 (감정 타임라인, AI 코치)
- [x] .gitignore 설정
- [x] 백엔드 CORS 설정 (main.py에 이미 설정됨)
- [x] Flutter 앱 기본 화면 완성 (감정 분석 + AI 코치 동작 확인)
- [ ] scene_analyzer.py (YOLOv8 + CLIP)  <-- 현재 여기
- [ ] fusion_engine.py (멀티모달 융합)
- [ ] viral_predictor.py (바이럴 점수 예측)
- [ ] YouTube Data API 연동
- [ ] 감정 트렌드 API (/api/trend)
- [ ] PostgreSQL DB 연동
- [ ] React 대시보드 고도화
- [ ] Flutter 앱 고도화
- [ ] 캐릭터 PNG 교체 (AI 이미지 제작 후)
- [ ] 캐릭터 4종 랜덤 등장 기능
- [ ] Docker + AWS 배포
- [ ] 발표 자료 준비

---

## 새 채팅창 사용법

이 파일을 업로드한 후:
```
이 파일은 내가 개발 중인 VibeView 졸업작품이야.
로드맵 순서대로 이어서 개발해줘.
코드 작성 전에 필요한 파일이 있으면 먼저 요청해줘.
새 채팅창도 컨텍스트가 넘어가기 전에 이 CONTEXT.md를 업데이트해서 줘.
```

---

## 주의사항

- 코드 전달 전 반드시 정확성 검토 후 전달
- 새 API 연동 전 반드시 라우터 파일 내용 확인 요청할 것
- 작업 시작 전 필요한 파일을 먼저 요청할 것 (나중에 확인이 필요했다고 말하지 않는다)
- Gemini 모델명: gemini-2.5-flash (다른 버전 사용 금지)
- pip 대신 항상 pip install 사용 (Python 3.11 경로: C:\Python311)
- 서버는 uvicorn main:app --reload --port 8000 으로 실행
- Flutter 에뮬레이터 API 주소: http://10.0.2.2:8000 (localhost 아님)
- yt-dlp Python API js_runtimes: {"node": {}} 딕셔너리 형식 (검증 완료)
- yt-dlp Python API remote_components: {"ejs:github"} set 형식 (검증 완료)
- yt-dlp format: "best[height<=720]/best" 사용 (복잡한 포맷 조건 사용 금지)
- cookies.txt는 절대 외부에 공유하지 말 것
- 새 채팅창에서도 컨텍스트 초과 전에 반드시 CONTEXT.md 업데이트 버전 제공
- Flutter Dart 파일 작성 시: CustomPainter 내부에서 전역 k* 상수 직접 사용 불가 (static const 별칭 필요)
- Flutter Dart 파일 작성 시: const 위젯 안에 runtime 상수(kText 등) 포함 시 const 제거 필요
