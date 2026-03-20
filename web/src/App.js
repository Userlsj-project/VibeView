import React, { useState } from 'react';
import axios from 'axios';
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid,
  Tooltip, Legend, ResponsiveContainer, ReferenceLine
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
};

// ─── 감정 바 컴포넌트 ────────────────────────────────────
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

// ─── 커스텀 차트 툴팁 ────────────────────────────────────
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

// ─── 통계 칸 (음성 카드용) ───────────────────────────────
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

// ─── 메인 앱 ─────────────────────────────────────────────
export default function App() {
  const [url,          setUrl]          = useState('');
  const [loading,      setLoading]      = useState(false);
  const [result,       setResult]       = useState(null);
  const [error,        setError]        = useState('');
  const [coachLoading, setCoachLoading] = useState(false);
  const [coachFeedback,setCoachFeedback]= useState('');

  // ── 영상 분석 요청 ──────────────────────────────────────
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

  // ── AI 코치 요청 ────────────────────────────────────────
  // 백엔드 스키마: { video_id: str, emotion_data: dict, question: str }
  const handleCoach = async () => {
    if (!result) return;
    setCoachLoading(true);
    setCoachFeedback('');
    try {
      const res = await axios.post(`${API_BASE}/api/coach`, {
        video_id: 'web_analysis',
        emotion_data: {
          face_summary:  result.face_summary,
          audio_summary: result.audio_summary,
          video_info:    result.video_info,
        },
        question: '이 영상의 감정 분석 결과를 바탕으로 크리에이터에게 구체적인 피드백을 한국어로 해줘.',
      });
      setCoachFeedback(
        res.data.feedback || res.data.message || JSON.stringify(res.data),
      );
    } catch (e) {
      const detail = e.response?.data?.detail;
      setCoachFeedback(
        Array.isArray(detail)
          ? '요청 형식 오류: ' + detail.map(d => d.msg).join(', ')
          : detail || 'AI 코치 응답을 가져오지 못했습니다. 서버를 확인해주세요.',
      );
    } finally {
      setCoachLoading(false);
    }
  };

  // ── 차트 데이터 변환 ────────────────────────────────────
  const chartData = (result?.emotion_timeline || []).map(t => ({
    time:      typeof t.timestamp    === 'number' ? parseFloat(t.timestamp.toFixed(1))    : t.timestamp,
    '얼굴 감정': typeof t.face_valence  === 'number' ? t.face_valence  : null,
    '음성 감정': typeof t.audio_valence === 'number' ? t.audio_valence : null,
    '음성 에너지': typeof t.audio_energy  === 'number' ? t.audio_energy  : null,
  }));

  const dominantEmotion = result?.face_summary?.peak_emotion?.emotion;
  const dominantColor   = EMOTION_COLORS[dominantEmotion] || '#00f5c4';

  // ── 음성 통계 셀 데이터 ─────────────────────────────────
  const audioStats = result ? [
    {
      label: 'DOMINANT',
      value: EMOTION_KO[result.audio_summary?.dominant_emotion]
             || result.audio_summary?.dominant_emotion,
    },
    {
      label: 'TEMPO',
      value: result.audio_summary?.tempo != null
             ? `${result.audio_summary.tempo.toFixed(0)} BPM`
             : '-',
    },
    {
      label: 'LANGUAGE',
      value: result.audio_summary?.language?.toUpperCase() || '-',
    },
  ] : [];

  return (
    <div style={{ position: 'relative', zIndex: 1, minHeight: '100vh' }}>

      {/* ── 헤더 ────────────────────────────────────────── */}
      <header style={{
        borderBottom: '1px solid #1e2d45',
        padding: '20px 40px',
        display: 'flex',
        alignItems: 'center',
        gap: 16,
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
          <h1 style={{ fontSize: 20, fontWeight: 800, letterSpacing: '-0.5px' }}>
            VibeView
          </h1>
          <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>
            감정이 조회수를 만든다
          </p>
        </div>

        <div className="tag-group" style={{ marginLeft: 'auto', display: 'flex', gap: 8 }}>
          {['FACE', 'AUDIO', 'AI COACH'].map(tag => (
            <span key={tag} style={{
              fontSize: 10, padding: '3px 8px', borderRadius: 4,
              border: '1px solid #1e2d45', color: '#5a6a84',
              fontFamily: "'Space Mono', monospace",
            }}>{tag}</span>
          ))}
        </div>
      </header>

      <main style={{ padding: '40px', maxWidth: 1100, margin: '0 auto' }}>

        {/* ── URL 입력 섹션 ────────────────────────────── */}
        <section style={{ marginBottom: 48 }}>
          <p style={{
            fontSize: 11, color: '#00f5c4',
            fontFamily: "'Space Mono', monospace",
            letterSpacing: 2, marginBottom: 12,
          }}>// ANALYZE VIDEO</p>

          <h2 style={{ fontSize: 32, fontWeight: 800, marginBottom: 24, lineHeight: 1.2 }}>
            영상 URL을 입력하고<br />
            <span style={{ color: '#00f5c4' }}>감정을 분석</span>하세요
          </h2>

          <div className="url-row" style={{ display: 'flex', gap: 12, maxWidth: 700 }}>
            <input
              value={url}
              onChange={e => setUrl(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && !loading && handleAnalyze()}
              placeholder="https://youtube.com/shorts/..."
              disabled={loading}
              style={{
                flex: 1, background: '#0e1420', border: '1px solid #1e2d45',
                borderRadius: 10, padding: '14px 18px', color: '#e8edf5',
                fontSize: 14, fontFamily: "'Space Mono', monospace",
                transition: 'border-color 0.2s',
                opacity: loading ? 0.6 : 1,
              }}
              onFocus={e => e.target.style.borderColor = '#00f5c4'}
              onBlur={e  => e.target.style.borderColor = '#1e2d45'}
            />
            <button
              onClick={handleAnalyze}
              disabled={loading}
              style={{
                background: loading
                  ? '#1e2d45'
                  : 'linear-gradient(135deg, #00f5c4, #7b61ff)',
                border: 'none', borderRadius: 10, padding: '14px 28px',
                color: loading ? '#5a6a84' : '#080b12',
                fontSize: 14, fontWeight: 700,
                cursor: loading ? 'not-allowed' : 'pointer',
                fontFamily: "'Syne', sans-serif",
                whiteSpace: 'nowrap',
              }}
            >
              {loading ? '분석 중...' : '분석 시작'}
            </button>
          </div>

          {error && (
            <p style={{
              marginTop: 12, color: '#ff4d6d', fontSize: 13,
              fontFamily: "'Space Mono', monospace",
            }}>⚠ {error}</p>
          )}
        </section>

        {/* ── 로딩 상태 ────────────────────────────────── */}
        {loading && (
          <div style={{
            background: '#0e1420', border: '1px solid #1e2d45',
            borderRadius: 16, padding: 40, textAlign: 'center',
          }}>
            <div style={{
              width: 48, height: 48,
              border: '3px solid #1e2d45',
              borderTop: '3px solid #00f5c4',
              borderRadius: '50%',
              margin: '0 auto 20px',
              animation: 'spin 1s linear infinite',
            }} />
            <p style={{
              color: '#8fa0bc', fontFamily: "'Space Mono', monospace", fontSize: 13,
            }}>
              영상 다운로드 → 얼굴 분석 → 음성 분석 중...
            </p>
            <p style={{
              color: '#5a6a84', fontSize: 11, marginTop: 8,
              fontFamily: "'Space Mono', monospace",
            }}>
              영상 길이에 따라 1~3분 소요될 수 있습니다
            </p>
          </div>
        )}

        {/* ── 분석 결과 ────────────────────────────────── */}
        {result && !loading && (
          <div style={{ animation: 'fadeIn 0.5s ease' }}>

            {/* 비디오 기본 정보 */}
            <div className="info-grid" style={{
              display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)',
              gap: 16, marginBottom: 32,
            }}>
              {[
                { label: 'DURATION',   value: `${result.video_info?.duration?.toFixed(1)}s` },
                { label: 'FPS',        value: result.video_info?.fps?.toFixed(0) },
                { label: 'RESOLUTION', value: `${result.video_info?.width}×${result.video_info?.height}` },
                { label: 'FRAMES',     value: result.video_info?.total_frames },
              ].map(item => (
                <div key={item.label} className="card-hover" style={{
                  background: '#0e1420', border: '1px solid #1e2d45',
                  borderRadius: 12, padding: '16px 20px',
                }}>
                  <p style={{
                    fontSize: 10, color: '#5a6a84',
                    fontFamily: "'Space Mono', monospace", marginBottom: 6,
                  }}>{item.label}</p>
                  <p style={{ fontSize: 22, fontWeight: 800, color: '#e8edf5' }}>
                    {item.value ?? '-'}
                  </p>
                </div>
              ))}
            </div>

            {/* 얼굴 감정 + 음성 감정 카드 */}
            <div className="analysis-grid" style={{
              display: 'grid', gridTemplateColumns: '1fr 1fr',
              gap: 20, marginBottom: 32,
            }}>

              {/* 얼굴 감정 카드 */}
              <div className="card-hover" style={{
                background: '#0e1420', border: '1px solid #1e2d45',
                borderRadius: 16, padding: 24,
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
                  <span style={{ fontSize: 20 }}>😊</span>
                  <div>
                    <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>
                      FACE ANALYSIS
                    </p>
                    <p style={{ fontSize: 16, fontWeight: 700 }}>얼굴 감정 분석</p>
                  </div>
                  <div style={{ marginLeft: 'auto', textAlign: 'right' }}>
                    <p style={{ fontSize: 10, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>
                      VALENCE
                    </p>
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
                    background: '#151c2c',
                    border: `1px solid ${dominantColor}33`,
                  }}>
                    <p style={{
                      fontSize: 10, color: '#5a6a84',
                      fontFamily: "'Space Mono', monospace", marginBottom: 4,
                    }}>PEAK EMOTION</p>
                    <p style={{ fontSize: 14, fontWeight: 700, color: dominantColor }}>
                      {EMOTION_KO[dominantEmotion] || dominantEmotion}
                      <span style={{
                        fontSize: 12, color: '#8fa0bc',
                        marginLeft: 8, fontFamily: "'Space Mono', monospace",
                      }}>
                        @ {result.face_summary.peak_emotion.timestamp?.toFixed(1)}s
                      </span>
                    </p>
                  </div>
                )}
              </div>

              {/* 음성 감정 카드 */}
              <div className="card-hover" style={{
                background: '#0e1420', border: '1px solid #1e2d45',
                borderRadius: 16, padding: 24,
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
                  <span style={{ fontSize: 20 }}>🎙️</span>
                  <div>
                    <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>
                      AUDIO ANALYSIS
                    </p>
                    <p style={{ fontSize: 16, fontWeight: 700 }}>음성 감정 분석</p>
                  </div>
                  <div style={{ marginLeft: 'auto', textAlign: 'right' }}>
                    <p style={{ fontSize: 10, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>
                      VALENCE
                    </p>
                    <p style={{ fontSize: 20, fontWeight: 800, color: '#7b61ff' }}>
                      {result.audio_summary?.avg_valence?.toFixed(2) ?? '-'}
                    </p>
                  </div>
                </div>

                {/* ✅ 3열 그리드 (아이템 3개에 맞게 수정) */}
                <div className="audio-stats-grid" style={{
                  display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
                  gap: 10, marginBottom: 16,
                }}>
                  {audioStats.map(s => (
                    <StatCell key={s.label} label={s.label} value={s.value} />
                  ))}
                </div>

                {result.audio_summary?.full_text && (
                  <div style={{
                    background: '#151c2c', borderRadius: 8,
                    padding: '12px 14px', border: '1px solid #1e2d45',
                  }}>
                    <p style={{
                      fontSize: 10, color: '#5a6a84',
                      fontFamily: "'Space Mono', monospace", marginBottom: 6,
                    }}>TRANSCRIPT</p>
                    <p className="scrollable-text" style={{
                      fontSize: 13, color: '#8fa0bc',
                      lineHeight: 1.6, maxHeight: 80, overflowY: 'auto',
                    }}>
                      {result.audio_summary.full_text}
                    </p>
                  </div>
                )}
              </div>
            </div>

            {/* 감정 타임라인 차트 */}
            <div className="card-hover" style={{
              background: '#0e1420', border: '1px solid #1e2d45',
              borderRadius: 16, padding: 24, marginBottom: 32,
            }}>
              <div style={{ marginBottom: 20 }}>
                <p style={{
                  fontSize: 11, color: '#5a6a84',
                  fontFamily: "'Space Mono', monospace", marginBottom: 4,
                }}>EMOTION TIMELINE</p>
                <p style={{ fontSize: 18, fontWeight: 700 }}>초 단위 감정 타임라인</p>
              </div>

              <ResponsiveContainer width="100%" height={260}>
                <LineChart data={chartData} margin={{ top: 5, right: 20, bottom: 5, left: -10 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#1e2d45" />
                  <XAxis
                    dataKey="time"
                    type="number"
                    domain={['dataMin', 'dataMax']}
                    tickFormatter={v => `${Number(v).toFixed(0)}s`}
                    stroke="#2a3a55"
                    tick={{ fill: '#5a6a84', fontSize: 11, fontFamily: 'Space Mono' }}
                  />
                  <YAxis
                    domain={[-1, 1]}
                    stroke="#2a3a55"
                    tick={{ fill: '#5a6a84', fontSize: 11, fontFamily: 'Space Mono' }}
                  />
                  <Tooltip content={<CustomTooltip />} />
                  <Legend wrapperStyle={{ fontSize: 12, fontFamily: 'Space Mono', color: '#8fa0bc' }} />
                  <ReferenceLine y={0} stroke="#2a3a55" strokeDasharray="4 4" />
                  <Line type="monotone" dataKey="얼굴 감정"  stroke="#00f5c4" dot={false} strokeWidth={2}   connectNulls />
                  <Line type="monotone" dataKey="음성 감정"  stroke="#7b61ff" dot={false} strokeWidth={2}   connectNulls />
                  <Line type="monotone" dataKey="음성 에너지" stroke="#ffd166" dot={false} strokeWidth={1.5} strokeDasharray="4 2" connectNulls />
                </LineChart>
              </ResponsiveContainer>
            </div>

            {/* AI 코치 섹션 */}
            <div className="card-hover" style={{
              background: '#0e1420', border: '1px solid #1e2d45',
              borderRadius: 16, padding: 24,
            }}>
              <div style={{
                display: 'flex', alignItems: 'center',
                justifyContent: 'space-between', marginBottom: 20,
              }}>
                <div>
                  <p style={{
                    fontSize: 11, color: '#5a6a84',
                    fontFamily: "'Space Mono', monospace", marginBottom: 4,
                  }}>GEMINI AI COACH</p>
                  <p style={{ fontSize: 18, fontWeight: 700 }}>AI 감정 코치 피드백</p>
                </div>
                <button
                  onClick={handleCoach}
                  disabled={coachLoading}
                  style={{
                    background: coachLoading
                      ? '#1e2d45'
                      : 'linear-gradient(135deg, #7b61ff, #ff4d6d)',
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
                <div style={{
                  background: '#151c2c', borderRadius: 12, padding: 20,
                  border: '1px solid #7b61ff33',
                }}>
                  <p style={{
                    fontSize: 14, color: '#c4cfe0',
                    lineHeight: 1.8, whiteSpace: 'pre-wrap',
                  }}>{coachFeedback}</p>
                </div>
              ) : (
                <div style={{
                  background: '#151c2c', borderRadius: 12, padding: 20,
                  border: '1px dashed #1e2d45', textAlign: 'center',
                }}>
                  <p style={{
                    color: '#5a6a84', fontSize: 13,
                    fontFamily: "'Space Mono', monospace",
                  }}>
                    분석 완료 후 AI 코치 버튼을 눌러<br />
                    Gemini의 피드백을 받아보세요
                  </p>
                </div>
              )}
            </div>

          </div>
        )}

        {/* ── 초기 안내 화면 ────────────────────────────── */}
        {!result && !loading && (
          <div style={{ textAlign: 'center', padding: '60px 0' }}>
            <div style={{ fontSize: 64, marginBottom: 20 }}>👁‍🗨</div>
            <p style={{
              color: '#5a6a84', fontSize: 14,
              fontFamily: "'Space Mono', monospace",
            }}>
              YouTube Shorts URL을 입력하면<br />
              얼굴 + 음성 감정을 분석합니다
            </p>
          </div>
        )}

      </main>
    </div>
  );
}
