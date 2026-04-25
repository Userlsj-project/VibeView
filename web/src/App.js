import React, { useState, useEffect } from 'react';
import axios from 'axios';
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid,
  Tooltip, Legend, ResponsiveContainer, ReferenceLine,
  RadialBarChart, RadialBar,
} from 'recharts';
import './index.css';
import './App.css';

const API_BASE = 'http://localhost:8000';

const EMOTION_COLORS = {
  happy:     '#00f5c4',
  sad:       '#4d9fff',
  angry:     '#ff4d6d',
  surprised: '#ffd166',
  neutral:   '#5a6a84',
  fearful:   '#a855f7',
  disgusted: '#84cc16',
};

const EMOTION_KO = {
  happy:     '행복',
  sad:       '슬픔',
  angry:     '분노',
  surprised: '놀람',
  neutral:   '중립',
  fearful:   '두려움',
  disgusted: '혐오',
  excited:   '흥분',
  anxious:   '불안',
  silence:   '무음',
  unknown:   '알 수 없음',
};

const GRADE_COLORS = {
  S: '#ffd166',
  A: '#00f5c4',
  B: '#7b61ff',
  C: '#4d9fff',
  D: '#ff4d6d',
};

// ─── 공통 컴포넌트 ────────────────────────────────────────

function EmotionBar({ emotion, value }) {
  const color = EMOTION_COLORS[emotion] || '#5a6a84';
  const pct   = Math.round((value || 0) * 100);
  return (
    <div style={{ marginBottom: 10 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
        <span style={{ fontSize: 12, color, fontFamily: "'Space Mono', monospace" }}>
          {EMOTION_KO[emotion] || emotion}
        </span>
        <span style={{ fontSize: 12, color: '#8fa0bc', fontFamily: "'Space Mono', monospace" }}>
          {pct}%
        </span>
      </div>
      <div style={{ height: 4, background: '#1e2d45', borderRadius: 2, overflow: 'hidden' }}>
        <div style={{
          height: '100%', width: `${pct}%`, background: color,
          borderRadius: 2, transition: 'width 1s ease',
          boxShadow: `0 0 8px ${color}66`,
        }} />
      </div>
    </div>
  );
}

function CustomTooltip({ active, payload, label }) {
  if (!active || !payload || !payload.length) return null;
  return (
    <div style={{
      background: '#0e1420', border: '1px solid #1e2d45',
      borderRadius: 8, padding: '10px 14px', fontSize: 12,
      fontFamily: "'Space Mono', monospace",
    }}>
      <p style={{ color: '#8fa0bc', marginBottom: 6 }}>
        {typeof label === 'number' ? label.toFixed(1) : label}s
      </p>
      {payload.map(p => (
        <p key={p.name} style={{ color: p.color, marginBottom: 2 }}>
          {p.name}: {typeof p.value === 'number' ? p.value.toFixed(2) : '-'}
        </p>
      ))}
    </div>
  );
}

function StatCell({ label, value }) {
  return (
    <div style={{ background: '#151c2c', borderRadius: 8, padding: '10px 12px' }}>
      <p style={{
        fontSize: 10, color: '#5a6a84',
        fontFamily: "'Space Mono', monospace", marginBottom: 4,
      }}>{label}</p>
      <p style={{ fontSize: 13, fontWeight: 700, color: '#e8edf5' }}>{value || '-'}</p>
    </div>
  );
}

function Card({ children, style = {} }) {
  return (
    <div className="card-hover" style={{
      background: '#0e1420', border: '1px solid #1e2d45',
      borderRadius: 16, padding: 24, ...style,
    }}>
      {children}
    </div>
  );
}

function CardLabel({ text }) {
  return (
    <p style={{
      fontSize: 11, color: '#5a6a84',
      fontFamily: "'Space Mono', monospace", marginBottom: 4,
    }}>{text}</p>
  );
}

// ─── 바이럴 점수 게이지 ───────────────────────────────────
function ViralGauge({ score, grade }) {
  const pct   = Math.round((score || 0) * 100);
  const color = GRADE_COLORS[grade] || '#5a6a84';
  const data  = [{ value: pct, fill: color }];

  return (
    <div style={{ textAlign: 'center' }}>
      <div style={{ position: 'relative', display: 'inline-block' }}>
        <RadialBarChart
          width={160} height={160}
          innerRadius={55} outerRadius={75}
          data={data} startAngle={210} endAngle={-30}
        >
          <RadialBar dataKey="value" cornerRadius={6} background={{ fill: '#1e2d45' }} />
        </RadialBarChart>
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: 'translate(-50%, -50%)', textAlign: 'center',
        }}>
          <p style={{ fontSize: 28, fontWeight: 800, color, lineHeight: 1 }}>{pct}</p>
          <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>/ 100</p>
        </div>
      </div>
      <div style={{
        display: 'inline-block', marginTop: 8,
        background: `${color}22`, border: `1px solid ${color}66`,
        borderRadius: 20, padding: '4px 16px',
      }}>
        <span style={{ fontSize: 18, fontWeight: 800, color }}>
          등급 {grade}
        </span>
      </div>
    </div>
  );
}

// ─── 숫자 포맷 (12000 → 1.2만) ───────────────────────────
function fmtNum(n) {
  if (n == null) return '-';
  if (n >= 100000000) return `${(n / 100000000).toFixed(1)}억`;
  if (n >= 10000)     return `${(n / 10000).toFixed(1)}만`;
  return n.toLocaleString();
}

