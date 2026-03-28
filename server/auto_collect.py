# C:\dev\vibeview\server\auto_collect.py
#
# YouTube 인기 Shorts 자동 수집 + 분석 스크립트
#
# 사용법:
#   cd C:\dev\vibeview\server
#   C:\Python311\python.exe auto_collect.py --count 20
#   C:\Python311\python.exe auto_collect.py --count 50 --region KR
#
# 옵션:
#   --count   : 수집할 영상 수 (기본 20, 최대 50)
#   --region  : 지역 코드 (기본 KR, US/JP 등 가능)
#   --delay   : 영상 간 대기 시간 초 (기본 5)

import os
import sys
import time
import argparse
import requests
import logging
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%H:%M:%S',
)
logger = logging.getLogger(__name__)

_YOUTUBE_API_KEY = os.getenv("YOUTUBE_API_KEY")
_API_BASE        = "http://localhost:8000"
_YT_SEARCH_URL   = "https://www.googleapis.com/youtube/v3/search"
_YT_VIDEO_URL    = "https://www.googleapis.com/youtube/v3/videos"


def fetch_popular_shorts(count: int = 20, region: str = "KR") -> list[str]:
    """
    YouTube Data API로 인기 Shorts URL 목록을 가져옵니다.

    Returns:
        YouTube Shorts URL 리스트
    """
    if not _YOUTUBE_API_KEY:
        raise RuntimeError("YOUTUBE_API_KEY가 .env에 없습니다.")

    urls = []
    next_page_token = None

    logger.info(f"YouTube 인기 Shorts 검색 중... (지역: {region}, 목표: {count}개)")

    while len(urls) < count:
        params = {
            "key":             _YOUTUBE_API_KEY,
            "part":            "id",
            "type":            "video",
            "videoDuration":   "short",       # 60초 이하
            "order":           "viewCount",   # 조회수 순
            "regionCode":      region,
            "relevanceLanguage": "ko" if region == "KR" else "en",
            "maxResults":      min(50, count - len(urls)),
            "q":               "shorts",
        }
        if next_page_token:
            params["pageToken"] = next_page_token

        try:
            res = requests.get(_YT_SEARCH_URL, params=params, timeout=10)
            res.raise_for_status()
            data = res.json()
        except Exception as e:
            logger.error(f"YouTube 검색 API 오류: {e}")
            break

        items = data.get("items", [])
        if not items:
            break

        for item in items:
            video_id = item.get("id", {}).get("videoId")
            if video_id:
                urls.append(f"https://www.youtube.com/shorts/{video_id}")

        next_page_token = data.get("nextPageToken")
        if not next_page_token:
            break

    logger.info(f"총 {len(urls)}개 Shorts URL 수집 완료")
    return urls[:count]


def is_already_analyzed(url: str) -> bool:
    """
    이미 분석된 영상인지 DB에서 확인합니다.
    /api/trend 응답의 recent_videos에서 URL 비교
    """
    try:
        res = requests.get(f"{_API_BASE}/api/trend", timeout=5)
        if res.status_code == 200:
            data = res.json()
            recent = data.get("recent_videos", [])
            # video_id 추출해서 비교
            video_id = url.split("/")[-1].split("?")[0]
            for v in recent:
                if v.get("video_id") == video_id:
                    return True
    except Exception:
        pass
    return False


def analyze_video(url: str, timeout: int = 300) -> dict | None:
    """
    백엔드 /api/analyze를 호출하여 영상을 분석합니다.

    Returns:
        분석 결과 dict or None (실패 시)
    """
    try:
        res = requests.post(
            f"{_API_BASE}/api/analyze",
            json={"url": url},
            timeout=timeout,
        )
        if res.status_code == 200:
            return res.json()
        else:
            error = res.json().get("detail", "알 수 없는 오류")
            logger.warning(f"  분석 실패 ({res.status_code}): {error}")
            return None
    except requests.exceptions.Timeout:
        logger.warning(f"  분석 타임아웃 ({timeout}초 초과)")
        return None
    except Exception as e:
        logger.warning(f"  분석 오류: {e}")
        return None


def print_result(result: dict, idx: int, total: int) -> None:
    """분석 결과 요약 출력"""
    yt    = result.get("youtube_stats", {})
    viral = result.get("viral_result", {})
    title = yt.get("title", "제목 없음")[:40]
    grade = viral.get("grade", "-")
    score = viral.get("viral_score", 0)
    views = yt.get("view_count", 0)

    views_str = f"{views/1_000_000:.1f}M" if views >= 1_000_000 else f"{views/1_000:.1f}K"
    logger.info(f"  [{idx}/{total}] {title}")
    logger.info(f"  → 등급: {grade} | 점수: {score:.1f} | 조회수: {views_str}")


def main():
    parser = argparse.ArgumentParser(description="VibeView 자동 데이터 수집 스크립트")
    parser.add_argument("--count",  type=int, default=20,  help="수집할 영상 수 (기본 20)")
    parser.add_argument("--region", type=str, default="KR", help="지역 코드 (기본 KR)")
    parser.add_argument("--delay",  type=int, default=5,   help="영상 간 대기 시간 초 (기본 5)")
    args = parser.parse_args()

    count  = min(args.count, 50)  # 최대 50개
    region = args.region
    delay  = args.delay

    print("=" * 60)
    print("  VibeView 자동 데이터 수집 스크립트")
    print(f"  목표: {count}개 | 지역: {region} | 대기: {delay}초")
    print(f"  시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    # 1. 백엔드 서버 확인
    try:
        res = requests.get(f"{_API_BASE}/health", timeout=5)
        if res.status_code != 200:
            raise Exception()
        logger.info("✅ 백엔드 서버 연결 확인")
    except Exception:
        logger.error("❌ 백엔드 서버에 연결할 수 없습니다.")
        logger.error("   uvicorn main:app --reload --port 8000 을 먼저 실행하세요.")
        sys.exit(1)

    # 2. Shorts URL 수집
    try:
        urls = fetch_popular_shorts(count=count, region=region)
    except Exception as e:
        logger.error(f"❌ URL 수집 실패: {e}")
        sys.exit(1)

    if not urls:
        logger.error("❌ 수집된 URL이 없습니다.")
        sys.exit(1)

    # 3. 각 영상 분석
    success = 0
    skip    = 0
    fail    = 0

    for i, url in enumerate(urls, 1):
        print("-" * 60)
        logger.info(f"[{i}/{len(urls)}] {url}")

        # 이미 분석된 영상 스킵
        if is_already_analyzed(url):
            logger.info("  ⏭ 이미 분석된 영상 — 스킵")
            skip += 1
            continue

        # 분석 실행
        logger.info("  🔍 분석 중... (1~3분 소요)")
        result = analyze_video(url)

        if result and result.get("status") == "success":
            success += 1
            print_result(result, i, len(urls))
        else:
            fail += 1
            logger.warning("  ❌ 분석 실패")

        # 다음 영상 전 대기 (서버 부하 방지)
        if i < len(urls):
            logger.info(f"  ⏳ {delay}초 대기 중...")
            time.sleep(delay)

    # 4. 결과 요약
    print("=" * 60)
    print(f"  완료: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"  ✅ 성공: {success}개")
    print(f"  ⏭ 스킵: {skip}개 (이미 분석됨)")
    print(f"  ❌ 실패: {fail}개")
    print(f"  📊 DB 누적 데이터: {success + skip}개 이상")
    print("=" * 60)


if __name__ == "__main__":
    main()
