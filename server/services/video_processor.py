# C:\dev\vibeview\server\services\video_processor.py

import cv2
import subprocess
import tempfile
import shutil
from pathlib import Path
from typing import Optional
import yt_dlp

# cookies.txt 경로: server/cookies.txt
_COOKIES_PATH = Path(__file__).parent.parent / "cookies.txt"

# 프레임 영구 저장 폴더: server/static/frames/{video_id}/
_FRAMES_ROOT = Path(__file__).parent.parent / "static" / "frames"


class VideoProcessor:
    """
    YouTube/TikTok 영상 다운로드 및 전처리 모듈
    - yt-dlp: 영상 다운로드 (쿠키 + EJS node 런타임)
    - ffmpeg: 오디오 분리
    - OpenCV: 프레임 추출
    """

    def __init__(self, output_dir: Optional[str] = None, fps: int = 2):
        self.fps = fps
        self.output_dir = Path(output_dir) if output_dir else Path(tempfile.mkdtemp(prefix="vibeview_"))
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.video_id: Optional[str] = None  # 분석 후 설정됨

    # ------------------------------------------------------------------
    # 1. 영상 다운로드
    # ------------------------------------------------------------------
    def download_video(self, url: str) -> Path:
        video_path = self.output_dir / "video.mp4"

        ydl_opts = {
            "format": "best[height<=720]/best",
            "outtmpl": str(video_path),
            "quiet": True,
            "no_warnings": True,
            "merge_output_format": "mp4",
            "js_runtimes": {"node": {}},
            "remote_components": {"ejs:github"},
        }

        if _COOKIES_PATH.exists():
            ydl_opts["cookiefile"] = str(_COOKIES_PATH)

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=True)
                if info is None:
                    raise RuntimeError("영상 정보를 가져올 수 없습니다.")
                # video_id 저장 (YouTube의 경우)
                self.video_id = info.get("id") or info.get("display_id") or "unknown"
        except yt_dlp.utils.DownloadError as e:
            err = str(e)
            if "Please sign in" in err or "Sign in" in err:
                raise RuntimeError("로그인이 필요하거나 연령 제한이 있는 영상입니다.")
            elif "Private video" in err:
                raise RuntimeError("비공개 영상입니다. 공개 영상 URL을 입력해주세요.")
            elif "Video unavailable" in err:
                raise RuntimeError("영상을 찾을 수 없습니다. URL을 확인해주세요.")
            elif "not a valid URL" in err:
                raise RuntimeError("올바른 YouTube URL이 아닙니다.")
            elif "Requested format is not available" in err:
                raise RuntimeError("해당 영상의 포맷을 다운로드할 수 없습니다. 다른 영상을 시도해주세요.")
            else:
                raise RuntimeError(f"영상 다운로드 실패: {e}") from e

        actual_path = self._find_downloaded_file(video_path)
        return actual_path

    def _find_downloaded_file(self, expected_path: Path) -> Path:
        """yt-dlp가 실제로 저장한 파일을 찾아 mp4로 변환합니다."""
        if expected_path.exists():
            return expected_path

        for ext in ["webm", "mkv", "avi", "mov"]:
            candidate = expected_path.parent / f"video.mp4.{ext}"
            if not candidate.exists():
                candidate = expected_path.with_suffix(f".{ext}")
            if candidate.exists():
                cmd = [
                    "ffmpeg", "-y",
                    "-i", str(candidate),
                    "-c:v", "copy",
                    "-c:a", "aac",
                    str(expected_path),
                ]
                result = subprocess.run(cmd, capture_output=True, text=True)
                candidate.unlink(missing_ok=True)
                if result.returncode == 0:
                    return expected_path
                raise RuntimeError(f"mp4 변환 실패: {result.stderr}")

        raise RuntimeError("다운로드된 파일을 찾을 수 없습니다.")

    # ------------------------------------------------------------------
    # 2. 오디오 분리
    # ------------------------------------------------------------------
    def extract_audio(self, video_path: Path) -> Path:
        audio_path = self.output_dir / "audio.wav"

        cmd = [
            "ffmpeg", "-y",
            "-i", str(video_path),
            "-ac", "1",
            "-ar", "16000",
            "-vn",
            str(audio_path),
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(f"오디오 추출 실패: {result.stderr}")

        return audio_path

    # ------------------------------------------------------------------
    # 3. 프레임 추출 (영구 저장 폴더에 저장)
    # ------------------------------------------------------------------
    def extract_frames(self, video_path: Path) -> list[dict]:
        """
        프레임을 static/frames/{video_id}/ 폴더에 영구 저장합니다.
        분석 후에도 /frames/{video_id}/{파일명} 으로 접근 가능합니다.
        """
        video_id = self.video_id or "unknown"
        frames_dir = _FRAMES_ROOT / video_id
        frames_dir.mkdir(parents=True, exist_ok=True)

        cap = cv2.VideoCapture(str(video_path))
        if not cap.isOpened():
            raise RuntimeError(f"영상 파일을 열 수 없습니다: {video_path}")

        video_fps = cap.get(cv2.CAP_PROP_FPS)
        if video_fps <= 0:
            video_fps = 30.0

        interval = max(1, round(video_fps / self.fps))
        results = []
        frame_idx = 0

        while True:
            ret, frame = cap.read()
            if not ret:
                break
            if frame_idx % interval == 0:
                timestamp = frame_idx / video_fps
                filename = f"frame_{frame_idx:06d}.jpg"
                frame_path = frames_dir / filename
                cv2.imwrite(str(frame_path), frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
                results.append({
                    "timestamp": round(timestamp, 3),
                    "frame_path": frame_path,
                    # 클라이언트에서 접근할 URL 경로
                    "frame_url": f"/frames/{video_id}/{filename}",
                })
            frame_idx += 1

        cap.release()
        return results

    # ------------------------------------------------------------------
    # 4. 영상 기본 메타데이터
    # ------------------------------------------------------------------
    def get_video_info(self, video_path: Path) -> dict:
        cap = cv2.VideoCapture(str(video_path))
        if not cap.isOpened():
            raise RuntimeError(f"영상 파일을 열 수 없습니다: {video_path}")

        fps = cap.get(cv2.CAP_PROP_FPS)
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        duration = total_frames / fps if fps > 0 else 0.0

        cap.release()

        return {
            "duration": round(duration, 2),
            "fps": round(fps, 2),
            "width": width,
            "height": height,
            "total_frames": total_frames,
        }

    # ------------------------------------------------------------------
    # 5. 전체 파이프라인
    # ------------------------------------------------------------------
    def process(self, url: str) -> dict:
        video_path = self.download_video(url)
        audio_path = self.extract_audio(video_path)
        info = self.get_video_info(video_path)
        frames = self.extract_frames(video_path)

        return {
            "video_path": video_path,
            "audio_path": audio_path,
            "frames": frames,
            "info": info,
            "work_dir": self.output_dir,
            "video_id": self.video_id,
        }

    # ------------------------------------------------------------------
    # 6. 정리 (프레임은 유지, 임시 파일만 삭제)
    # ------------------------------------------------------------------
    def cleanup(self):
        """임시 작업 폴더(영상, 오디오)만 삭제합니다. 프레임은 static에 유지됩니다."""
        if self.output_dir.exists():
            shutil.rmtree(self.output_dir)
