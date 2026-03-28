# VibeView - 프로젝트 컨텍스트

> 이 파일은 새 채팅창에서 Claude에게 업로드하여 프로젝트를 이어서 개발할 때 사용합니다.
> 새 채팅창에서 이 파일을 업로드한 후 아래처럼 말하세요:
> "이 파일은 내가 개발 중인 VibeView 졸업작품이야. 로드맵 순서대로 이어서 개발해줘.
>  코드 작성 전에 필요한 파일이 있으면 먼저 요청해줘."

---

## ⚠️ Claude AI 필수 행동 지침 (반드시 준수)

---

### 🔴 CONTEXT.md 생성 및 전달 규칙 (최우선)

**CONTEXT.md를 생성하는 경우는 딱 두 가지뿐이다:**
1. 사용자가 직접 요청했을 때
2. 컨텍스트 한계에 도달했을 때

**🔴 CONTEXT.md를 사용자에게 전달하기 전, 아래 항목을 반드시 스스로 검증한다:**

> ✅ 전달 전 체크리스트
> - [ ] 완료된 단계가 모두 "완료"로 표시되어 있는가?
> - [ ] 미완료 단계 중 [다음 작업] 표시가 정확한 위치에 있는가?
> - [ ] 폴더 구조의 파일 상태(완료/미구현)가 최신 상태인가?
> - [ ] API 응답 구조가 현재 구현된 코드와 일치하는가?
> - [ ] 주의사항에 이번 작업에서 새로 확인된 내용이 반영되어 있는가?
> - [ ] 파일 내용이 중간에 잘리거나 누락된 부분이 없는가?

**위 체크리스트를 모두 확인한 후에만 사용자에게 전달한다. 확인 전에는 절대 전달하지 않는다.**

---

### 🔴 컨텍스트 한계 도달 시 행동 규칙 (최우선)

**대화가 길어져서 더 이상 진행하기 어렵다고 판단되면:**

1. **즉시 작업을 멈춘다**
2. **위의 체크리스트를 모두 검증한 후 CONTEXT.md를 최신 상태로 업데이트해서 전달한다**
3. **아래 메시지를 사용자에게 반드시 전달한다:**

> 🚨 **채팅창 컨텍스트가 한계에 가까워졌습니다.**
> 지금까지의 진행 상황을 반영한 CONTEXT.md를 업데이트했습니다.
> **새 채팅창을 열고 이 CONTEXT.md 파일을 업로드한 후 계속 진행해주세요.**

---

### 일반 행동 규칙

1. **코드 전달 전 반드시 검토**: 로직, 문법, 의존성을 스스로 검토하고 문제가 없는 경우에만 전달한다.
2. **불확실한 정보는 검색 후 전달**: API 옵션명, 라이브러리 버전, 설정값 등 확신이 없는 정보는 반드시 웹 검색으로 확인 후 전달한다.
3. **틀린 정보를 전달했을 경우 즉시 인정**: 이전에 잘못된 정보를 전달했다면 즉시 인정하고 정확한 정보로 교체한다.
4. **추측으로 코드를 작성하지 않는다**: 동작 여부가 불확실한 코드는 "확인이 필요합니다"라고 먼저 말하고 검증 방법을 제시한다.
5. **파일 전달 시 전체 코드 제공**: 일부만 수정할 때는 변경된 부분을 명확히 표시하고, 전체 파일이 필요한 경우 전체를 제공한다.
6. **백엔드 코드 확인 요청**: 프론트엔드에서 백엔드 API를 호출하는 코드를 작성하기 전에, 반드시 해당 라우터 파일의 실제 내용을 확인한 후 작성한다.
7. **Pydantic 스키마 확인 후 요청 형식 결정**: API 요청/응답 형식은 반드시 실제 Pydantic 모델을 확인한 후 맞춰서 작성한다.
8. **로드맵 순서 준수**: 아래 개발 로드맵 순서대로 진행한다. 새 채팅창이 시작되면 현재 완료된 단계를 확인하고 다음 단계를 안내한다.
9. **작업 전 필요한 정보를 먼저 요청한다**: 작업을 시작하기 전에 필요한 파일, 현재 코드 상태, 설정값 등을 사전에 파악하고 사용자에게 먼저 요청한다.
10. **정보와 코드는 정확하고 완벽한지 반드시 재확인 후 전달한다**: 전달 전 스스로 한 번 더 검토하고, 각 단계를 하나하나 자세히 설명하여 사용자가 따라할 수 있게 한다.
11. **안내 메시지와 실행 코드를 절대 혼재하지 않는다**: 실행할 코드만 코드 블록에 넣고, 설명은 코드 블록 밖에 작성한다.
12. **Flutter 파일 수정 시 반드시 오류 검증**: (1) CustomPainter 내부 전역 k* 상수 직접 사용 여부 (2) Color를 Paint 자리에 직접 전달 여부 (3) 없는 변수 사용 여부 (4) const 위젯 안에 non-const 표현식 사용 여부 (5) 브라켓/괄호 쌍 일치 여부

