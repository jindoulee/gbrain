// Channel-neutral contract. The agent CORE speaks only these types; each channel
// adapter (telegram today; whatsapp/slack/teams later) translates to/from its
// platform. Add a channel = write a new adapter against these types. The core
// and these contracts never change. This is the channel-agnostic seam.

export interface InboundMessage {
  channel: string; // "telegram" | future: "whatsapp" | "slack" | "sms" | ...
  userId: string;  // channel-native id; v1 maps this to a brain contact/alias
  text: string;
}

export interface Action {
  type: "approve" | "choose_another" | "award_override" | "detail" | "ask";
  rfp?: string;
  target?: string; // vendor slug
  reason?: string;
}

export interface ActionButton {
  label: string;
  action: Action;
  disabled?: boolean;
  disabledReason?: string;
}

export interface LeaderboardItem {
  rank: number;
  vendor: string;
  price: string;
  score?: number;
  recommended?: boolean;
  blockedReason?: string;
}

// Abstract artifacts. The adapter decides HOW to render each per channel
// (Telegram: text/PNG + inline keyboard; WhatsApp: image + <=3 buttons;
// SMS: text + reply-a-number; Slack: Block Kit; web: interactive page).
export type Artifact =
  | { kind: "text"; text: string; buttons?: ActionButton[] }
  | {
      kind: "leaderboard";
      title: string;
      subtitle?: string;
      items: LeaderboardItem[];
      recommendation: { target: string; summary: string };
      buttons: ActionButton[];
    }
  | { kind: "award"; title: string; lines: string[]; buttons?: ActionButton[] };
