import React from "react";
import {
  AbsoluteFill,
  Sequence,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
} from "remotion";

export const WALKTHROUGH_FPS = 30;
export const STEP_FRAMES = 72;
export const WALKTHROUGH_TOTAL_FRAMES = STEP_FRAMES * 6;

export type WalkthroughCompositionProps = {
  stepTitles: string[];
  stepBodies: string[];
};

const cream = "#f5f0e8";
const forest = "#2a6049";
const forestTint = "#ebf3ee";
const parchment = "#e8e2d8";
const charcoal = "#1e1c18";
const dusk = "#4a4640";
const white = "#ffffff";

function smoothstep(t: number) {
  const x = Math.max(0, Math.min(1, t));
  return x * x * (3 - 2 * x);
}

function Cursor({ x, y }: { x: number; y: number }) {
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width: 22,
        height: 22,
        marginLeft: -5,
        marginTop: -5,
        borderRadius: "50%",
        border: "3px solid #fff",
        boxShadow: "0 2px 14px rgba(0,0,0,0.35)",
        background: "rgba(42,96,73,0.32)",
        zIndex: 30,
      }}
    />
  );
}

function Caption({
  title,
  body,
  frame,
}: {
  title: string;
  body: string;
  frame: number;
}) {
  const op = interpolate(frame, [4, 18], [0, 1], { extrapolateRight: "clamp" });
  return (
    <div
      style={{
        position: "absolute",
        left: 28,
        right: 28,
        bottom: 20,
        maxWidth: 560,
        padding: "16px 18px",
        background: white,
        border: `1px solid ${parchment}`,
        borderRadius: 14,
        boxShadow: "0 12px 36px rgba(15,18,16,0.12)",
        opacity: op,
        zIndex: 25,
      }}
    >
      <div
        style={{
          fontSize: 11,
          fontWeight: 700,
          letterSpacing: "0.06em",
          textTransform: "uppercase",
          color: forest,
          marginBottom: 8,
        }}
      >
        WanderMood
      </div>
      <div
        style={{
          fontSize: 19,
          fontWeight: 650,
          color: charcoal,
          lineHeight: 1.25,
          marginBottom: 8,
          fontFamily: "Georgia, ui-serif, serif",
        }}
      >
        {title}
      </div>
      <div
        style={{
          fontSize: 14,
          lineHeight: 1.45,
          color: dusk,
          maxHeight: 120,
          overflow: "hidden",
        }}
      >
        {body}
      </div>
    </div>
  );
}

function useCursorMotion(
  frame: number,
  start: { x: number; y: number },
  end: { x: number; y: number },
) {
  const tMove = smoothstep(interpolate(frame, [0, 34], [0, 1], { extrapolateRight: "clamp" }));
  return {
    x: start.x + (end.x - start.x) * tMove,
    y: start.y + (end.y - start.y) * tMove,
  };
}

function StepScene({
  index,
  title,
  body,
}: {
  index: number;
  title: string;
  body: string;
}) {
  const frame = useCurrentFrame();
  const { width, height } = useVideoConfig();
  const w = width;
  const h = height;

  const start = { x: w * 0.12, y: h * 0.88 };
  const targets: { x: number; y: number }[] = [
    { x: w * 0.38, y: h * 0.068 },
    { x: w * 0.26, y: h * 0.44 },
    { x: w * 0.22, y: h * 0.48 },
    { x: w * 0.5, y: h * 0.46 },
    { x: w * 0.74, y: h * 0.5 },
    { x: w * 0.48, y: h * 0.58 },
  ];
  const end = targets[index] ?? targets[0];
  const { x: cx, y: cy } = useCursorMotion(frame, start, end);

  const ringOpacity = interpolate(frame, [10, 26], [0, 1], { extrapolateRight: "clamp" });
  const dim = 0.42 * ringOpacity;

  const rings: { x: number; y: number; rw: number; rh: number }[] = [
    { x: w * 0.14, y: h * 0.02, rw: w * 0.72, rh: h * 0.11 },
    { x: w * 0.06, y: h * 0.34, rw: w * 0.38, rh: h * 0.2 },
    { x: w * 0.06, y: h * 0.34, rw: w * 0.26, rh: h * 0.36 },
    { x: w * 0.2, y: h * 0.34, rw: w * 0.6, rh: h * 0.38 },
    { x: w * 0.52, y: h * 0.32, rw: w * 0.42, rh: h * 0.42 },
    { x: w * 0.2, y: h * 0.42, rw: w * 0.6, rh: h * 0.28 },
  ];
  const ring = rings[index] ?? rings[0];

  return (
    <>
      <AbsoluteFill style={{ zIndex: 0 }}>
        {index === 0 && <NavMock w={w} h={h} />}
        {index === 1 && <HeroMock w={w} h={h} />}
        {index === 2 && <HowMock w={w} h={h} />}
        {index === 3 && <MoodsMock w={w} h={h} />}
        {index === 4 && <B2bMock w={w} h={h} />}
        {index === 5 && <DownloadMock w={w} h={h} />}
      </AbsoluteFill>

      <AbsoluteFill style={{ zIndex: 5, pointerEvents: "none" }}>
        <div
          style={{
            position: "absolute",
            left: ring.x,
            top: ring.y,
            width: ring.rw,
            height: ring.rh,
            borderRadius: 14,
            border: `${3 * ringOpacity}px solid ${forest}`,
            boxShadow: ringOpacity > 0 ? `0 0 0 ${Math.ceil(w + h)}px rgba(15,18,16,${dim})` : "none",
          }}
        />
      </AbsoluteFill>

      <Cursor x={cx} y={cy} />
      <Caption title={title} body={body} frame={frame} />
    </>
  );
}

