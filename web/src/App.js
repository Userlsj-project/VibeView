import React, { useState, useEffect } from 'react';
import axios from 'axios';
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid,
  Tooltip, Legend, ResponsiveContainer, ReferenceLine,
  RadarChart, Radar, PolarGrid, PolarAngleAxis,
  BarChart, Bar, Cell,
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

const GRADE_COLORS = {
  S: '#00f5c4',
  A: '#7b61ff',
  B: '#ffd166',
  C: '#ff8c42',
  D: '#ff4d6d',
};

const VIBE_COLORS = [
  '#00f5c4','#7b61ff','#ffd166','#ff4d6d','#4d9fff','#a855f7','#84cc16',
];

// ─── 숫자 포맷 헬퍼 ──────────────────────────────────────
function fmtNum(n) {
  if (n == null) return '-';
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M';
  if (n >= 1_000)     return (n / 1_000).toFixed(1) + 'K';
  return String(n);
}

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

// ─── 카드 섹션 헤더 ──────────────────────────────────────
function CardHeader({ icon, tag, title, rightLabel, rightValue, rightColor = '#00f5c4' }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
      <span style={{ fontSize: 20 }}>{icon}</span>
      <div>
        <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>{tag}</p>
        <p style={{ fontSize: 16, fontWeight: 700 }}>{title}</p>
      </div>
      {rightLabel && (
        <div style={{ marginLeft: 'auto', textAlign: 'right' }}>
          <p style={{ fontSize: 10, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>{rightLabel}</p>
          <p style={{ fontSize: 20, fontWeight: 800, color: rightColor }}>{rightValue ?? '-'}</p>
        </div>
      )}
    </div>
  );
}

// ─── YouTube 통계 카드 ───────────────────────────────────
function YouTubeStatsCard({ stats }) {
  if (!stats) return null;
  return (
    <div className="card-hover" style={{
      background: '#0e1420', border: '1px solid #1e2d45',
      borderRadius: 16, padding: 24, marginBottom: 32,
    }}>
      <CardHeader icon="📺" tag="YOUTUBE STATS" title="YouTube 통계" />

      <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap' }}>
        {/* 썸네일 */}
        {stats.thumbnail_url && (
          <div style={{ flexShrink: 0 }}>
            <img
              src={stats.thumbnail_url}
              alt="thumbnail"
              style={{
                width: 160, borderRadius: 10,
                border: '1px solid #1e2d45',
                display: 'block',
              }}
            />
          </div>
        )}

        {/* 텍스트 정보 */}
        <div style={{ flex: 1, minWidth: 200 }}>
          {/* 제목 */}
          {stats.title && (
            <p style={{
              fontSize: 15, fontWeight: 700, marginBottom: 6,
              color: '#e8edf5', lineHeight: 1.4,
            }}>{stats.title}</p>
          )}
          {/* 채널 */}
          {stats.channel && (
            <p style={{
              fontSize: 12, color: '#00f5c4', marginBottom: 16,
              fontFamily: "'Space Mono', monospace",
            }}>@ {stats.channel}</p>
          )}

          {/* 통계 그리드 */}
          <div style={{
            display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
            gap: 10,
          }}>
            {[
              { label: 'VIEWS',     value: fmtNum(stats.view_count),    color: '#00f5c4' },
              { label: 'LIKES',     value: fmtNum(stats.like_count),    color: '#ffd166' },
              { label: 'COMMENTS',  value: fmtNum(stats.comment_count), color: '#7b61ff' },
              { label: 'VIEWS/DAY', value: stats.views_per_day != null ? fmtNum(Math.round(stats.views_per_day)) : '-', color: '#ff4d6d' },
              { label: 'DAYS UP',   value: stats.days_since_upload != null ? `${stats.days_since_upload}d` : '-', color: '#8fa0bc' },
              { label: 'VIDEO ID',  value: stats.video_id ? stats.video_id.slice(0, 8) + '…' : '-', color: '#5a6a84' },
            ].map(item => (
              <div key={item.label} style={{
                background: '#151c2c', borderRadius: 8, padding: '10px 12px',
              }}>
                <p style={{
                  fontSize: 10, color: '#5a6a84',
                  fontFamily: "'Space Mono', monospace", marginBottom: 4,
                }}>{item.label}</p>
                <p style={{ fontSize: 14, fontWeight: 800, color: item.color }}>{item.value}</p>
              </div>
            ))}
          </div>

          {/* 태그 */}
          {stats.tags && stats.tags.length > 0 && (
            <div style={{ marginTop: 12, display: 'flex', flexWrap: 'wrap', gap: 6 }}>
              {stats.tags.slice(0, 6).map(tag => (
                <span key={tag} style={{
                  fontSize: 11, padding: '2px 8px', borderRadius: 4,
                  border: '1px solid #2a3a55', color: '#8fa0bc',
                  fontFamily: "'Space Mono', monospace",
                }}>#{tag}</span>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ─── 장면 분석 카드 ──────────────────────────────────────
function SceneCard({ scene }) {
  if (!scene) return null;

  const vibeData = scene.vibe_distribution
    ? Object.entries(scene.vibe_distribution)
        .sort((a, b) => b[1] - a[1])
        .map(([name, value], i) => ({
          name,
          value: Math.round(value * 100),
          fill: VIBE_COLORS[i % VIBE_COLORS.length],
        }))
    : [];

  return (
    <div className="card-hover" style={{
      background: '#0e1420', border: '1px solid #1e2d45',
      borderRadius: 16, padding: 24,
    }}>
      <CardHeader
        icon="🎬"
        tag="SCENE ANALYSIS"
        title="장면 분위기 분석"
        rightLabel="DOMINANT VIBE"
        rightValue={scene.dominant_vibe || '-'}
        rightColor="#ffd166"
      />

      {/* 콘텐츠 유형 + 객체 통계 */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10, marginBottom: 20 }}>
        {[
          { label: 'CONTENT TYPE', value: scene.content_type || '-' },
          { label: 'PERSON RATIO', value: scene.object_stats?.person_ratio != null ? `${Math.round(scene.object_stats.person_ratio * 100)}%` : '-' },
          { label: 'AVG PERSONS',  value: scene.object_stats?.avg_person_count != null ? scene.object_stats.avg_person_count.toFixed(1) : '-' },
        ].map(item => (
          <StatCell key={item.label} label={item.label} value={item.value} />
        ))}
      </div>

      {/* 분위기 분포 수평 바 차트 */}
      {vibeData.length > 0 && (
        <>
          <p style={{
            fontSize: 10, color: '#5a6a84',
            fontFamily: "'Space Mono', monospace", marginBottom: 10,
          }}>VIBE DISTRIBUTION</p>
          {vibeData.map(v => (
            <div key={v.name} style={{ marginBottom: 8 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                <span style={{ fontSize: 12, color: v.fill, fontFamily: "'Space Mono', monospace" }}>{v.name}</span>
                <span style={{ fontSize: 12, color: '#8fa0bc', fontFamily: "'Space Mono', monospace" }}>{v.value}%</span>
              </div>
              <div style={{ height: 4, background: '#1e2d45', borderRadius: 2, overflow: 'hidden' }}>
                <div style={{
                  height: '100%', width: `${v.value}%`, background: v.fill,
                  borderRadius: 2, transition: 'width 1s ease',
                  boxShadow: `0 0 8px ${v.fill}66`,
                }} />
              </div>
            </div>
          ))}
        </>
      )}
    </div>
  );
}

// ─── 융합 결과 카드 ──────────────────────────────────────
function FusionCard({ fusion }) {
  if (!fusion) return null;

  const radarData = fusion.modality_scores
    ? [
        { subject: '얼굴',  value: Math.round((fusion.modality_scores.face  || 0) * 100) },
        { subject: '음성',  value: Math.round((fusion.modality_scores.audio || 0) * 100) },
        { subject: '장면',  value: Math.round((fusion.modality_scores.scene || 0) * 100) },
      ]
    : [];

  const confidencePct = Math.round((fusion.confidence || 0) * 100);

  return (
    <div className="card-hover" style={{
      background: '#0e1420', border: '1px solid #1e2d45',
      borderRadius: 16, padding: 24,
    }}>
      <CardHeader
        icon="🔮"
        tag="FUSION RESULT"
        title="멀티모달 융합 결과"
        rightLabel="FUSED EMOTION"
        rightValue={fusion.fused_emotion || '-'}
        rightColor="#7b61ff"
      />

      {/* 신뢰도 바 */}
      <div style={{ marginBottom: 20 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
          <span style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>CONFIDENCE</span>
          <span style={{ fontSize: 11, color: '#7b61ff', fontFamily: "'Space Mono', monospace" }}>{confidencePct}%</span>
        </div>
        <div style={{ height: 6, background: '#1e2d45', borderRadius: 3, overflow: 'hidden' }}>
          <div style={{
            height: '100%', width: `${confidencePct}%`,
            background: 'linear-gradient(90deg, #7b61ff, #00f5c4)',
            borderRadius: 3, transition: 'width 1s ease',
          }} />
        </div>
      </div>

      {/* 레이더 차트 */}
      {radarData.length > 0 && (
        <ResponsiveContainer width="100%" height={180}>
          <RadarChart data={radarData} margin={{ top: 10, right: 20, bottom: 10, left: 20 }}>
            <PolarGrid stroke="#1e2d45" />
            <PolarAngleAxis
              dataKey="subject"
              tick={{ fill: '#8fa0bc', fontSize: 12, fontFamily: 'Space Mono' }}
            />
            <Radar
              name="모달리티 점수"
              dataKey="value"
              stroke="#7b61ff"
              fill="#7b61ff"
              fillOpacity={0.25}
            />
          </RadarChart>
        </ResponsiveContainer>
      )}

      {/* Vibe 태그 */}
      {fusion.vibe_tags && fusion.vibe_tags.length > 0 && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 8 }}>
          {fusion.vibe_tags.map(tag => (
            <span key={tag} style={{
              fontSize: 11, padding: '3px 10px', borderRadius: 20,
              background: 'rgba(123,97,255,0.15)',
              border: '1px solid rgba(123,97,255,0.4)',
              color: '#7b61ff', fontFamily: "'Space Mono', monospace",
            }}>{tag}</span>
          ))}
        </div>
      )}

      {/* 하이라이트 모먼트 */}
      {fusion.highlight_moments && fusion.highlight_moments.length > 0 && (
        <div style={{ marginTop: 16 }}>
          <p style={{
            fontSize: 10, color: '#5a6a84',
            fontFamily: "'Space Mono', monospace", marginBottom: 8,
          }}>HIGHLIGHT MOMENTS</p>
          {fusion.highlight_moments.slice(0, 3).map((m, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '8px 10px', borderRadius: 8, background: '#151c2c', marginBottom: 6,
            }}>
              <span style={{
                fontSize: 11, color: '#ffd166',
                fontFamily: "'Space Mono', monospace", flexShrink: 0,
              }}>{m.timestamp?.toFixed(1)}s</span>
              <div style={{
                flex: 1, height: 3, background: '#1e2d45', borderRadius: 2, overflow: 'hidden',
              }}>
                <div style={{
                  height: '100%',
                  width: `${Math.round((m.intensity || 0) * 100)}%`,
                  background: '#ffd166', borderRadius: 2,
                }} />
              </div>
              <span style={{
                fontSize: 11, color: '#8fa0bc',
                fontFamily: "'Space Mono', monospace", flexShrink: 0,
              }}>{m.reason || ''}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ─── 바이럴 점수 카드 ────────────────────────────────────
function ViralCard({ viral }) {
  if (!viral) return null;

  const grade      = viral.grade || 'D';
  const gradeColor = GRADE_COLORS[grade] || '#5a6a84';
  const score      = viral.viral_score != null ? viral.viral_score.toFixed(1) : '-';

  const factorData = viral.factors
    ? [
        { name: '감정 강도',    value: Math.round((viral.factors.emotional_intensity   || 0) * 100) },
        { name: '감정 일관성',  value: Math.round((viral.factors.emotional_consistency || 0) * 100) },
        { name: '콘텐츠 매력',  value: Math.round((viral.factors.content_appeal        || 0) * 100) },
        { name: '페이싱',       value: Math.round((viral.factors.pacing                || 0) * 100) },
        { name: '하이라이트',   value: Math.round((viral.factors.highlight_density     || 0) * 100) },
      ]
    : [];

  return (
    <div className="card-hover" style={{
      background: '#0e1420', border: `1px solid ${gradeColor}33`,
      borderRadius: 16, padding: 24,
    }}>
      {/* 헤더: 등급 + 점수 */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 20 }}>
        <div style={{
          width: 56, height: 56, borderRadius: 12, flexShrink: 0,
          background: `${gradeColor}22`,
          border: `2px solid ${gradeColor}66`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 28, fontWeight: 800, color: gradeColor,
          fontFamily: "'Space Mono', monospace",
        }}>{grade}</div>
        <div>
          <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>VIRAL PREDICTOR</p>
          <p style={{ fontSize: 16, fontWeight: 700 }}>바이럴 예측 점수</p>
        </div>
        <div style={{ marginLeft: 'auto', textAlign: 'right' }}>
          <p style={{ fontSize: 10, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>SCORE</p>
          <p style={{ fontSize: 28, fontWeight: 800, color: gradeColor }}>{score}</p>
        </div>
      </div>

      {/* 팩터 바 차트 */}
      {factorData.length > 0 && (
        <>
          <p style={{
            fontSize: 10, color: '#5a6a84',
            fontFamily: "'Space Mono', monospace", marginBottom: 10,
          }}>FACTOR BREAKDOWN</p>
          <ResponsiveContainer width="100%" height={130}>
            <BarChart data={factorData} layout="vertical" margin={{ top: 0, right: 10, left: 60, bottom: 0 }}>
              <XAxis type="number" domain={[0, 100]} hide />
              <YAxis
                type="category"
                dataKey="name"
                width={60}
                tick={{ fill: '#8fa0bc', fontSize: 11, fontFamily: 'Space Mono' }}
                axisLine={false}
                tickLine={false}
              />
              <Bar dataKey="value" radius={[0, 4, 4, 0]}>
                {factorData.map((entry, i) => (
                  <Cell key={i} fill={gradeColor} fillOpacity={0.7 + i * 0.05} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </>
      )}

      {/* 강점/약점 */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 16 }}>
        {viral.strong_points && viral.strong_points.length > 0 && (
          <div style={{ background: '#151c2c', borderRadius: 10, padding: '12px 14px' }}>
            <p style={{
              fontSize: 10, color: '#00f5c4',
              fontFamily: "'Space Mono', monospace", marginBottom: 8,
            }}>✦ STRONG POINTS</p>
            {viral.strong_points.map((pt, i) => (
              <p key={i} style={{
                fontSize: 12, color: '#8fa0bc', marginBottom: 4, lineHeight: 1.5,
              }}>· {pt}</p>
            ))}
          </div>
        )}
        {viral.weak_points && viral.weak_points.length > 0 && (
          <div style={{ background: '#151c2c', borderRadius: 10, padding: '12px 14px' }}>
            <p style={{
              fontSize: 10, color: '#ff4d6d',
              fontFamily: "'Space Mono', monospace", marginBottom: 8,
            }}>✦ WEAK POINTS</p>
            {viral.weak_points.map((pt, i) => (
              <p key={i} style={{
                fontSize: 12, color: '#8fa0bc', marginBottom: 4, lineHeight: 1.5,
              }}>· {pt}</p>
            ))}
          </div>
        )}
      </div>

      {/* 추천 */}
      {viral.recommendation && (
        <div style={{
          marginTop: 12, padding: '12px 14px', borderRadius: 10,
          background: `${gradeColor}11`, border: `1px solid ${gradeColor}33`,
        }}>
          <p style={{
            fontSize: 10, color: gradeColor,
            fontFamily: "'Space Mono', monospace", marginBottom: 6,
          }}>💡 RECOMMENDATION</p>
          <p style={{ fontSize: 13, color: '#c4cfe0', lineHeight: 1.6 }}>
            {viral.recommendation}
          </p>
        </div>
      )}
    </div>
  );
}

// ─── 트렌드 탭 ───────────────────────────────────────────
function TrendTab() {
  const [trend,        setTrend]        = useState(null);
  const [trendLoading, setTrendLoading] = useState(false);
  const [trendError,   setTrendError]   = useState('');

  useEffect(() => {
    loadTrend();
  }, []);

  const loadTrend = async () => {
    setTrendLoading(true);
    setTrendError('');
    try {
      const res = await axios.get(`${API_BASE}/api/trend`, { timeout: 10000 });
      setTrend(res.data);
    } catch (e) {
      setTrendError('트렌드 데이터를 불러오지 못했습니다. 서버를 확인해주세요.');
    } finally {
      setTrendLoading(false);
    }
  };

  if (trendLoading) {
    return (
      <div style={{ textAlign: 'center', padding: '60px 0' }}>
        <div style={{
          width: 48, height: 48,
          border: '3px solid #1e2d45',
          borderTop: '3px solid #00f5c4',
          borderRadius: '50%',
          margin: '0 auto 20px',
          animation: 'spin 1s linear infinite',
        }} />
        <p style={{ color: '#8fa0bc', fontFamily: "'Space Mono', monospace", fontSize: 13 }}>
          트렌드 데이터 로딩 중...
        </p>
      </div>
    );
  }

  if (trendError) {
    return (
      <div style={{ textAlign: 'center', padding: '60px 0' }}>
        <p style={{ color: '#ff4d6d', fontFamily: "'Space Mono', monospace", fontSize: 13 }}>⚠ {trendError}</p>
        <button onClick={loadTrend} style={{
          marginTop: 16, background: '#1e2d45', border: 'none',
          borderRadius: 8, padding: '10px 20px', color: '#8fa0bc',
          fontSize: 13, cursor: 'pointer', fontFamily: "'Syne', sans-serif",
        }}>다시 시도</button>
      </div>
    );
  }

  if (!trend) return null;

  // 등급 분포 차트 데이터
  const gradeData = trend.grade_distribution
    ? Object.entries(trend.grade_distribution)
        .sort((a, b) => ['S','A','B','C','D'].indexOf(a[0]) - ['S','A','B','C','D'].indexOf(b[0]))
        .map(([grade, pct]) => ({
          grade,
          value: Math.round(pct * 100),
          fill: GRADE_COLORS[grade] || '#5a6a84',
        }))
    : [];

  // 감정 분포 차트 데이터
  const emotionData = trend.emotion_distribution
    ? Object.entries(trend.emotion_distribution)
        .map(([name, pct], i) => ({
          name,
          value: Math.round(pct * 100),
          fill: VIBE_COLORS[i % VIBE_COLORS.length],
        }))
    : [];

  return (
    <div style={{ animation: 'fadeIn 0.4s ease' }}>

      {/* 요약 통계 */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
        gap: 16, marginBottom: 32,
      }}>
        {[
          { label: 'TOTAL ANALYZED', value: trend.total_analyzed,            color: '#00f5c4' },
          { label: 'AVG VIRAL SCORE', value: trend.avg_viral_score?.toFixed(1), color: '#7b61ff' },
          { label: 'AVG VALENCE',    value: trend.avg_valence?.toFixed(2),    color: '#ffd166' },
        ].map(item => (
          <div key={item.label} className="card-hover" style={{
            background: '#0e1420', border: '1px solid #1e2d45',
            borderRadius: 12, padding: '20px 24px', textAlign: 'center',
          }}>
            <p style={{
              fontSize: 10, color: '#5a6a84',
              fontFamily: "'Space Mono', monospace", marginBottom: 8,
            }}>{item.label}</p>
            <p style={{ fontSize: 28, fontWeight: 800, color: item.color }}>
              {item.value ?? '-'}
            </p>
          </div>
        ))}
      </div>

      {/* 등급 분포 + 감정 분포 */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 32 }}>

        {/* 등급 분포 */}
        <div className="card-hover" style={{
          background: '#0e1420', border: '1px solid #1e2d45',
          borderRadius: 16, padding: 24,
        }}>
          <p style={{
            fontSize: 11, color: '#5a6a84',
            fontFamily: "'Space Mono', monospace", marginBottom: 4,
          }}>GRADE DISTRIBUTION</p>
          <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 20 }}>등급 분포</p>
          {gradeData.length > 0 ? (
            <ResponsiveContainer width="100%" height={160}>
              <BarChart data={gradeData} margin={{ top: 0, right: 10, bottom: 0, left: -10 }}>
                <XAxis dataKey="grade" tick={{ fill: '#8fa0bc', fontSize: 12, fontFamily: 'Space Mono' }} axisLine={false} tickLine={false} />
                <YAxis hide />
                <Tooltip
                  cursor={{ fill: 'rgba(255,255,255,0.03)' }}
                  content={({ active, payload }) => {
                    if (!active || !payload?.length) return null;
                    const d = payload[0].payload;
                    return (
                      <div style={{
                        background: '#0e1420', border: '1px solid #1e2d45',
                        borderRadius: 8, padding: '8px 12px',
                        fontFamily: "'Space Mono', monospace", fontSize: 12,
                      }}>
                        <p style={{ color: d.fill }}>Grade {d.grade}: {d.value}%</p>
                      </div>
                    );
                  }}
                />
                <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                  {gradeData.map((entry, i) => (
                    <Cell key={i} fill={entry.fill} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <p style={{ color: '#5a6a84', fontSize: 13, fontFamily: "'Space Mono', monospace" }}>데이터 없음</p>
          )}
        </div>

        {/* 감정 분포 */}
        <div className="card-hover" style={{
          background: '#0e1420', border: '1px solid #1e2d45',
          borderRadius: 16, padding: 24,
        }}>
          <p style={{
            fontSize: 11, color: '#5a6a84',
            fontFamily: "'Space Mono', monospace", marginBottom: 4,
          }}>EMOTION DISTRIBUTION</p>
          <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 20 }}>감정 분포</p>
          {emotionData.map(e => (
            <div key={e.name} style={{ marginBottom: 8 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                <span style={{ fontSize: 12, color: e.fill, fontFamily: "'Space Mono', monospace" }}>{e.name}</span>
                <span style={{ fontSize: 12, color: '#8fa0bc', fontFamily: "'Space Mono', monospace" }}>{e.value}%</span>
              </div>
              <div style={{ height: 4, background: '#1e2d45', borderRadius: 2, overflow: 'hidden' }}>
                <div style={{
                  height: '100%', width: `${e.value}%`, background: e.fill,
                  borderRadius: 2, transition: 'width 1s ease',
                }} />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Top 바이럴 영상 */}
      {trend.top_viral && trend.top_viral.length > 0 && (
        <div className="card-hover" style={{
          background: '#0e1420', border: '1px solid #1e2d45',
          borderRadius: 16, padding: 24, marginBottom: 32,
        }}>
          <p style={{
            fontSize: 11, color: '#5a6a84',
            fontFamily: "'Space Mono', monospace", marginBottom: 4,
          }}>TOP VIRAL</p>
          <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 20 }}>바이럴 상위 영상</p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {trend.top_viral.map((v, i) => {
              const gc = GRADE_COLORS[v.grade] || '#5a6a84';
              return (
                <div key={i} style={{
                  display: 'flex', alignItems: 'center', gap: 14,
                  background: '#151c2c', borderRadius: 10, padding: '12px 16px',
                }}>
                  <span style={{
                    fontSize: 14, fontWeight: 800, color: gc, width: 20,
                    fontFamily: "'Space Mono', monospace", flexShrink: 0,
                  }}>#{i + 1}</span>
                  {v.thumbnail_url && (
                    <img src={v.thumbnail_url} alt="" style={{
                      width: 64, borderRadius: 6, flexShrink: 0,
                      border: '1px solid #1e2d45',
                    }} />
                  )}
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <p style={{
                      fontSize: 13, fontWeight: 700, color: '#e8edf5',
                      marginBottom: 3, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                    }}>{v.title || '제목 없음'}</p>
                    <p style={{
                      fontSize: 11, color: '#5a6a84',
                      fontFamily: "'Space Mono', monospace",
                    }}>{v.channel} · {fmtNum(v.view_count)} views · {v.fused_emotion}</p>
                  </div>
                  <div style={{ textAlign: 'right', flexShrink: 0 }}>
                    <span style={{
                      fontSize: 13, fontWeight: 800, color: gc,
                      fontFamily: "'Space Mono', monospace",
                    }}>{v.grade}</span>
                    <p style={{
                      fontSize: 11, color: '#8fa0bc',
                      fontFamily: "'Space Mono', monospace",
                    }}>{v.viral_score?.toFixed(1)}</p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* 최근 분석 영상 */}
      {trend.recent_videos && trend.recent_videos.length > 0 && (
        <div className="card-hover" style={{
          background: '#0e1420', border: '1px solid #1e2d45',
          borderRadius: 16, padding: 24,
        }}>
          <p style={{
            fontSize: 11, color: '#5a6a84',
            fontFamily: "'Space Mono', monospace", marginBottom: 4,
          }}>RECENT ANALYSES</p>
          <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 20 }}>최근 분석 기록</p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {trend.recent_videos.map((v, i) => {
              const gc = GRADE_COLORS[v.grade] || '#5a6a84';
              const date = v.analyzed_at
                ? new Date(v.analyzed_at).toLocaleDateString('ko-KR')
                : '-';
              return (
                <div key={i} style={{
                  display: 'flex', alignItems: 'center', gap: 12,
                  padding: '10px 14px', borderRadius: 8,
                  background: '#151c2c',
                  borderLeft: `3px solid ${gc}`,
                }}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <p style={{
                      fontSize: 13, fontWeight: 600, color: '#e8edf5',
                      overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                    }}>{v.title || '제목 없음'}</p>
                    <p style={{
                      fontSize: 11, color: '#5a6a84',
                      fontFamily: "'Space Mono', monospace", marginTop: 2,
                    }}>{v.channel} · {date}</p>
                  </div>
                  <span style={{
                    fontSize: 12, fontWeight: 700, color: gc,
                    fontFamily: "'Space Mono', monospace",
                  }}>{v.grade} {v.viral_score?.toFixed(1)}</span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* 데이터 없음 */}
      {trend.total_analyzed === 0 && (
        <div style={{ textAlign: 'center', padding: '40px 0' }}>
          <p style={{ color: '#5a6a84', fontFamily: "'Space Mono', monospace", fontSize: 13 }}>
            아직 분석된 영상이 없습니다.<br />
            먼저 영상을 분석해보세요!
          </p>
        </div>
      )}
    </div>
  );
}

// ─── 타임라인 상세 페이지 ────────────────────────────────
function TimelinePage({ timeline, onBack }) {
  const [selectedIdx, setSelectedIdx] = useState(0);
  const selected = timeline[selectedIdx] || {};
  const chartRef = React.useRef(null);

  const chartData = timeline.map((t, i) => ({
    time:        parseFloat((t.timestamp || 0).toFixed(1)),
    '얼굴 감정':  typeof t.face_valence  === 'number' ? t.face_valence  : null,
    '음성 감정':  typeof t.audio_valence === 'number' ? t.audio_valence : null,
    '음성 에너지': typeof t.audio_energy  === 'number' ? t.audio_energy  : null,
  }));

  // 마우스 X 좌표 → 가장 가까운 타임라인 인덱스 계산
  const handleChartMouseEvent = (e) => {
    if (!chartRef.current) return;
    const rect = chartRef.current.getBoundingClientRect();
    // Recharts 차트 내부 여백 (margin left=40, right=10 기준)
    const marginLeft = 40;
    const marginRight = 10;
    const chartWidth = rect.width - marginLeft - marginRight;
    const mouseX = (e.clientX - rect.left - marginLeft);
    if (mouseX < 0 || mouseX > chartWidth) return;

    const ratio = mouseX / chartWidth;
    const idx = Math.round(ratio * (timeline.length - 1));
    const clampedIdx = Math.max(0, Math.min(timeline.length - 1, idx));
    setSelectedIdx(clampedIdx);
  };

  return (
    <div style={{ position: 'relative', zIndex: 1, minHeight: '100vh' }}>
      {/* 헤더 */}
      <header style={{
        borderBottom: '1px solid #1e2d45', padding: '16px 32px',
        display: 'flex', alignItems: 'center', gap: 16,
        background: 'rgba(8,11,18,0.9)', backdropFilter: 'blur(12px)',
        position: 'sticky', top: 0, zIndex: 100,
      }}>
        <button onClick={onBack} style={{
          background: '#1e2d45', border: 'none', borderRadius: 8,
          padding: '8px 16px', color: '#8fa0bc', fontSize: 13,
          cursor: 'pointer', fontFamily: "'Space Mono', monospace",
        }}>← 돌아가기</button>
        <div>
          <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>
            TIMELINE VIEWER
          </p>
          <p style={{ fontSize: 16, fontWeight: 700 }}>감정 타임라인 상세 검증</p>
        </div>
        <div style={{ marginLeft: 'auto' }}>
          <span style={{
            fontSize: 11, color: '#5a6a84',
            fontFamily: "'Space Mono', monospace",
          }}>총 {timeline.length}개 구간</span>
        </div>
      </header>

      <main style={{ padding: '32px', maxWidth: 1200, margin: '0 auto' }}>

        {/* 상단: 차트 + 프레임 나란히 */}
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 320px',
          gap: 24, marginBottom: 32,
          alignItems: 'start',
        }}>
          {/* 타임라인 차트 */}
          <div style={{
            background: '#0e1420', border: '1px solid #1e2d45',
            borderRadius: 16, padding: 24,
          }}>
            <p style={{
              fontSize: 11, color: '#5a6a84',
              fontFamily: "'Space Mono', monospace", marginBottom: 4,
            }}>EMOTION TIMELINE</p>
            <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 6 }}>
              초 단위 감정 흐름
            </p>
            <p style={{ fontSize: 12, color: '#5a6a84', fontFamily: "'Space Mono', monospace", marginBottom: 20 }}>
              그래프 위에 마우스를 올리거나 클릭하면 오른쪽에 해당 시점 영상 장면이 표시됩니다
            </p>
            {/* 차트 이벤트를 div에 직접 걸어서 확실하게 감지 */}
            <div
              ref={chartRef}
              onMouseMove={handleChartMouseEvent}
              onClick={handleChartMouseEvent}
              style={{ cursor: 'crosshair', userSelect: 'none' }}
            >
            <ResponsiveContainer width="100%" height={280}>
              <LineChart
                data={chartData}
                margin={{ top: 5, right: 10, bottom: 5, left: 30 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="#1e2d45" />
                <XAxis
                  dataKey="time" type="number"
                  domain={['dataMin', 'dataMax']}
                  tickFormatter={v => `${Number(v).toFixed(0)}s`}
                  stroke="#2a3a55"
                  tick={{ fill: '#5a6a84', fontSize: 11, fontFamily: 'Space Mono' }}
                />
                <YAxis domain={[-1, 1]} stroke="#2a3a55"
                  tick={{ fill: '#5a6a84', fontSize: 11, fontFamily: 'Space Mono' }} />
                <Tooltip content={<CustomTooltip />} />
                <Legend wrapperStyle={{ fontSize: 12, fontFamily: 'Space Mono', color: '#8fa0bc' }} />
                <ReferenceLine y={0} stroke="#2a3a55" strokeDasharray="4 4" />
                <ReferenceLine
                  x={chartData[selectedIdx]?.time}
                  stroke="#00f5c4"
                  strokeWidth={2}
                />
                <Line type="monotone" dataKey="얼굴 감정"   stroke="#00f5c4" dot={false} activeDot={{ r: 5, fill: '#00f5c4' }} strokeWidth={2} connectNulls />
                <Line type="monotone" dataKey="음성 감정"   stroke="#7b61ff" dot={false} activeDot={false} strokeWidth={2} connectNulls />
                <Line type="monotone" dataKey="음성 에너지" stroke="#ffd166" dot={false} activeDot={false} strokeWidth={1.5} strokeDasharray="4 2" connectNulls />
              </LineChart>
            </ResponsiveContainer>
            </div>
          </div>

          {/* 프레임 뷰어 */}
          <div style={{
            background: '#0e1420', border: '2px solid #00f5c4',
            borderRadius: 16, padding: 20,
            position: 'sticky', top: 100,
          }}>
            <p style={{
              fontSize: 11, color: '#00f5c4',
              fontFamily: "'Space Mono', monospace", marginBottom: 4,
            }}>FRAME VIEWER</p>
            <p style={{ fontSize: 15, fontWeight: 700, marginBottom: 16 }}>
              {(selected.timestamp || 0).toFixed(1)}s 시점
            </p>

            {/* 프레임 이미지 */}
            {selected.frame_url ? (
              <img
                key={selected.frame_url}
                src={`${API_BASE}${selected.frame_url}`}
                alt={`frame at ${selected.timestamp}s`}
                style={{
                  width: '100%', borderRadius: 10,
                  border: '1px solid #1e2d45',
                  display: 'block', marginBottom: 16,
                }}
              />
            ) : (
              <div style={{
                width: '100%', height: 160,
                background: '#151c2c', borderRadius: 10,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: '#5a6a84', fontSize: 12, marginBottom: 16,
                fontFamily: "'Space Mono', monospace",
                flexDirection: 'column', gap: 8,
              }}>
                <span style={{ fontSize: 24 }}>🖼</span>
                <span>이미지 없음</span>
              </div>
            )}

            {/* 감정 정보 */}
            {[
              { label: '얼굴 감정', value: EMOTION_KO[selected.face_emotion] || selected.face_emotion || '-', score: selected.face_valence, color: '#00f5c4' },
              { label: '음성 감정', value: EMOTION_KO[selected.audio_emotion] || selected.audio_emotion || '-', score: selected.audio_valence, color: '#7b61ff' },
              { label: '음성 에너지', value: '', score: selected.audio_energy, color: '#ffd166' },
            ].map(item => (
              <div key={item.label} style={{ marginBottom: 12 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                  <span style={{ fontSize: 11, color: item.color, fontFamily: "'Space Mono', monospace" }}>
                    {item.label}
                  </span>
                  <span style={{ fontSize: 11, color: '#8fa0bc', fontFamily: "'Space Mono', monospace" }}>
                    {item.value} {item.score != null ? `(${item.score.toFixed(2)})` : ''}
                  </span>
                </div>
                <div style={{ height: 4, background: '#1e2d45', borderRadius: 2, overflow: 'hidden' }}>
                  <div style={{
                    height: '100%',
                    width: `${Math.round(((item.score ?? 0) + 1) / 2 * 100)}%`,
                    background: item.color, borderRadius: 2,
                    boxShadow: `0 0 6px ${item.color}66`,
                    transition: 'width 0.3s ease',
                  }} />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* 하단: 전체 프레임 썸네일 스크롤 */}
        <div style={{
          background: '#0e1420', border: '1px solid #1e2d45',
          borderRadius: 16, padding: 24,
        }}>
          <p style={{
            fontSize: 11, color: '#5a6a84',
            fontFamily: "'Space Mono', monospace", marginBottom: 4,
          }}>ALL FRAMES</p>
          <p style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>
            전체 프레임 목록 — 클릭하면 선택됩니다
          </p>
          <div style={{
            display: 'flex', gap: 8, overflowX: 'auto',
            paddingBottom: 12,
          }}>
            {timeline.map((t, i) => {
              const isSelected = i === selectedIdx;
              const emotionColor = EMOTION_COLORS[t.face_emotion] || '#5a6a84';
              return (
                <div
                  key={i}
                  onClick={() => setSelectedIdx(i)}
                  style={{
                    flexShrink: 0, cursor: 'pointer',
                    border: `2px solid ${isSelected ? '#00f5c4' : '#1e2d45'}`,
                    borderRadius: 8, overflow: 'hidden',
                    width: 80,
                    transition: 'border-color 0.15s ease',
                    background: '#151c2c',
                  }}
                >
                  {t.frame_url ? (
                    <img
                      src={`${API_BASE}${t.frame_url}`}
                      alt={`${t.timestamp}s`}
                      style={{ width: '100%', display: 'block', height: 60, objectFit: 'cover' }}
                    />
                  ) : (
                    <div style={{ width: '100%', height: 60, background: '#1e2d45',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontSize: 16 }}>🖼</div>
                  )}
                  <div style={{ padding: '4px 6px' }}>
                    <p style={{
                      fontSize: 9, color: '#5a6a84',
                      fontFamily: "'Space Mono', monospace",
                    }}>{(t.timestamp || 0).toFixed(1)}s</p>
                    <p style={{
                      fontSize: 9, color: emotionColor,
                      fontFamily: "'Space Mono', monospace",
                      overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                    }}>{EMOTION_KO[t.face_emotion] || t.face_emotion || '-'}</p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

      </main>
    </div>
  );
}

// ─── 메인 앱 ─────────────────────────────────────────────
export default function App() {
  const [tab,          setTab]          = useState('analyze');
  const [url,          setUrl]          = useState('');
  const [loading,      setLoading]      = useState(false);
  const [result,       setResult]       = useState(null);
  const [error,        setError]        = useState('');
  const [coachLoading, setCoachLoading] = useState(false);
  const [coachFeedback,setCoachFeedback]= useState('');
  const [selectedFrame,setSelectedFrame]= useState(null);
  const [showTimeline, setShowTimeline] = useState(false); // 타임라인 상세 페이지

  // 타임라인 상세 페이지로 이동
  if (showTimeline && result?.emotion_timeline?.length > 0) {
    return (
      <TimelinePage
        timeline={result.emotion_timeline}
        onBack={() => setShowTimeline(false)}
      />
    );
  }

  // ── 영상 분석 요청 ──────────────────────────────────────
  const handleAnalyze = async () => {
    if (!url.trim()) { setError('YouTube URL을 입력해주세요.'); return; }
    setLoading(true);
    setError('');
    setResult(null);
    setCoachFeedback('');
    setSelectedFrame(null);
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
    time:       typeof t.timestamp    === 'number' ? parseFloat(t.timestamp.toFixed(1))    : t.timestamp,
    '얼굴 감정': typeof t.face_valence  === 'number' ? t.face_valence  : null,
    '음성 감정': typeof t.audio_valence === 'number' ? t.audio_valence : null,
    '음성 에너지': typeof t.audio_energy  === 'number' ? t.audio_energy  : null,
    frame_url:   t.frame_url || '',
    face_emotion: t.face_emotion || '',
    audio_emotion: t.audio_emotion || '',
  }));

  const dominantEmotion = result?.face_summary?.peak_emotion?.emotion;
  const dominantColor   = EMOTION_COLORS[dominantEmotion] || '#00f5c4';

  const audioStats = result ? [
    {
      label: 'DOMINANT',
      value: EMOTION_KO[result.audio_summary?.dominant_emotion] || result.audio_summary?.dominant_emotion,
    },
    {
      label: 'TEMPO',
      value: result.audio_summary?.tempo != null ? `${result.audio_summary.tempo.toFixed(0)} BPM` : '-',
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
          <h1 style={{ fontSize: 20, fontWeight: 800, letterSpacing: '-0.5px' }}>VibeView</h1>
          <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>
            감정이 조회수를 만든다
          </p>
        </div>

        {/* 탭 버튼 */}
        <div style={{ marginLeft: 32, display: 'flex', gap: 4 }}>
          {[
            { key: 'analyze', label: '🔍 분석' },
            { key: 'trend',   label: '📊 트렌드' },
          ].map(t => (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              style={{
                background: tab === t.key ? 'rgba(0,245,196,0.12)' : 'transparent',
                border: tab === t.key ? '1px solid rgba(0,245,196,0.3)' : '1px solid transparent',
                borderRadius: 8, padding: '6px 16px',
                color: tab === t.key ? '#00f5c4' : '#5a6a84',
                fontSize: 13, fontWeight: 600, cursor: 'pointer',
                fontFamily: "'Syne', sans-serif",
                transition: 'all 0.15s ease',
              }}
            >{t.label}</button>
          ))}
        </div>

        <div className="tag-group" style={{ marginLeft: 'auto', display: 'flex', gap: 8 }}>
          {['FACE', 'AUDIO', 'SCENE', 'VIRAL', 'AI COACH'].map(tag => (
            <span key={tag} style={{
              fontSize: 10, padding: '3px 8px', borderRadius: 4,
              border: '1px solid #1e2d45', color: '#5a6a84',
              fontFamily: "'Space Mono', monospace",
            }}>{tag}</span>
          ))}
        </div>
      </header>

      {/* ── 트렌드 탭 ────────────────────────────────────── */}
      {tab === 'trend' && (
        <main style={{ padding: '40px', maxWidth: 1100, margin: '0 auto' }}>
          <section style={{ marginBottom: 40 }}>
            <p style={{
              fontSize: 11, color: '#00f5c4',
              fontFamily: "'Space Mono', monospace",
              letterSpacing: 2, marginBottom: 12,
            }}>{'// TREND DATA'}</p>
            <h2 style={{ fontSize: 32, fontWeight: 800, marginBottom: 8, lineHeight: 1.2 }}>
              분석 <span style={{ color: '#00f5c4' }}>트렌드</span>
            </h2>
            <p style={{ fontSize: 13, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>
              DB에 저장된 전체 분석 결과 통계
            </p>
          </section>
          <TrendTab />
        </main>
      )}

      {/* ── 분석 탭 ─────────────────────────────────────── */}
      {tab === 'analyze' && (
        <main style={{ padding: '40px', maxWidth: 1100, margin: '0 auto' }}>

          {/* URL 입력 섹션 */}
          <section style={{ marginBottom: 48 }}>
            <p style={{
              fontSize: 11, color: '#00f5c4',
              fontFamily: "'Space Mono', monospace",
              letterSpacing: 2, marginBottom: 12,
            }}>{'// ANALYZE VIDEO'}</p>

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

          {/* 로딩 상태 */}
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
              <p style={{ color: '#8fa0bc', fontFamily: "'Space Mono', monospace", fontSize: 13 }}>
                영상 다운로드 → 얼굴 분석 → 음성 분석 → 장면 분석 중...
              </p>
              <p style={{ color: '#5a6a84', fontSize: 11, marginTop: 8, fontFamily: "'Space Mono', monospace" }}>
                영상 길이에 따라 1~3분 소요될 수 있습니다
              </p>
            </div>
          )}

          {/* ── 분석 결과 ──────────────────────────────────── */}
          {result && !loading && (
            <div style={{ animation: 'fadeIn 0.5s ease' }}>

              {/* YouTube 통계 카드 */}
              <YouTubeStatsCard stats={result.youtube_stats} />

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
                      <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>FACE ANALYSIS</p>
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
                      <p style={{ fontSize: 11, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>AUDIO ANALYSIS</p>
                      <p style={{ fontSize: 16, fontWeight: 700 }}>음성 감정 분석</p>
                    </div>
                    <div style={{ marginLeft: 'auto', textAlign: 'right' }}>
                      <p style={{ fontSize: 10, color: '#5a6a84', fontFamily: "'Space Mono', monospace" }}>VALENCE</p>
                      <p style={{ fontSize: 20, fontWeight: 800, color: '#7b61ff' }}>
                        {result.audio_summary?.avg_valence?.toFixed(2) ?? '-'}
                      </p>
                    </div>
                  </div>

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

              {/* 장면 분석 + 융합 결과 카드 */}
              <div className="analysis-grid" style={{
                display: 'grid', gridTemplateColumns: '1fr 1fr',
                gap: 20, marginBottom: 32,
              }}>
                <SceneCard scene={result.scene_summary} />
                <FusionCard fusion={result.fusion_result} />
              </div>

              {/* 바이럴 점수 카드 */}
              <div style={{ marginBottom: 32 }}>
                <ViralCard viral={result.viral_result} />
              </div>

              {/* 감정 타임라인 차트 */}
              <div className="card-hover" style={{
                background: '#0e1420', border: '1px solid #1e2d45',
                borderRadius: 16, padding: 24, marginBottom: 32,
              }}>
                <div style={{
                  display: 'flex', alignItems: 'flex-start',
                  justifyContent: 'space-between', marginBottom: 20,
                }}>
                  <div>
                    <p style={{
                      fontSize: 11, color: '#5a6a84',
                      fontFamily: "'Space Mono', monospace", marginBottom: 4,
                    }}>EMOTION TIMELINE</p>
                    <p style={{ fontSize: 18, fontWeight: 700 }}>초 단위 감정 타임라인</p>
                  </div>
                  {result?.emotion_timeline?.length > 0 && (
                    <button
                      onClick={() => setShowTimeline(true)}
                      style={{
                        background: 'linear-gradient(135deg, #00f5c4, #7b61ff)',
                        border: 'none', borderRadius: 10, padding: '10px 20px',
                        color: '#080b12', fontSize: 13, fontWeight: 700,
                        cursor: 'pointer', fontFamily: "'Syne', sans-serif",
                        flexShrink: 0,
                      }}
                    >
                      🔍 장면 검증 보기
                    </button>
                  )}
                </div>

                <ResponsiveContainer width="100%" height={260}>
                  <LineChart data={chartData} margin={{ top: 5, right: 20, bottom: 5, left: -10 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#1e2d45" />
                    <XAxis
                      dataKey="time" type="number"
                      domain={['dataMin', 'dataMax']}
                      tickFormatter={v => `${Number(v).toFixed(0)}s`}
                      stroke="#2a3a55"
                      tick={{ fill: '#5a6a84', fontSize: 11, fontFamily: 'Space Mono' }}
                    />
                    <YAxis domain={[-1, 1]} stroke="#2a3a55"
                      tick={{ fill: '#5a6a84', fontSize: 11, fontFamily: 'Space Mono' }} />
                    <Tooltip content={<CustomTooltip />} />
                    <Legend wrapperStyle={{ fontSize: 12, fontFamily: 'Space Mono', color: '#8fa0bc' }} />
                    <ReferenceLine y={0} stroke="#2a3a55" strokeDasharray="4 4" />
                    <Line type="monotone" dataKey="얼굴 감정"   stroke="#00f5c4" dot={false} strokeWidth={2}   connectNulls />
                    <Line type="monotone" dataKey="음성 감정"   stroke="#7b61ff" dot={false} strokeWidth={2}   connectNulls />
                    <Line type="monotone" dataKey="음성 에너지" stroke="#ffd166" dot={false} strokeWidth={1.5} strokeDasharray="4 2" connectNulls />
                  </LineChart>
                </ResponsiveContainer>

                <p style={{
                  marginTop: 12, textAlign: 'center',
                  color: '#2a3a55', fontSize: 11,
                  fontFamily: "'Space Mono', monospace",
                }}>
                  🔍 장면 검증 보기 버튼을 눌러 각 시점의 영상 장면을 확인하세요
                </p>
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

          {/* 초기 안내 화면 */}
          {!result && !loading && (
            <div style={{ textAlign: 'center', padding: '60px 0' }}>
              <div style={{ fontSize: 64, marginBottom: 20 }}>👁‍🗨</div>
              <p style={{
                color: '#5a6a84', fontSize: 14,
                fontFamily: "'Space Mono', monospace",
              }}>
                YouTube Shorts URL을 입력하면<br />
                얼굴 + 음성 + 장면 감정을 분석합니다
              </p>
            </div>
          )}

        </main>
      )}
    </div>
  );
}
