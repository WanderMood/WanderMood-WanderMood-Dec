"use client";

import { Player } from "@remotion/player";
import {
  WalkthroughComposition,
  WALKTHROUGH_FPS,
  WALKTHROUGH_TOTAL_FRAMES,
} from "@/remotion/walkthrough-composition";
import type { WalkthroughCompositionProps } from "@/remotion/walkthrough-composition";

export function LandingWalkthroughPlayer(props: WalkthroughCompositionProps) {
  return (
    <Player
      component={WalkthroughComposition}
      inputProps={props}
      durationInFrames={WALKTHROUGH_TOTAL_FRAMES}
      compositionWidth={1280}
      compositionHeight={720}
      fps={WALKTHROUGH_FPS}
      controls
      acknowledgeRemotionLicense
      style={{
        width: "100%",
        maxWidth: 960,
        margin: "0 auto",
        borderRadius: 16,
        overflow: "hidden",
        boxShadow: "0 20px 50px rgba(15, 18, 16, 0.12)",
      }}
    />
  );
}