---

## 코드 정확성을 위해 Claude가 요청할 사항

| 상황 | Claude가 요청할 파일 | 명령어 |
|------|------|------|
| 새 API 연동 시 | 해당 라우터 파일 | `type C:\dev\vibeview\server\routers\파일명.py` |
| 서비스 로직 수정 시 | 해당 서비스 파일 | `type C:\dev\vibeview\server\services\파일명.py` |
| CORS / 미들웨어 수정 시 | main.py 전체 | `type C:\dev\vibeview\server\main.py` |
| Flutter 앱 수정 시 | pubspec.yaml | `type C:\dev\vibeview\mobile\pubspec.yaml` |
| React 수정 시 | App.js, App.css, index.css, package.json | `type C:\dev\vibeview\web\src\파일명` |
| 오류 발생 시 | 백엔드 터미널 에러 로그 | uvicorn 실행 터미널 스크린샷 |
| Flutter 오류 시 | 터미널 전체 오류 | flutter run 터미널 스크린샷 |
| React 오류 시 | 브라우저 콘솔 에러 | F12 → Console 탭 스크린샷 |

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
| **중간 발표** | 2026년 5월 |
| **최종 발표** | 2026년 9월 |

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
| Android 에뮬레이터 | Medium_Phone (API 34, Android 14) ← 기본 사용 |
| Android 에뮬레이터 (구) | Medium_Phone_API_36.1 (API 36, 키보드 버그로 사용 중단) |
| PostgreSQL | 16.13 (포트 5432, DB명: vibeview, 사용자: postgres) |

---

## 기술 스택

| 분류 | 기술 | 용도 |
|------|------|------|
| **모바일** | Flutter (Dart) | iOS/Android 크로스플랫폼 |
| **웹 프론트엔드** | React + Recharts | 대시보드 시각화 |
| **백엔드** | Python, FastAPI | REST API 서버 |
| **AI 코치** | Gemini API (gemini-2.5-flash) | 감정 해석 + 피드백 |
| **얼굴 분석** | MediaPipe FaceMesh | 표정 분석 |
| **객체 감지** | YOLOv8 | 사람/동물 분류 |
| **음성 분석** | Whisper (base) + librosa | STT + 감정 분석 |
| **영상 분위기** | CLIP (ViT-B/32) | 장면 임베딩 |
| **영상 처리** | OpenCV + ffmpeg + yt-dlp | 프레임 추출 + 음성 분리 |
| **데이터** | YouTube Data API v3 | 조회수 연동 |
| **DB** | PostgreSQL 16 + SQLAlchemy | 분석 결과 영구 저장 |
| **배포** | Docker + AWS EC2 | 컨테이너 배포 |

---

## 중요 설정

### API 키 (.env 파일 위치: C:\dev\vibeview\server\.env)
```
GEMINI_API_KEY=발급받은키
GOOGLE_API_KEY=발급받은키
YOUTUBE_API_KEY=발급받은키
DATABASE_URL=postgresql://postgres:비밀번호@localhost:5432/vibeview
```
- .env 파일 내용을 절대 대화창에 붙여넣지 말 것 (보안)
- Gemini 모델명: gemini-2.5-flash (다른 버전 사용 금지)

### 서버 실행 방법
```
터미널 1 - 백엔드:
cd C:\dev\vibeview\server
uvicorn main:app --reload --port 8000

터미널 2 - 프론트엔드 (웹):
cd C:\dev\vibeview\web
npm start

터미널 3 - Flutter 앱:
flutter emulators --launch Medium_Phone
cd C:\dev\vibeview\mobile
flutter run
```

