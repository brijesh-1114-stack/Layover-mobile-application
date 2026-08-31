# Layover — Product Requirements Document

**Tagline:** Connect with people stuck in the same limbo, for as long as it lasts.

---

## 1. Overview

Layover is a mobile app for people who are temporarily stuck somewhere — airports, train stations, hospital waiting rooms, DMV/govt offices, jury duty, long queues — and want light, low-pressure connection with others in the same situation. Presence is ephemeral by design: you check in, you're visible for the duration of your wait, and you disappear the moment you leave.

**Core differentiator:** Unlike social or dating apps that try to keep users engaged indefinitely, Layover is honest about being temporary. No persistent profile-building, no follower counts, no long-term social graph — just presence, proximity, and a countdown.

---

## 2. Problem Statement

Waiting in transient spaces (airports, stations, waiting rooms) is universally experienced but socially "dead time." People are bored, sometimes anxious, often isolated — surrounded by others in the exact same situation with no easy way to connect. Existing social apps aren't built for this: they assume permanence, identity-building, and long-term relationships, which feels heavy and mismatched for a 45-minute layover.

---

## 3. Target Users

| Persona | Context | Need |
|---|---|---|
| Delayed Traveler | Stuck at an airport/station for hours | Company, distraction, shared frustration |
| Waiting Room Visitor | Hospital, clinic, govt office | Light companionship during an anxious wait |
| Jury Duty / Long Queue Person | Courthouse, DMV, ticket queue | Something to do, someone to talk to |
| Digital Nomad / Frequent Flyer | Regularly in transit spaces | Quick social connection without commitment |

---

## 4. Core Principles

1. **Ephemeral by default** — presence and chats expire automatically; nothing persists beyond the wait.
2. **Low-pressure connection** — waves before chats; no open DMs to strangers.
3. **Location-honest** — presence is tied to real-time location/venue, not a static profile.
4. **No engagement traps** — no infinite scroll, no streaks, no notifications begging you to "come back."

---

## 5. Feature Set (MVP)

### 5.1 Check-In Flow
- Select **Layover Type**: Airport, Train Station, Hospital, DMV/Govt Office, Jury Duty, Long Queue, Custom
- Set **Expected Duration**: 30 min / 1–2 hrs / 3+ hrs / "No idea"
- Optional **Status Line** (one sentence, e.g. "Flight delayed to Mumbai, bored out of my mind")
- Auto-detect venue via location (with manual override/search)

### 5.2 Limbo Feed
- List/card view of others checked in at the same venue
- Sorted by proximity within venue (terminal, floor, section if available)
- Card shows: avatar, layover type icon, status line, time remaining (live countdown)
- Filter by **Vibe**: "Just want quiet company" / "Down to chat" / "Show me who's also stuck here"

### 5.3 Connect Flow
- Tap to send a **Wave** (lightweight icebreaker, not a full message)
- If both users wave → temporary chat thread unlocks
- Chat auto-expires when either user checks out, or after a defined buffer (e.g. 2 hours post-checkout)
- No persistent DM history retained after expiry

### 5.4 Countdown & Auto-Expiry
- Visual countdown timer tied to expected duration (editable if the wait runs long/short)
- Geofence-based auto-checkout when user leaves the venue radius
- Manual "I'm done waiting" checkout option
- Signature animation: countdown timer visually "dissolving" as time runs out (boarding-pass-style)

### 5.5 Safety & Comfort Layer
- No exact GPS pin shown to other users — only venue + proximity zone
- Report/block user
- Waves are anonymous until mutually accepted (no forced photo/name reveal)
- Auto-expiry itself acts as a natural safety net (no long-term exposure)

---

## 6. User Flow

1. Open app → Check in (select type, duration, optional status)
2. Land on Limbo Feed → browse others at the same venue
3. Send a Wave to someone → wait for mutual wave
4. Mutual wave → temporary chat unlocks
5. Chat/connect during the wait
6. Leave venue (auto or manual checkout) → presence and chat fade out

---

## 7. Screen List

1. Onboarding / Value Prop (3 screens)
2. Check-In Screen (venue, duration, status)
3. Limbo Feed (list/card view)
4. Vibe Filter Selector
5. User Detail Card (expanded view before waving)
6. Wave Sent / Pending State
7. Temporary Chat Screen
8. Countdown / Timer Widget (persistent overlay or tab)
9. Checkout Confirmation Screen
10. Settings (safety, notifications, block list)

---

## 8. Tech Considerations

- **Frontend:** Flutter (cross-platform, consistent with your existing stack)
- **Real-time presence:** Firebase Realtime DB or WebSocket-based presence system
- **Geofencing:** Native geofencing APIs (iOS CoreLocation / Android Geofencing API) for auto-checkin/checkout
- **Chat:** Ephemeral messaging layer — chat data purged on expiry (not soft-deleted, actually removed)
- **Backend:** Laravel or Node, depending on team preference
- **Animation:** Rive for the countdown/expiry visual and wave micro-interactions

---

## 9. Monetization (Future Consideration)
- Freemium: basic check-in/wave free; premium unlocks extended chat buffer, more vibe filters, priority visibility
- Venue partnerships: airports/lounges could sponsor a branded "Layover Lounge" check-in category
- No ads in MVP — conflicts with the low-pressure, non-engagement-trap ethos

---

## 10. Success Metrics (Post-Launch)
- % of check-ins that result in at least one mutual wave
- Average chat duration relative to layover duration
- Repeat check-ins per user (across different venues/trips)
- Report/block rate (safety health indicator)

---

## 11. Out of Scope (MVP)
- Persistent user profiles/bios
- Public feed or posts
- Photo/video sharing within chat
- Group chats (1:1 only for MVP)
- Any AI-based matching or recommendation