// ─── 탭 버튼 ─────────────────────────────────────────────
function TabButton({ label, active, onClick }) {
  return (
    <button onClick={onClick} style={{
      background: active ? 'linear-gradient(135deg, #00f5c4, #7b61ff)' : 'transparent',
      border: active ? 'none' : '1px solid #1e2d45',
      borderRadius: 8, padding: '8px 20px',
      color: active ? '#080b12' : '#8fa0bc',
      fontSize: 13, fontWeight: 700,
      cursor: 'pointer', fontFamily: "'Syne', sans-serif",
    }}>
      {label}
    </button>
  );
}

// ─── 메인 앱 ─────────────────────────────────────────────
export default function App() {
  const [url,           setUrl]           = useState('');
  const [loading,       setLoading]       = useState(false);
  const [result,        setResult]        = useState(null);
  const [error,         setError]         = useState('');
  const [coachLoading,  setCoachLoading]  = useState(false);
  const [coachFeedback, setCoachFeedback] = useState('');
  const [activeTab,     setActiveTab]     = useState('analysis'); // 'analysis' | 'trend'
  const [trendData,     setTrendData]     = useState(null);
  const [trendLoading,  setTrendLoading]  = useState(false);

  // ── 트렌드 데이터 로드 ───────────────────────────────────
  const loadTrend = async () => {
    setTrendLoading(true);
    try {
      const res = await axios.get(`${API_BASE}/api/trend?limit=20`);
      setTrendData(res.data);
    } catch (e) {
      console.error('트렌드 로드 실패:', e);
    } finally {
      setTrendLoading(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'trend') loadTrend();
  }, [activeTab]);

  // ── 영상 분석 요청 ───────────────────────────────────────
  const handleAnalyze = async () => {
    if (!url.trim()) { setError('YouTube URL을 입력해주세요.'); return; }
    setLoading(true);
    setError('');
    setResult(null);
    setCoachFeedback('');
    try {
      const res = await axios.post(
        `${API_BASE}/api/analyze`,
        { url },
        { timeout: 300000 },
      );
      setResult(res.data);
      setActiveTab('analysis');
    } catch (e) {
      const detail = e.response?.data?.detail;
      setError(
        Array.isArray(detail)
          ? detail.map(d => d.msg).join(', ')
          : detail || '분석 중 오류가 발생했습니다. 서버를 확인해주세요.',
      );
    } finally {
      setLoading(false);
    }
  };

  // ── AI 코치 요청 ─────────────────────────────────────────
  const handleCoach = async () => {
    if (!result) return;
    setCoachLoading(true);
    setCoachFeedback('');
    try {
      const res = await axios.post(`${API_BASE}/api/coach`, {
        video_id: result.youtube_stats?.video_id || 'web_analysis',
        emotion_data: {
          face_summary:   result.face_summary,
          audio_summary:  result.audio_summary,
          scene_summary:  result.scene_summary,
          fusion_result:  result.fusion_result,
          viral_result:   result.viral_result,
          youtube_stats:  result.youtube_stats,
          video_info:     result.video_info,
        },
        question: '이 영상의 감정 분석 결과를 바탕으로 크리에이터에게 구체적인 피드백을 한국어로 해줘.',
      });
      setCoachFeedback(res.data.feedback || res.data.message || JSON.stringify(res.data));
    } catch (e) {
      const detail = e.response?.data?.detail;
      setCoachFeedback(
        Array.isArray(detail)
          ? '요청 형식 오류: ' + detail.map(d => d.msg).join(', ')
          : detail || 'AI 코치 응답을 가져오지 못했습니다.',
      );
    } finally {
      setCoachLoading(false);
    }
  };

  // ── 차트 데이터 ──────────────────────────────────────────
  const chartData = (result?.emotion_timeline || []).map(t => ({
    time:       typeof t.timestamp    === 'number' ? parseFloat(t.timestamp.toFixed(1))    : t.timestamp,
    '얼굴 감정':  typeof t.face_valence  === 'number' ? t.face_valence  : null,
    '음성 감정':  typeof t.audio_valence === 'number' ? t.audio_valence : null,
    '음성 에너지': typeof t.audio_energy  === 'number' ? t.audio_energy  : null,
  }));

  // ── 선택된 프레임 ─────────────────────────────────────────
  const [selectedFrame, setSelectedFrame] = React.useState(null);

  const handleChartClick = (data) => {
    if (!data || !data.activePayload) return;
    const time = data.activeLabel;
    const timeline = result?.emotion_timeline || [];
    const frame = timeline.find(t => parseFloat(t.timestamp.toFixed(1)) === parseFloat(Number(time).toFixed(1)))
      || timeline.reduce((prev, curr) =>
          Math.abs(curr.timestamp - time) < Math.abs(prev.timestamp - time) ? curr : prev, timeline[0]);
    if (frame) setSelectedFrame(frame);
  };

  const dominantEmotion = result?.face_summary?.peak_emotion?.emotion;
  const dominantColor   = EMOTION_COLORS[dominantEmotion] || '#00f5c4';

  const audioStats = result ? [
    { label: 'DOMINANT', value: EMOTION_KO[result.audio_summary?.dominant_emotion] || result.audio_summary?.dominant_emotion },
    { label: 'TEMPO',    value: result.audio_summary?.tempo != null ? `${result.audio_summary.tempo.toFixed(0)} BPM` : '-' },
    { label: 'LANGUAGE', value: result.audio_summary?.language?.toUpperCase() || '-' },
  ] : [];

  return (
    <div style={{ position: 'relative', zIndex: 1, minHeight: '100vh' }}>

      {/* ── 헤더 ─────────────────────────────────────────── */}
      <header style={{
        borderBottom: '1px solid #1e2d45',
        padding: '20px 40px',
        display: 'flex', alignItems: 'center', gap: 16,
        background: 'rgba(8,11,18,0.85)',
        backdropFilter: 'blur(12px)',
        position: 'sticky', top: 0, zIndex: 100,
      }}>
        <div style={{
          width: 36, height: 36, borderRadius: 8, flexShrink: 0,
          background: 'linear-gradient(135deg, #00f5c4, #7b61ff)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 18,
        }}>👁</div>
        <div>
          <h1 style={{ fontSize: 20, fontWeight: 800, letterSpacing: '-0.5px' }}>VibeView</h1>
          <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>
            감정이 조회수를 만든다
          </p>
        </div>

        {/* 탭 버튼 */}
        <div style={{ marginLeft: 'auto', display: 'flex', gap: 8 }}>
          <TabButton label="🔍 분석" active={activeTab === 'analysis'} onClick={() => setActiveTab('analysis')} />
          <TabButton label="📈 트렌드" active={activeTab === 'trend'}    onClick={() => setActiveTab('trend')} />
        </div>
      </header>

      <main style={{ maxWidth: 960, margin: '0 auto', padding: '32px 24px' }}>

        {/* ── URL 입력 ──────────────────────────────────── */}
        {activeTab === 'analysis' && (
          <div style={{ marginBottom: 32 }}>
            <div style={{ display: 'flex', gap: 12 }}>
              <input
                value={url}
                onChange={e => setUrl(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleAnalyze()}
                placeholder="YouTube Shorts URL을 입력하세요"
                style={{
                  flex: 1, background: '#0e1420', border: '1px solid #1e2d45',
                  borderRadius: 12, padding: '14px 18px',
                  color: '#e8edf5', fontSize: 14,
                  fontFamily: "'Space Mono', monospace", outline: 'none',
                }}
              />
              <button
                onClick={handleAnalyze}
                disabled={loading}
                style={{
                  background: loading ? '#1e2d45' : 'linear-gradient(135deg, #00f5c4, #7b61ff)',
                  border: 'none', borderRadius: 12, padding: '14px 28px',
                  color: loading ? '#5a6a84' : '#080b12',
                  fontSize: 14, fontWeight: 800,
                  cursor: loading ? 'not-allowed' : 'pointer',
                  fontFamily: "'Syne', sans-serif", whiteSpace: 'nowrap',
                }}
              >
                {loading ? '분석 중...' : '분석 시작'}
              </button>
            </div>
            {error && (
              <p style={{
                marginTop: 10, color: '#ff4d6d', fontSize: 13,
                fontFamily: "'Space Mono', monospace",
              }}>{error}</p>
            )}
          </div>
        )}

        {/* ── 로딩 ─────────────────────────────────────── */}
        {loading && (
          <div style={{ textAlign: 'center', padding: '60px 0' }}>
            <div style={{ fontSize: 48, marginBottom: 16 }}>⚙️</div>
            <p style={{ color: '#00f5c4', fontFamily: "'Space Mono', monospace", fontSize: 14 }}>
              영상 분석 중... (최대 5분 소요)
            </p>
          </div>
        )}

        {/* ── 분석 결과 ─────────────────────────────────── */}
        {result && activeTab === 'analysis' && (
          <div>

            {/* YouTube 통계 + 바이럴 점수 */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 20 }}>

              {/* YouTube 통계 카드 */}
              <Card>
                <CardLabel text="YOUTUBE STATS" />
                <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>YouTube 통계</p>

                {result.youtube_stats?.thumbnail_url && (
                  <img
                    src={result.youtube_stats.thumbnail_url}
                    alt="썸네일"
                    style={{
                      width: '100%', borderRadius: 10, marginBottom: 14,
                      objectFit: 'cover', maxHeight: 160,
                    }}
                  />
                )}

                <p style={{ fontSize: 14, fontWeight: 700, color: '#e8edf5', marginBottom: 4 }}>
                  {result.youtube_stats?.title || '-'}
                </p>
                <p style={{ fontSize: 12, color: '#5a6a84', marginBottom: 16 }}>
                  {result.youtube_stats?.channel || '-'}
                </p>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
                  <StatCell label="조회수"   value={fmtNum(result.youtube_stats?.view_count)} />
                  <StatCell label="좋아요"   value={fmtNum(result.youtube_stats?.like_count)} />
                  <StatCell label="댓글"     value={fmtNum(result.youtube_stats?.comment_count)} />
                  <StatCell label="일 평균"  value={result.youtube_stats?.views_per_day != null ? `${fmtNum(Math.round(result.youtube_stats.views_per_day))}회` : '-'} />
                  <StatCell label="업로드"   value={result.youtube_stats?.days_since_upload != null ? `${result.youtube_stats.days_since_upload}일 전` : '-'} />
                  <StatCell label="길이"     value={result.video_info?.duration != null ? `${result.video_info.duration.toFixed(0)}초` : '-'} />
                </div>
              </Card>

              {/* 바이럴 점수 카드 */}
              <Card>
                <CardLabel text="VIRAL SCORE" />
                <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>바이럴 예측 점수</p>

                <ViralGauge
                  score={result.viral_result?.viral_score}
                  grade={result.viral_result?.grade}
                />

                <div style={{ marginTop: 16 }}>
                  {/* 세부 점수 바 */}
                  {result.viral_result?.factors && Object.entries(result.viral_result.factors).map(([key, val]) => {
                    const labelMap = {
                      emotional_intensity:   '감정 강도',
                      emotional_consistency: '감정 일관성',
                      content_appeal:        '콘텐츠 호감도',
                      pacing:                '페이싱',
                      highlight_density:     '하이라이트 밀도',
                    };
                    const pct = Math.round((val || 0) * 100);
                    return (
                      <div key={key} style={{ marginBottom: 8 }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                          <span style={{ fontSize: 11, color: '#8fa0bc', fontFamily: "'Space Mono', monospace" }}>
                            {labelMap[key] || key}
                          </span>
                          <span style={{ fontSize: 11, color: '#8fa0bc', fontFamily: "'Space Mono', monospace" }}>
                            {pct}%
                          </span>
                        </div>
                        <div style={{ height: 3, background: '#1e2d45', borderRadius: 2 }}>
                          <div style={{
                            height: '100%', width: `${pct}%`,
                            background: 'linear-gradient(90deg, #7b61ff, #00f5c4)',
                            borderRadius: 2,
                          }} />
                        </div>
                      </div>
                    );
                  })}
                </div>

                {/* 개선 제안 */}
                {result.viral_result?.recommendation && (
                  <div style={{
                    marginTop: 14, background: '#151c2c', borderRadius: 8,
                    padding: '10px 12px', border: '1px solid #7b61ff33',
                  }}>
                    <p style={{ fontSize: 10, color: '#7b61ff', fontFamily: "'Space Mono', monospace", marginBottom: 4 }}>
                      💡 개선 제안
                    </p>
                    <p style={{ fontSize: 12, color: '#c4cfe0', lineHeight: 1.6 }}>
                      {result.viral_result.recommendation}
                    </p>
                  </div>
                )}
              </Card>
            </div>

            {/* 장면 분위기 + 융합 결과 */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 20 }}>

              {/* 장면 분위기 카드 */}
              <Card>
                <CardLabel text="SCENE ANALYSIS" />
                <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>장면 분위기 분석</p>

                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 16 }}>
                  {(result.fusion_result?.vibe_tags || []).map(tag => (
                    <span key={tag} style={{
                      background: '#7b61ff22', border: '1px solid #7b61ff66',
                      borderRadius: 20, padding: '4px 12px',
                      fontSize: 12, color: '#7b61ff', fontWeight: 700,
                    }}>
                      {tag}
                    </span>
                  ))}
                </div>

                {result.scene_summary?.vibe_distribution &&
                  Object.entries(result.scene_summary.vibe_distribution)
                    .sort((a, b) => b[1] - a[1])
                    .map(([vibe, val]) => {
                      const pct = Math.round(val * 100);
                      return (
                        <div key={vibe} style={{ marginBottom: 8 }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                            <span style={{ fontSize: 12, color: '#e8edf5' }}>{vibe}</span>
                            <span style={{ fontSize: 12, color: '#8fa0bc', fontFamily: "'Space Mono', monospace" }}>{pct}%</span>
                          </div>
                          <div style={{ height: 4, background: '#1e2d45', borderRadius: 2 }}>
                            <div style={{
                              height: '100%', width: `${pct}%`,
                              background: 'linear-gradient(90deg, #00f5c4, #7b61ff)',
                              borderRadius: 2,
                            }} />
                          </div>
                        </div>
                      );
                    })
                }

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginTop: 12 }}>
                  <StatCell label="콘텐츠 유형"   value={result.scene_summary?.content_type || '-'} />
                  <StatCell label="사람 등장 비율" value={result.scene_summary?.object_stats?.person_ratio != null ? `${Math.round(result.scene_summary.object_stats.person_ratio * 100)}%` : '-'} />
                </div>
              </Card>

              {/* 융합 결과 카드 */}
              <Card>
                <CardLabel text="FUSION RESULT" />
                <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>멀티모달 융합 분석</p>

                <div style={{ textAlign: 'center', marginBottom: 20 }}>
                  <p style={{ fontSize: 36, fontWeight: 800, color: '#00f5c4' }}>
                    {result.fusion_result?.fused_emotion || '-'}
                  </p>
                  <p style={{ fontSize: 12, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>
                    종합 감정
                  </p>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 16 }}>
                  <StatCell label="종합 VALENCE"  value={result.fusion_result?.fused_valence?.toFixed(3) ?? '-'} />
                  <StatCell label="분석 신뢰도"   value={result.fusion_result?.confidence != null ? `${Math.round(result.fusion_result.confidence * 100)}%` : '-'} />
                  <StatCell label="참여도 힌트"   value={result.fusion_result?.engagement_hint?.toFixed(3) ?? '-'} />
                  <StatCell label="하이라이트"    value={`${result.fusion_result?.highlight_moments?.length ?? 0}개`} />
                </div>

                {/* 모달리티별 점수 */}
                {result.fusion_result?.modality_scores && (
                  <div>
                    <p style={{ fontSize: 10, color: '#5a6a84', fontFamily: "'Space Mono', monospace", marginBottom: 8 }}>
                      MODALITY SCORES
                    </p>
                    {Object.entries(result.fusion_result.modality_scores).map(([k, v]) => {
                      const labelMap = { face: '얼굴', audio: '음성', scene: '장면' };
                      const pct = Math.round(Math.abs(v) * 100);
                      const color = v >= 0 ? '#00f5c4' : '#ff4d6d';
                      return (
                        <div key={k} style={{ marginBottom: 6 }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                            <span style={{ fontSize: 11, color: '#8fa0bc', fontFamily: "'Space Mono', monospace" }}>
                              {labelMap[k] || k}
                            </span>
                            <span style={{ fontSize: 11, color, fontFamily: "'Space Mono', monospace" }}>
                              {v?.toFixed(3)}
                            </span>
                          </div>
                          <div style={{ height: 3, background: '#1e2d45', borderRadius: 2 }}>
                            <div style={{ height: '100%', width: `${pct}%`, background: color, borderRadius: 2 }} />
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </Card>
            </div>

            {/* 얼굴 감정 + 음성 감정 */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 20 }}>

              {/* 얼굴 감정 카드 */}
              <Card>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
                  <span style={{ fontSize: 20 }}>😊</span>
                  <div>
                    <CardLabel text="FACE ANALYSIS" />
                    <p style={{ fontSize: 16, fontWeight: 700 }}>얼굴 감정 분석</p>
                  </div>
                  <div style={{ marginLeft: 'auto', textAlign: 'right' }}>
                    <p style={{ fontSize: 10, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>VALENCE</p>
                    <p style={{ fontSize: 20, fontWeight: 800, color: '#00f5c4' }}>
                      {result.face_summary?.avg_valence?.toFixed(2) ?? '-'}
                    </p>
                  </div>
                </div>

                {result.face_summary?.emotion_distribution &&
                  Object.entries(result.face_summary.emotion_distribution)
                    .sort((a, b) => b[1] - a[1])
                    .map(([emotion, value]) => (
                      <EmotionBar key={emotion} emotion={emotion} value={value} />
                    ))
                }

                {result.face_summary?.peak_emotion && (
                  <div style={{
                    marginTop: 16, padding: '10px 14px', borderRadius: 8,
                    background: '#151c2c', border: `1px solid ${dominantColor}33`,
                  }}>
                    <p style={{ fontSize: 10, color: '#5a6a84', fontFamily: "'Space Mono', monospace", marginBottom: 4 }}>
                      PEAK EMOTION
                    </p>
                    <p style={{ fontSize: 14, fontWeight: 700, color: dominantColor }}>
                      {EMOTION_KO[dominantEmotion] || dominantEmotion}
                      <span style={{ fontSize: 12, color: '#8fa0bc', marginLeft: 8, fontFamily: "'Space Mono', monospace" }}>
                        @ {result.face_summary.peak_emotion.timestamp?.toFixed(1)}s
                      </span>
                    </p>
                  </div>
                )}
              </Card>

              {/* 음성 감정 카드 */}
              <Card>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
                  <span style={{ fontSize: 20 }}>🎙️</span>
                  <div>
                    <CardLabel text="AUDIO ANALYSIS" />
                    <p style={{ fontSize: 16, fontWeight: 700 }}>음성 감정 분석</p>
                  </div>
                  <div style={{ marginLeft: 'auto', textAlign: 'right' }}>
                    <p style={{ fontSize: 10, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>VALENCE</p>
                    <p style={{ fontSize: 20, fontWeight: 800, color: '#7b61ff' }}>
                      {result.audio_summary?.avg_valence?.toFixed(2) ?? '-'}
                    </p>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginBottom: 16 }}>
                  {audioStats.map(s => (
                    <StatCell key={s.label} label={s.label} value={s.value} />
                  ))}
                </div>



                {/* 강점 / 약점 */}
                {(result.viral_result?.strong_points?.length > 0 || result.viral_result?.weak_points?.length > 0) && (
                  <div style={{ marginTop: 16 }}>
                    {result.viral_result.strong_points?.map((p, i) => (
                      <p key={i} style={{ fontSize: 12, color: '#00f5c4', marginBottom: 4 }}>✅ {p}</p>
                    ))}
                    {result.viral_result.weak_points?.map((p, i) => (
                      <p key={i} style={{ fontSize: 12, color: '#ff4d6d', marginBottom: 4 }}>⚠️ {p}</p>
                    ))}
                  </div>
                )}
              </Card>
            </div>

            {/* 감정 타임라인 차트 */}
            <Card style={{ marginBottom: 20 }}>
              <div style={{ marginBottom: 20 }}>
                <CardLabel text="EMOTION TIMELINE" />
                <p style={{ fontSize: 18, fontWeight: 700 }}>초 단위 감정 타임라인</p>
              </div>
              <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace", marginBottom: 12 }}>
                차트를 클릭하면 해당 시점의 프레임 이미지를 확인할 수 있습니다
              </p>
              <ResponsiveContainer width="100%" height={260}>
                <LineChart data={chartData} margin={{ top: 5, right: 20, bottom: 5, left: -10 }} onClick={handleChartClick} style={{ cursor: 'pointer' }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#1e2d45" />
                  <XAxis
                    dataKey="time" type="number"
                    domain={['dataMin', 'dataMax']}
                    tickFormatter={v => `${Number(v).toFixed(0)}s`}
                    stroke="#2a3a55"
                    tick={{ fill: '#5a6a84', fontSize: 11, fontFamily: 'Space Mono' }}
                  />
                  <YAxis
                    domain={[-1, 1]} stroke="#2a3a55"
                    tick={{ fill: '#5a6a84', fontSize: 11, fontFamily: 'Space Mono' }}
                  />
                  <Tooltip content={<CustomTooltip />} />
                  <Legend wrapperStyle={{ fontSize: 12, fontFamily: 'Space Mono', color: '#8fa0bc' }} />
                  <ReferenceLine y={0} stroke="#2a3a55" strokeDasharray="4 4" />
                  {selectedFrame && (
                    <ReferenceLine x={parseFloat(selectedFrame.timestamp.toFixed(1))} stroke="#ff4d6d" strokeWidth={2} strokeDasharray="4 2" />
                  )}
                  <Line type="monotone" dataKey="얼굴 감정"  stroke="#00f5c4" dot={false} strokeWidth={2}   connectNulls />
                  <Line type="monotone" dataKey="음성 감정"  stroke="#7b61ff" dot={false} strokeWidth={2}   connectNulls />
                  <Line type="monotone" dataKey="음성 에너지" stroke="#ffd166" dot={false} strokeWidth={1.5} strokeDasharray="4 2" connectNulls />
                </LineChart>
              </ResponsiveContainer>

              {/* 선택된 프레임 뷰어 */}
              {selectedFrame && (
                <div style={{
                  marginTop: 20, background: '#0d1420', borderRadius: 12,
                  border: '1px solid #ff4d6d44', padding: 16,
                  display: 'flex', gap: 20, alignItems: 'flex-start',
                }}>
                  {/* 프레임 이미지 */}
                  <div style={{ flexShrink: 0 }}>
                    {selectedFrame.frame_url ? (
                      <img
                        src={`http://localhost:8000${selectedFrame.frame_url}`}
                        alt={`frame_${selectedFrame.timestamp}`}
                        style={{
                          width: 160, height: 200, objectFit: 'contain', background: '#0d1420',
                          borderRadius: 8, border: '1px solid #1e2d45',
                          display: 'block',
                        }}
                        onError={(e) => { e.target.style.display = 'none'; }}
                      />
                    ) : (
                      <div style={{
                        width: 160, height: 100, borderRadius: 8,
                        background: '#1e2d45', display: 'flex',
                        alignItems: 'center', justifyContent: 'center',
                      }}>
                        <span style={{ color: '#5a6a84', fontSize: 12 }}>이미지 없음</span>
                      </div>
                    )}
                    <p style={{ fontSize: 10, color: '#5a6a84', marginTop: 6, fontFamily: "'Space Mono', monospace", textAlign: 'center' }}>
                      {selectedFrame.timestamp.toFixed(1)}s
                    </p>
                  </div>

                  {/* 감정 정보 */}
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: 10, color: '#ff4d6d', fontFamily: "'Space Mono', monospace", marginBottom: 10, letterSpacing: 1 }}>
                      FRAME @ {selectedFrame.timestamp.toFixed(1)}s
                    </p>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                      <div style={{ background: '#151c2c', borderRadius: 8, padding: '10px 12px', border: '1px solid #00f5c433' }}>
                        <p style={{ fontSize: 9, color: '#00f5c4', fontFamily: "'Space Mono', monospace", marginBottom: 4 }}>얼굴 감정</p>
                        <p style={{ fontSize: 16, fontWeight: 700, color: EMOTION_COLORS[selectedFrame.face_emotion] || '#00f5c4' }}>
                          {EMOTION_KO[selectedFrame.face_emotion] || selectedFrame.face_emotion || '-'}
                        </p>
                        <p style={{ fontSize: 11, color: '#5a6a84', marginTop: 2 }}>
                          극성: {selectedFrame.face_valence?.toFixed(2) ?? '-'}
                        </p>
                      </div>
                      <div style={{ background: '#151c2c', borderRadius: 8, padding: '10px 12px', border: '1px solid #7b61ff33' }}>
                        <p style={{ fontSize: 9, color: '#7b61ff', fontFamily: "'Space Mono', monospace", marginBottom: 4 }}>음성 감정</p>
                        <p style={{ fontSize: 16, fontWeight: 700, color: '#7b61ff' }}>
                          {EMOTION_KO[selectedFrame.audio_emotion] || selectedFrame.audio_emotion || '-'}
                        </p>
                        <p style={{ fontSize: 11, color: '#5a6a84', marginTop: 2 }}>
                          에너지: {selectedFrame.audio_energy?.toFixed(4) ?? '-'}
                        </p>
                      </div>
                    </div>
                    <div style={{ marginTop: 8, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                      <span style={{
                        fontSize: 10, padding: '3px 8px', borderRadius: 4,
                        background: '#1e2d45', color: '#8fa0bc',
                        fontFamily: "'Space Mono', monospace",
                      }}>
                        얼굴 {selectedFrame.face_count ?? 0}명 감지
                      </span>
                      <span style={{
                        fontSize: 10, padding: '3px 8px', borderRadius: 4,
                        background: '#1e2d45', color: '#8fa0bc',
                        fontFamily: "'Space Mono', monospace",
                      }}>
                        극성 차이: {Math.abs((selectedFrame.face_valence ?? 0) - (selectedFrame.audio_valence ?? 0)).toFixed(2)}
                      </span>
                    </div>
                  </div>

                  {/* 닫기 버튼 */}
                  <button
                    onClick={() => setSelectedFrame(null)}
                    style={{
                      background: 'none', border: 'none', color: '#5a6a84',
                      cursor: 'pointer', fontSize: 18, padding: 4, flexShrink: 0,
                    }}
                  >✕</button>
                </div>
              )}

              {/* 프레임 썸네일 스트립 */}
              {(result?.emotion_timeline || []).length > 0 && (
                <div style={{ marginTop: 16 }}>
                  <p style={{ fontSize: 10, color: '#5a6a84', fontFamily: "'Space Mono', monospace", marginBottom: 8 }}>
                    FRAME STRIP — 클릭하여 확인
                  </p>
                  <div style={{
                    display: 'flex', gap: 6, overflowX: 'auto',
                    paddingBottom: 8,
                  }}>
                    {(result.emotion_timeline || []).map((frame, i) => (
                      <div
                        key={i}
                        onClick={() => setSelectedFrame(frame)}
                        style={{
                          flexShrink: 0, cursor: 'pointer',
                          border: selectedFrame?.timestamp === frame.timestamp
                            ? '2px solid #ff4d6d' : '2px solid transparent',
                          borderRadius: 6, overflow: 'hidden',
                          transition: 'border 0.15s',
                          position: 'relative',
                        }}
                      >
                        {frame.frame_url ? (
                          <img
                            src={`http://localhost:8000${frame.frame_url}`}
                            alt={`frame_${frame.timestamp}`}
                            style={{ width: 64, height: 80, objectFit: 'contain', background: '#0d1420', display: 'block' }}
                            onError={(e) => { e.target.style.display = 'none'; }}
                          />
                        ) : (
                          <div style={{ width: 64, height: 40, background: '#1e2d45' }} />
                        )}
                        <div style={{
                          position: 'absolute', bottom: 0, left: 0, right: 0,
                          background: 'rgba(0,0,0,0.65)',
                          fontSize: 8, color: '#8fa0bc', textAlign: 'center',
                          padding: '1px 0', fontFamily: "'Space Mono', monospace",
                        }}>
                          {frame.timestamp.toFixed(1)}s
                        </div>
                        <div style={{
                          position: 'absolute', top: 2, right: 2,
                          width: 8, height: 8, borderRadius: '50%',
                          background: EMOTION_COLORS[frame.face_emotion] || '#5a6a84',
                        }} />
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </Card>

            {/* AI 코치 섹션 */}
            <Card>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
                <div>
                  <CardLabel text="GEMINI AI COACH" />
                  <p style={{ fontSize: 18, fontWeight: 700 }}>AI 감정 코치 피드백</p>
                </div>
                <button
                  onClick={handleCoach}
                  disabled={coachLoading}
                  style={{
                    background: coachLoading ? '#1e2d45' : 'linear-gradient(135deg, #7b61ff, #ff4d6d)',
                    border: 'none', borderRadius: 10, padding: '12px 24px',
                    color: coachLoading ? '#5a6a84' : '#fff',
                    fontSize: 13, fontWeight: 700,
                    cursor: coachLoading ? 'not-allowed' : 'pointer',
                    fontFamily: "'Syne', sans-serif",
                  }}
                >
                  {coachLoading ? '분석 중...' : '🤖 AI 코치 받기'}
                </button>
              </div>

              {coachFeedback ? (
                <div style={{ background: '#151c2c', borderRadius: 12, padding: 20, border: '1px solid #7b61ff33' }}>
                  <p style={{ fontSize: 14, color: '#c4cfe0', lineHeight: 1.8, whiteSpace: 'pre-wrap' }}>
                    {coachFeedback}
                  </p>
                </div>
              ) : (
                <div style={{ background: '#151c2c', borderRadius: 12, padding: 20, border: '1px dashed #1e2d45', textAlign: 'center' }}>
                  <p style={{ color: '#5a6a84', fontSize: 13, fontFamily: "'Space Mono', monospace" }}>
                    분석 완료 후 AI 코치 버튼을 눌러<br />Gemini의 피드백을 받아보세요
                  </p>
                </div>
              )}
            </Card>
          </div>
        )}

        {/* ── 트렌드 탭 ────────────────────────────────── */}
        {activeTab === 'trend' && (
          <div>
            {trendLoading && (
              <div style={{ textAlign: 'center', padding: '60px 0' }}>
                <p style={{ color: '#00f5c4', fontFamily: "'Space Mono', monospace" }}>
                  트렌드 데이터 로드 중...
                </p>
              </div>
            )}

            {trendData && trendData.status === 'no_data' && (
              <div style={{ textAlign: 'center', padding: '60px 0' }}>
                <p style={{ color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>
                  아직 분석된 영상이 없습니다.<br />먼저 영상을 분석해주세요.
                </p>
              </div>
            )}

            {trendData && trendData.status === 'success' && (
              <div>
                {/* 요약 통계 */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 20 }}>
                  <Card style={{ textAlign: 'center' }}>
                    <p style={{ fontSize: 32, fontWeight: 800, color: '#00f5c4' }}>{trendData.total_analyzed}</p>
                    <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>분석된 영상</p>
                  </Card>
                  <Card style={{ textAlign: 'center' }}>
                    <p style={{ fontSize: 32, fontWeight: 800, color: '#7b61ff' }}>
                      {Math.round((trendData.avg_viral_score || 0) * 100)}
                    </p>
                    <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>평균 바이럴 점수</p>
                  </Card>
                  <Card style={{ textAlign: 'center' }}>
                    <p style={{ fontSize: 32, fontWeight: 800, color: '#ffd166' }}>
                      {trendData.avg_valence?.toFixed(2) ?? '-'}
                    </p>
                    <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>평균 감정 극성</p>
                  </Card>
                  <Card style={{ textAlign: 'center' }}>
                    <p style={{ fontSize: 32, fontWeight: 800, color: '#ff4d6d' }}>
                      {Object.keys(trendData.grade_distribution || {})[0] || '-'}
                    </p>
                    <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>최다 등급</p>
                  </Card>
                </div>

                {/* TOP 바이럴 영상 */}
                <Card style={{ marginBottom: 20 }}>
                  <CardLabel text="TOP VIRAL" />
                  <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>🏆 바이럴 TOP 3</p>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                    {(trendData.top_viral || []).map((v, i) => (
                      <div key={i} style={{
                        display: 'flex', alignItems: 'center', gap: 14,
                        background: '#151c2c', borderRadius: 10, padding: 14,
                      }}>
                        <span style={{ fontSize: 24, width: 32, textAlign: 'center' }}>
                          {['🥇', '🥈', '🥉'][i]}
                        </span>
                        {v.thumbnail_url && (
                          <img src={v.thumbnail_url} alt="" style={{ width: 60, height: 40, objectFit: 'cover', borderRadius: 6 }} />
                        )}
                        <div style={{ flex: 1, minWidth: 0 }}>
                          <p style={{ fontSize: 13, fontWeight: 700, color: '#e8edf5', marginBottom: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                            {v.title || '-'}
                          </p>
                          <p style={{ fontSize: 11, color: '#5a6a84' }}>{v.channel || '-'}</p>
                        </div>
                        <div style={{ textAlign: 'right', flexShrink: 0 }}>
                          <p style={{ fontSize: 18, fontWeight: 800, color: GRADE_COLORS[v.grade] || '#5a6a84' }}>
                            {Math.round((v.viral_score || 0) * 100)}
                          </p>
                          <p style={{ fontSize: 10, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>
                            등급 {v.grade}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </Card>

                {/* 분위기 트렌드 + 감정 분포 */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 20 }}>
                  <Card>
                    <CardLabel text="VIBE TREND" />
                    <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>분위기 트렌드</p>
                    {Object.entries(trendData.vibe_trend || {}).map(([vibe, val]) => {
                      const pct = Math.round(val * 100);
                      return (
                        <div key={vibe} style={{ marginBottom: 10 }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                            <span style={{ fontSize: 13, color: '#e8edf5' }}>{vibe}</span>
                            <span style={{ fontSize: 12, color: '#8fa0bc', fontFamily: "'Space Mono', monospace" }}>{pct}%</span>
                          </div>
                          <div style={{ height: 4, background: '#1e2d45', borderRadius: 2 }}>
                            <div style={{ height: '100%', width: `${pct}%`, background: 'linear-gradient(90deg, #00f5c4, #7b61ff)', borderRadius: 2 }} />
                          </div>
                        </div>
                      );
                    })}
                  </Card>

                  <Card>
                    <CardLabel text="EMOTION TREND" />
                    <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>감정 분포</p>
                    {Object.entries(trendData.emotion_distribution || {}).map(([emotion, val]) => {
                      const pct = Math.round(val * 100);
                      return (
                        <div key={emotion} style={{ marginBottom: 10 }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                            <span style={{ fontSize: 13, color: '#e8edf5' }}>{emotion}</span>
                            <span style={{ fontSize: 12, color: '#8fa0bc', fontFamily: "'Space Mono', monospace" }}>{pct}%</span>
                          </div>
                          <div style={{ height: 4, background: '#1e2d45', borderRadius: 2 }}>
                            <div style={{ height: '100%', width: `${pct}%`, background: '#7b61ff', borderRadius: 2 }} />
                          </div>
                        </div>
                      );
                    })}
                  </Card>
                </div>

                {/* 최근 분석 영상 목록 */}
                <Card>
                  <CardLabel text="RECENT ANALYSIS" />
                  <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>최근 분석 영상</p>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                    {(trendData.recent_videos || []).map((v, i) => (
                      <div key={i} style={{
                        display: 'flex', alignItems: 'center', gap: 12,
                        background: '#151c2c', borderRadius: 10, padding: 12,
                      }}>
                        {v.thumbnail_url && (
                          <img src={v.thumbnail_url} alt="" style={{ width: 56, height: 36, objectFit: 'cover', borderRadius: 6, flexShrink: 0 }} />
                        )}
                        <div style={{ flex: 1, minWidth: 0 }}>
                          <p style={{ fontSize: 13, fontWeight: 700, color: '#e8edf5', marginBottom: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                            {v.title || v.video_url || '-'}
                          </p>
                          <p style={{ fontSize: 11, color: '#5a6a84' }}>
                            {v.channel || '-'} · {v.dominant_vibe || '-'} · {v.fused_emotion || '-'}
                          </p>
                        </div>
                        <div style={{ textAlign: 'right', flexShrink: 0 }}>
                          <span style={{
                            background: `${GRADE_COLORS[v.grade] || '#5a6a84'}22`,
                            border: `1px solid ${GRADE_COLORS[v.grade] || '#5a6a84'}66`,
                            borderRadius: 6, padding: '2px 10px',
                            fontSize: 12, fontWeight: 800,
                            color: GRADE_COLORS[v.grade] || '#5a6a84',
                          }}>
                            {v.grade || '-'}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </Card>
              </div>
            )}
          </div>
        )}

        {/* ── 초기 안내 ─────────────────────────────────── */}
        {!result && !loading && activeTab === 'analysis' && (
          <div style={{ textAlign: 'center', padding: '60px 0' }}>
            <div style={{ fontSize: 64, marginBottom: 20 }}>👁‍🗨</div>
            <p style={{ color: '#5a6a84', fontSize: 14, fontFamily: "'Space Mono', monospace" }}>
              YouTube Shorts URL을 입력하면<br />
              얼굴 + 음성 + 장면 감정을 분석합니다
            </p>
          </div>
        )}

      </main>
    </div>
  );
}