### 기타 설정
- API 문서: http://localhost:8000/docs
- Flutter 에뮬레이터 API 주소: http://10.0.2.2:8000 (localhost 아님)
- yt-dlp js_runtimes: `{"node": {}}` 딕셔너리 형식 (검증 완료)
- yt-dlp remote_components: `{"ejs:github"}` set 형식 (검증 완료)
- yt-dlp format: `"best[height<=720]/best"` 사용
- cookies.txt 위치: C:\dev\vibeview\server\cookies.txt (절대 공유 금지)
- pip 설치 시 항상: `C:\Python311\python.exe -m pip install 패키지명`
- PostgreSQL PATH 설정 완료: C:\Program Files\PostgreSQL\16\bin
- PostgreSQL Temp 폴더: C:\Temp (한글 경로 문제로 변경됨)
- Gradle 경로: C:\Users\이성준\.gradle\wrapper\dists\gradle-8.14-all\c2qonpi39x1mddn7hk5gh9iqj\
- adb 경로: C:\dev\android-sdk\platform-tools\adb.exe
- API 36 에뮬레이터는 hide(ime()) 키보드 버그로 사용 중단, API 34로 교체

---

## 폴더 구조

```
C:\dev\vibeview\
├── server\
│   ├── main.py                    완료 (CORS + DB 테이블 자동 생성)
│   ├── database.py                완료 (SQLAlchemy DB 연결)
│   ├── models.py                  완료 (AnalysisResult 테이블 정의)
│   ├── requirements.txt           완료
│   ├── cookies.txt                완료 (공유 금지)
│   ├── .env                       완료 (API 키 + DB URL 설정됨)
│   ├── routers\
│   │   ├── __init__.py            완료
│   │   ├── analyze.py             완료 (전체 파이프라인 + DB 저장)
│   │   ├── coach.py               완료
│   │   ├── trend.py               완료 (/api/trend 구현)
│   │   └── user.py                완료 (기본 구조)
│   └── services\
│       ├── gemini_coach.py        완료
│       ├── video_processor.py     완료
│       ├── face_analyzer.py       완료
│       ├── audio_analyzer.py      완료
│       ├── scene_analyzer.py      완료 (YOLOv8 + CLIP)
│       ├── fusion_engine.py       완료 (멀티모달 융합)
│       ├── viral_predictor.py     완료 (바이럴 점수 예측)
│       └── youtube_service.py     완료 (YouTube Data API v3)
├── web\                           완료 (React 대시보드 고도화 완료)
│   └── src\
│       ├── App.js                 완료 (YouTube통계+장면+융합+바이럴+트렌드탭)
│       ├── App.css                완료
│       └── index.css              완료
├── mobile\                        완료 (Flutter 앱 고도화 완료)
│   ├── lib\
│   │   └── main.dart              완료 (YouTube통계+장면+융합+바이럴+트렌드화면)
│   └── pubspec.yaml               완료 (http 패키지 포함)
├── README.md                      완료
└── CONTEXT.md                     이 파일
```

---

## API 엔드포인트 현황

| 메서드 | 경로 | 상태 | 설명 |
|--------|------|------|------|
| POST | /api/analyze | 완료 | 영상 분석 전체 파이프라인 + DB 저장 |
| POST | /api/coach | 완료 | Gemini AI 코치 피드백 |
| GET | /api/trend | 완료 | 감정 트렌드 (DB 기반) |
| GET | /api/user | 기본 구조 | 사용자 정보 (미구현) |

### /api/analyze 응답 구조 (현재 최신)
```json
{
  "status": "success",
  "video_info": {"duration": float, "fps": float, "width": int, "height": int, "total_frames": int},
  "youtube_stats": {
    "video_id": str, "title": str, "channel": str, "published_at": str,
    "view_count": int, "like_count": int, "comment_count": int,
    "thumbnail_url": str, "tags": list, "views_per_day": float, "days_since_upload": int
  },
  "face_summary": {
    "emotion_distribution": {"happy": float, ...},
    "avg_valence": float,
    "peak_emotion": {"timestamp": float, "emotion": str, "valence": float}
  },
  "audio_summary": {
    "avg_valence": float, "dominant_emotion": str,
    "tempo": float, "language": str, "full_text": str
  },
  "scene_summary": {
    "dominant_vibe": str,
    "vibe_distribution": {"활기찬": float, ...},
    "object_stats": {"person_ratio": float, "animal_ratio": float, "avg_person_count": float},
    "content_type": str
  },
  "fusion_result": {
    "fused_valence": float, "fused_emotion": str, "confidence": float,
    "modality_scores": {"face": float, "audio": float, "scene": float},
    "highlight_moments": [{"timestamp": float, "intensity": float, "reason": str}],
    "vibe_tags": [str], "engagement_hint": float
  },
  "viral_result": {
    "viral_score": float, "grade": str,
    "factors": {"emotional_intensity": float, "emotional_consistency": float,
                "content_appeal": float, "pacing": float, "highlight_density": float},
    "strong_points": [str], "weak_points": [str], "recommendation": str
  },
  "emotion_timeline": [
    {"timestamp": float, "face_emotion": str, "face_valence": float,
     "face_count": int, "audio_emotion": str, "audio_valence": float, "audio_energy": float}
  ]
}
```

