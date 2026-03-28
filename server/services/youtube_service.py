# C:\dev\vibeview\server\services\youtube_service.py

from __future__ import annotations

import os
import re
import logging
from datetime import datetime, timezone
from typing import Optional

import requests
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

_API_KEY = os.getenv("YOUTUBE_API_KEY")
_BASE_URL = "https://www.googleapis.com/youtube/v3/videos"


class YouTubeService:
    """
    YouTube Data API v3 기반 영상 통계 조회 서비스.
    조회수, 좋아요, 댓글 수, 제목, 채널명, 게시일,
    썸네일, 태그, 조회수 속도를 반환합니다.
    """

    def get_stats(self, url: str) -> dict:
        """
        YouTube URL에서 영상 통계를 가져옵니다.

        Parameters
        ----------
        url : str
            YouTube 영상 URL (Shorts, 일반 영상 모두 지원)

        Returns
        -------
        dict:
            video_id       : str
            title          : str
            channel        : str
            published_at   : str   (ISO 8601)
            view_count     : int
            like_count     : int
            comment_count  : int
            thumbnail_url  : str
            tags           : list[str]
            views_per_day  : float  (하루 평균 조회수)
            days_since_upload : int (업로드 후 경과 일수)
        """
        if not _API_KEY:
            raise RuntimeError(
                "YOUTUBE_API_KEY가 .env에 설정되지 않았습니다."
            )

        video_id = self._extract_video_id(url)
        if not video_id:
            raise RuntimeError(
                "YouTube 영상 ID를 URL에서 추출할 수 없습니다. URL을 확인해주세요."
            )

        params = {
            "key": _API_KEY,
            "id": video_id,
            "part": "snippet,statistics",
        }

        try:
            response = requests.get(_BASE_URL, params=params, timeout=10)
            response.raise_for_status()
        except requests.exceptions.Timeout:
            raise RuntimeError("YouTube API 요청 시간이 초과됐습니다.")
        except requests.exceptions.RequestException as e:
            raise RuntimeError(f"YouTube API 요청 실패: {e}")

        data = response.json()

        items = data.get("items", [])
        if not items:
            raise RuntimeError(
                "YouTube API에서 영상 정보를 찾을 수 없습니다. "
                "비공개 영상이거나 삭제된 영상일 수 있습니다."
            )

        item = items[0]
        snippet    = item.get("snippet", {})
        statistics = item.get("statistics", {})

        # 기본 정보
        title       = snippet.get("title", "")
        channel     = snippet.get("channelTitle", "")
        published_at = snippet.get("publishedAt", "")
        thumbnail_url = (
            snippet.get("thumbnails", {})
            .get("high", {})
            .get("url", "")
            or snippet.get("thumbnails", {})
            .get("default", {})
            .get("url", "")
        )
        tags = snippet.get("tags", [])

        # 통계
        view_count    = int(statistics.get("viewCount", 0))
        like_count    = int(statistics.get("likeCount", 0))
        comment_count = int(statistics.get("commentCount", 0))

        # 업로드 후 경과 일수 + 하루 평균 조회수
        days_since_upload, views_per_day = self._calc_velocity(
            published_at, view_count
        )

        return {
            "video_id":          video_id,
            "title":             title,
            "channel":           channel,
            "published_at":      published_at,
            "view_count":        view_count,
            "like_count":        like_count,
            "comment_count":     comment_count,
            "thumbnail_url":     thumbnail_url,
            "tags":              tags,
            "views_per_day":     views_per_day,
            "days_since_upload": days_since_upload,
        }

    # ── 내부 헬퍼 ──────────────────────────────────────────────────

    @staticmethod
    def _extract_video_id(url: str) -> Optional[str]:
        """
        다양한 YouTube URL 형식에서 영상 ID를 추출합니다.

        지원 형식:
        - https://www.youtube.com/watch?v=VIDEO_ID
        - https://youtu.be/VIDEO_ID
        - https://www.youtube.com/shorts/VIDEO_ID
        - https://m.youtube.com/watch?v=VIDEO_ID
        """
        patterns = [
            r"(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/shorts/)([a-zA-Z0-9_-]{11})",
            r"[?&]v=([a-zA-Z0-9_-]{11})",
        ]
        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                return match.group(1)
        return None

    @staticmethod
    def _calc_velocity(published_at: str, view_count: int) -> tuple[int, float]:
        """
        업로드 후 경과 일수와 하루 평균 조회수를 계산합니다.

        Returns
        -------
        (days_since_upload, views_per_day)
        """
        if not published_at:
            return 0, 0.0

        try:
            upload_time = datetime.fromisoformat(
                published_at.replace("Z", "+00:00")
            )
            now = datetime.now(timezone.utc)
            days = max(1, (now - upload_time).days)
            views_per_day = round(view_count / days, 1)
            return days, views_per_day
        except Exception:
            return 0, 0.0