function NavMock({ w, h }: { w: number; h: number }) {
  return (
    <AbsoluteFill style={{ backgroundColor: cream }}>
      <div
        style={{
          height: h * 0.11,
          background: "rgba(245,240,232,0.96)",
          borderBottom: `1px solid rgba(30,28,24,0.08)`,
          display: "flex",
          alignItems: "center",
          padding: `0 ${w * 0.04}px`,
          gap: w * 0.02,
        }}
      >
        <div style={{ width: 36, height: 36, background: forest, borderRadius: 10 }} />
        <div style={{ fontSize: 20, fontWeight: 600, color: forest, fontFamily: "Georgia, serif" }}>WanderMood</div>
        <div style={{ flex: 1 }} />
        <div style={{ display: "flex", gap: 10, fontSize: 14, color: dusk }}>
          <span>···</span>
          <span>···</span>
          <span>···</span>
        </div>
        <div
          style={{
            padding: "8px 16px",
            background: forest,
            color: white,
            borderRadius: 999,
            fontSize: 13,
            fontWeight: 600,
          }}
        >
          ···
        </div>
      </div>
      <div style={{ padding: `${h * 0.08}px ${w * 0.06}px`, opacity: 0.35 }}>
        <div style={{ height: 14, width: "40%", background: parchment, borderRadius: 6, marginBottom: 16 }} />
        <div style={{ height: 32, width: "70%", background: parchment, borderRadius: 8, marginBottom: 10 }} />
        <div style={{ height: 32, width: "55%", background: parchment, borderRadius: 8 }} />
      </div>
    </AbsoluteFill>
  );
}

function HeroMock({ w, h }: { w: number; h: number }) {
  return (
    <AbsoluteFill style={{ backgroundColor: cream }}>
      <div style={{ display: "flex", padding: `${h * 0.08}px ${w * 0.06}px`, gap: w * 0.04 }}>
        <div style={{ flex: 1 }}>
          <div
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: 8,
              fontSize: 12,
              color: forest,
              marginBottom: 16,
            }}
          >
            <span style={{ width: 8, height: 8, borderRadius: 4, background: forest }} />
            ···
          </div>
          <div style={{ fontSize: 36, fontWeight: 600, color: charcoal, lineHeight: 1.1, fontFamily: "Georgia, serif" }}>
            ···
            <br />
            <em style={{ color: forest, fontStyle: "italic" }}>···</em>
            <br />
            ···
          </div>
          <div style={{ height: 12 }} />
          <div style={{ fontSize: 15, color: dusk, maxWidth: 420, lineHeight: 1.5 }}>···</div>
          <div style={{ display: "flex", gap: 12, marginTop: 24 }}>
            <div style={{ padding: "12px 20px", background: forest, color: white, borderRadius: 999, fontSize: 14 }}>···</div>
            <div
              style={{
                padding: "12px 20px",
                border: `1px solid ${parchment}`,
                borderRadius: 999,
                fontSize: 14,
                color: charcoal,
                background: white,
              }}
            >
              ···
            </div>
          </div>
        </div>
        <div
          style={{
            width: w * 0.28,
            height: h * 0.62,
            background: white,
            borderRadius: 36,
            border: `8px solid ${parchment}`,
            alignSelf: "center",
          }}
        />
      </div>
    </AbsoluteFill>
  );
}