### /api/trend 응답 구조
```json
{
  "status": "success",
  "total_analyzed": int,
  "avg_viral_score": float,
  "avg_valence": float,
  "grade_distribution": {"S": float, "A": float, ...},
  "emotion_distribution": {"약간 긍정적": float, ...},
  "vibe_trend": {"활기찬": float, ...},
  "content_distribution": {"person": float, ...},
  "top_viral": [{"title": str, "channel": str, "thumbnail_url": str,
                 "viral_score": float, "grade": str, "view_count": int,
                 "fused_emotion": str, "analyzed_at": str}],
  "recent_videos": [...]
}
```

### /api/coach 요청
```json
{
  "video_id": "string",
  "emotion_data": {"face_summary": {}, "audio_summary": {}, "video_info": {}},
  "question": "string (optional)"
}
```

---

## DB 테이블 구조 (AnalysisResult)

| 컬럼 | 타입 | 내용 |
|------|------|------|
| id | Integer PK | 자동 증가 |
| video_url | String | 분석한 영상 URL |
| video_id | String | YouTube 영상 ID |
| title | String | 영상 제목 |
| channel | String | 채널명 |
| thumbnail_url | String | 썸네일 URL |
| duration | Float | 영상 길이(초) |
| view_count | Integer | 조회수 |
| like_count | Integer | 좋아요 수 |
| comment_count | Integer | 댓글 수 |
| views_per_day | Float | 하루 평균 조회수 |
| fused_emotion | String | 종합 감정 |
| fused_valence | Float | 종합 감정 극성 |
| viral_score | Float | 바이럴 점수 |
| grade | String | 등급 (S/A/B/C/D) |
| dominant_vibe | String | 대표 분위기 |
| content_type | String | 콘텐츠 유형 |
| face_summary | JSON | 얼굴 분석 전체 |
| audio_summary | JSON | 음성 분석 전체 |
| scene_summary | JSON | 장면 분석 전체 |
| fusion_result | JSON | 융합 결과 전체 |
| viral_result | JSON | 바이럴 예측 전체 |
| youtube_stats | JSON | YouTube 통계 전체 |
| emotion_timeline | JSON | 감정 타임라인 전체 |
| created_at | DateTime | 분석 일시 |

---

## Flutter 앱 현황

### 구현된 기능
- URL 입력 화면 (홈) + 트렌드 버튼
- 백엔드 /api/analyze 호출 (타임아웃 5분)
- 결과 화면: YouTube 통계 카드 (썸네일/제목/채널/조회수/좋아요/댓글/하루평균/태그)
- 결과 화면: 비디오 정보, 얼굴 감정 바, 음성 감정, 타임라인 바 차트
- 결과 화면: 장면 분석 카드 (dominant_vibe, vibe 분포, 인물 비율)
- 결과 화면: 멀티모달 융합 카드 (fused_emotion, confidence, modality_scores, vibe_tags)
- 결과 화면: 바이럴 예측 카드 (등급 뱃지, viral_score, 팩터 바, 강점/약점, 추천)
- Gemini AI 코치 버튼 (/api/coach 연동)
- 트렌드 화면 (/api/trend 연동, 등급분포/감정분포/상위영상/최근기록)
- SD 수인 캐릭터 (CustomPainter, 사람 기반 백호)
- 감정별 표정 5종: idle, thinking, happy, sad, surprised, angry
- 둥실둥실 float 애니메이션 + thinking 시 빙글빙글 회전

### Flutter 패키지
```yaml
dependencies:
  flutter: sdk
  http: ^1.6.0
```

### 에뮬레이터 주의사항
- API 36 (Medium_Phone_API_36.1): hide(ime()) 키보드 버그 → 사용 중단
- API 34 (Medium_Phone): 정상 동작 → 기본 사용
- 실행: `flutter emulators --launch Medium_Phone`

### 캐릭터 향후 계획
- Phase 3에서 AI 이미지로 고퀄리티 PNG 교체
- 캐릭터 4종 (백호/강아지/고양이/판다) 랜덤 등장
- Image.asset()으로 교체 예정

---

## React 웹 현황

### 구현된 화면
- 분석 탭: YouTube통계, 비디오정보, 얼굴감정, 음성감정, 장면분석, 융합결과, 바이럴점수, 타임라인, AI코치
- 트렌드 탭: 요약통계, 등급분포, 감정분포, 상위영상, 최근기록

---

## 개발 로드맵

### Phase 1 - 중간 발표 필수 (~ 2026년 5월)

| 단계 | 작업 | 상태 |
|------|------|------|
| 1-1 | FastAPI 백엔드 기본 서버 | 완료 |
| 1-2 | 영상 처리 (yt-dlp + OpenCV) | 완료 |
| 1-3 | 얼굴 감정 분석 (MediaPipe) | 완료 |
| 1-4 | 음성 감정 분석 (Whisper + librosa) | 완료 |
| 1-5 | Gemini AI 코치 연동 | 완료 |
| 1-6 | React 웹 대시보드 기본 | 완료 |
| 1-7 | 백엔드 CORS 설정 | 완료 |
| 1-8 | Flutter 앱 기본 화면 | 완료 |

### Phase 2 - 중간~최종 발표 (2026년 5월~9월)

| 단계 | 작업 | 상태 |
|------|------|------|
| 2-1 | scene_analyzer.py | 완료 |
| 2-2 | fusion_engine.py | 완료 |
| 2-3 | viral_predictor.py | 완료 |
| 2-4 | YouTube Data API 연동 | 완료 |
| 2-5 | 감정 트렌드 API (/api/trend) | 완료 |
| 2-6 | PostgreSQL DB 연동 | 완료 |
| 2-7 | React 대시보드 고도화 | 완료 |
| 2-8 | Flutter 앱 고도화 | 완료 |

### Phase 3 - 최종 발표 준비 (2026년 8월~9월)

| 단계 | 작업 | 상태 |
|------|------|------|
| 3-1 | 캐릭터 PNG 교체 | 미완료 [다음 작업] |
| 3-2 | 캐릭터 4종 추가 | 미완료 |
| 3-3 | Docker 컨테이너화 | 미완료 |
| 3-4 | AWS EC2 배포 | 미완료 |
| 3-5 | Flutter 앱 완성 | 미완료 |
| 3-6 | 발표 자료 준비 | 미완료 |

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
- [x] React 웹 대시보드 기본 완성
- [x] .gitignore 설정
- [x] 백엔드 CORS 설정
- [x] Flutter 앱 기본 화면 완성
- [x] scene_analyzer.py (YOLOv8 + CLIP)
- [x] fusion_engine.py (멀티모달 융합)
- [x] viral_predictor.py (바이럴 점수 예측)
- [x] YouTube Data API 연동
- [x] 감정 트렌드 API (/api/trend)
- [x] PostgreSQL DB 연동 (분석 결과 자동 저장)
- [x] React 대시보드 고도화
- [x] Flutter 앱 고도화
- [ ] 캐릭터 PNG 교체  <-- 현재 여기
- [ ] 캐릭터 4종 랜덤 등장
- [ ] Docker + AWS 배포
- [ ] 발표 자료 준비

---

## 주의사항

- 안내 메시지와 실행 코드를 절대 혼재하지 말 것 (사용자 혼동 방지)
- 실행할 코드만 코드 블록에 넣고, 설명은 코드 블록 밖에 작성할 것
- .env 파일 내용을 대화창에 붙여넣지 말 것 (보안)
- API 키는 사용자가 직접 .env에 입력하도록 안내할 것
- Gemini 모델명: gemini-2.5-flash (다른 버전 사용 금지)
- pip 설치: `C:\Python311\python.exe -m pip install 패키지명`
- 서버 실행: `uvicorn main:app --reload --port 8000`
- Flutter 에뮬레이터: Medium_Phone (API 34) 사용
- Flutter 에뮬레이터 실행: `flutter emulators --launch Medium_Phone`
- Flutter 에뮬레이터 API: http://10.0.2.2:8000
- API 36 에뮬레이터(Medium_Phone_API_36.1)는 hide(ime()) 버그로 사용 불가
- adb 경로: C:\dev\android-sdk\platform-tools\adb.exe
- CONTEXT.md 전달 전 반드시 체크리스트 6개 항목 모두 검증 후 전달
- Flutter: CustomPainter 내부 전역 k* 상수 직접 사용 불가 (static const 별칭 필요)
- Flutter: const 위젯 안에 runtime 상수 포함 시 const 제거 필요