function HowMock({ w, h }: { w: number; h: number }) {
  const card = (n: string) => (
    <div
      key={n}
      style={{
        flex: 1,
        background: white,
        borderRadius: 16,
        border: `1px solid ${parchment}`,
        padding: 18,
        minHeight: h * 0.22,
      }}
    >
      <div style={{ fontSize: 12, color: forest, fontWeight: 700, marginBottom: 8 }}>{n}</div>
      <div style={{ height: 10, width: "80%", background: forestTint, borderRadius: 4, marginBottom: 8 }} />
      <div style={{ height: 10, width: "60%", background: forestTint, borderRadius: 4 }} />
    </div>
  );
  return (
    <AbsoluteFill style={{ backgroundColor: cream, padding: `${h * 0.1}px ${w * 0.06}px` }}>
      <div style={{ fontSize: 13, color: forest, fontWeight: 600, marginBottom: 8 }}>···</div>
      <div style={{ fontSize: 28, fontWeight: 600, color: charcoal, marginBottom: 20, fontFamily: "Georgia, serif" }}>···</div>
      <div style={{ display: "flex", gap: 16 }}>{["01", "02", "03"].map(card)}</div>
    </AbsoluteFill>
  );
}

function MoodsMock({ w, h }: { w: number; h: number }) {
  const chips = Array.from({ length: 12 });
  return (
    <AbsoluteFill style={{ backgroundColor: cream, padding: `${h * 0.1}px ${w * 0.06}px` }}>
      <div style={{ fontSize: 28, fontWeight: 600, color: charcoal, marginBottom: 20, fontFamily: "Georgia, serif" }}>···</div>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4, 1fr)",
          gap: 12,
          maxWidth: w * 0.88,
        }}
      >
        {chips.map((_, i) => (
          <div
            key={i}
            style={{
              background: white,
              border: `1px solid ${parchment}`,
              borderRadius: 999,
              padding: "10px 14px",
              fontSize: 13,
              color: dusk,
              textAlign: "center",
            }}
          >
            ···
          </div>
        ))}
      </div>
    </AbsoluteFill>
  );
}

function B2bMock({ w, h }: { w: number; h: number }) {
  return (
    <AbsoluteFill style={{ backgroundColor: cream, padding: `${h * 0.1}px ${w * 0.06}px` }}>
      <div style={{ display: "flex", gap: w * 0.05 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, color: forest, marginBottom: 8 }}>···</div>
          <div style={{ fontSize: 26, fontWeight: 600, color: charcoal, fontFamily: "Georgia, serif", marginBottom: 12 }}>···</div>
          <div style={{ height: 10, width: "90%", background: parchment, borderRadius: 4, marginBottom: 8 }} />
          <div style={{ height: 10, width: "70%", background: parchment, borderRadius: 4 }} />
        </div>
        <div
          style={{
            width: w * 0.34,
            background: white,
            borderRadius: 20,
            border: `1px solid ${parchment}`,
            padding: 24,
          }}
        >
          <div style={{ fontSize: 32, fontWeight: 700, color: forest }}>···</div>
          <div style={{ height: 12 }} />
          <div style={{ height: 8, width: "100%", background: forestTint, borderRadius: 4, marginBottom: 6 }} />
          <div style={{ height: 8, width: "100%", background: forestTint, borderRadius: 4, marginBottom: 6 }} />
          <div style={{ height: 36, background: forest, borderRadius: 999, marginTop: 16 }} />
        </div>
      </div>
    </AbsoluteFill>
  );
}

function DownloadMock({ w, h }: { w: number; h: number }) {
  return (
    <AbsoluteFill
      style={{
        backgroundColor: cream,
        padding: `${h * 0.12}px ${w * 0.06}px`,
        alignItems: "center",
      }}
    >
      <div style={{ textAlign: "center", maxWidth: w * 0.75, margin: "0 auto" }}>
        <div style={{ fontSize: 13, color: forest, marginBottom: 10 }}>···</div>
        <div style={{ fontSize: 30, fontWeight: 600, color: charcoal, fontFamily: "Georgia, serif", marginBottom: 14 }}>···</div>
        <div style={{ display: "flex", gap: 14, justifyContent: "center", marginTop: 22 }}>
          <div style={{ padding: "12px 22px", background: forest, color: white, borderRadius: 999, fontSize: 14 }}>···</div>
          <div style={{ padding: "12px 22px", border: `1px solid ${parchment}`, borderRadius: 999, background: white, fontSize: 14 }}>
            ···
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
}

export const WalkthroughComposition: React.FC<WalkthroughCompositionProps> = ({ stepTitles, stepBodies }) => {
  if (stepTitles.length !== 6 || stepBodies.length !== 6) {
    return (
      <AbsoluteFill
        style={{
          backgroundColor: cream,
          justifyContent: "center",
          alignItems: "center",
          color: dusk,
          fontSize: 18,
        }}
      >
        Walkthrough: need 6 titles and 6 bodies
      </AbsoluteFill>
    );
  }

  return (
    <AbsoluteFill style={{ backgroundColor: cream, fontFamily: "ui-sans-serif, system-ui, sans-serif" }}>
      {stepTitles.map((_, i) => (
        <Sequence key={i} from={i * STEP_FRAMES} durationInFrames={STEP_FRAMES}>
          <StepScene index={i} title={stepTitles[i]} body={stepBodies[i]} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};
