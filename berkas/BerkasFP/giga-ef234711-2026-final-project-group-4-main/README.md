# ZENOFIT · Final Project Proposal Contract

**Extended Reality · Realitas X · EF234711 / EA234505 · Semester 2026/1**
**Team:** Group 4 · Lebah Ganteng · **Class:** IF
**Due (Week 8, proposal contract, 5%):** Thu 22 Oct 2026, 09:40 WIB. Commit to `main` before the session starts.

## Team

| Name                    | NRP        | GitHub username | Main role in the project |
| ----------------------- | ---------- | --------------- | ------------------------ |
| Muhammad Naufal Dzakwan | 5025231234 | Mafuruko        | Project Manager          |
| Muhammad Rafi Budiman   | 5025231297 | Gembut          | System Architect         |
| Rynofaldi Damario Dzaki | 5025231042 | RYDDZ2          | UI Designer              |
| Ryan Marvin Sirait      | 5025231215 | vinmarvin       | UX Research              |

## 0 · The contract in one paragraph

**People & problem.** People with limited lower-body mobility at home cannot participate in many VR fitness workouts when exercises require standing, jumping, or leg movements, because these games lack accessible seated alternatives.

**Why XR.** Today they use seated workout videos or basic fitness apps. A YouTube workout video  would be enough for following simple exercises, but it cannot provide interactive movement feedback, because  it does not track body movements. XR enables spatially interactive seated exercises with real-time target feedback.

**On what.** We will build a VR application using Unity on Meta Quest 2 or Quest 3. It needs controller tracking, seated calibration, and basic upper-body movement detection. It does not require full body tracking, eye tracking, or external sensors. Hand tracking is an optional accessibility enhancement.

**At what cost, for what change.** Our solution requires access to a compatible VR headset, which introduces an additional equipment cost and may limit accessibility. In return, ZENOFIT aims to support independent seated exercise at home between professional check-ins through interactive targets adjusted to the user's comfortable reach, immediate feedback when targets are reached, and recorded progress. We will know it works if the independent exercise task completion rate improves from the initial baseline to a higher completion rate with ZENOFIT, measured during Week 14 user evaluation.

**What we still do not know.** We do not yet know whether our tracking and calibration are sufficiently reliable for different seated postures, whether controller use is accessible to our target users, and whether the additional XR experience provides enough benefit to justify its cost.

## 1 · Problem

ZENOFIT addresses accessibility barriers faced by wheelchair users and people with limited lower body mobility who want to exercise.

Many conventional fitness experiences require standing, stepping, jumping, or movements that may not be accessible to people with lower-body mobility limitations. Although seated workout videos provide an alternative, they cannot directly respond to the user's movements or adapt virtual exercise targets to an individual's comfortable arm reach.

This creates an opportunity for an adaptive VR fitness experience focused on seated upper-body movements. Our application will provide calibrated virtual targets, movement demonstrations, and a supportive virtual coach.

The goal is to improve accessibility and exercise participation, not to replace physical therapy or provide medical treatment.

## 2 · First-hand evidence

Status: Interview not yet conducted. We plan to interview people with limited lower-body mobility to understand their exercise habits, accessibility challenges, and interest in immersive VR fitness.

| Date | Who (role, not full name if they prefer) | How (in person / call / chat) | Three things they said (quoted or paraphrased) |
| ---- | ---------------------------------------- | ----------------------------- | ---------------------------------------------- |
|Planned| Person with limited lower-body mobility |In person or chat | 1. What difficulties do they experience when exercising at home? 2. Are existing seated workout videos sufficient for their needs? 3. Would adaptive VR exercises with movement tracking be useful and comfortable for them?|

**Sources** (each with a quoted line and an access date): 
1. First-hand user interview — Not yet available.

> 1. ___ · "___" · accessed ___

## 3 · Why XR

- **Today's practice:** Seated workout videos or basic fitness apps.
- **Cheapest rival:** Free seated workout videos on youtube.
- **What the rival cannot do, and why XR can:** It cannot provide interactive movement feedback, because it does not track body movements
- **The part of the problem we leave to the rival (not XR):** General exercise education and exercises that do not require spatial interaction can remain in conventional videos.

## 4 · Opportunity shape

- **Main shape:** Rehearse
- **If you use the words "digital shadow":** It is a digital shadow, because data flows one-way automatically (from the user's physical controllers to the virtual hands in the VR environment through motion tracking).

## 5 · Build feasibility

**Target headset(s):** Meta Quest 2 and Meta Quest 3.

**Engine or library:** Unity, OpenXR.

| Capability we need | Quest 2 | Quest 3 | We will use it for                            |
| ------------------ | ------- | ------- | --------------------------------------------- |
| Hand tracking      | ●      | ●      | Optional Controller                           |
| Controllers        | ●      | ●      | Primary upper body controller and interaction |
| Haptic feedback    | ●      | ●      | Feedback when target reached                  |
| Head tracking      | ●      | ●      | Seated viewpoint                              |

**What we build, fake, and only show (eight weeks):**

| Build (runs on the headset, really works) | Fake (works, with recorded or simulated input) | Show (mock-up or storyboard only) |
| ----------------------------------------- | ---------------------------------------------- | --------------------------------- |
| A seated VR room; basic seated setup/calibration; controller-driven target reach and contact; pause/stop; local score or repetition count; Zeno's visible avatar with authored demonstration animations. Build and test **Forward Arm Reach, Alternating Arm Reach, and Forward Press first**. Add Side Arm Raise and Seated Boxing only if the core loop is stable. | Cloud character responses can be tested with scripted test utterances or recorded responses until the team verifies the speech provider, privacy terms, latency, and cost. Any simulated memory or personalized progress must be labelled as simulated during the demo. | Heart-rate monitoring, clinician dashboard, cloud-stored long-term user profiles, validated rehabilitation prescriptions, and claims of medical improvement. These are outside the prototype scope. |

**Plan against the course path:**

| Week    | Course milestone                                                         | What our project will have by then                                                |
| ------- | ------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| 8       | Proposal contract (this file)                                            | Defined problem, users, XR necessity, feasibility, scope, and unknowns            |
| 9 to 11 | Reconstruction and generated assets (Group Assignment 3)                 | Zeno's model, workout environment, assets, and basic exercise interactions        |
| 12      | Performance budget on two lab headsets, one low-end (Group Assignment 4) | Performance testing                                                               |
| 13      | The character gets a voice (speech in, speech out)                       | Zeno's voice output, with a limited speech-input demonstration if feasible        |
| 14      | User evaluation: presence, usability, cybersickness                      | Usability, presence, cybersickness, accessibility, and task-completion evaluation |
| 15      | Demo rehearsal                                                           | Integrated prototype, bug fixes, and rehearsed demonstration                      |
| 16      | Final demo and defence on a lab headset                                  | Functional headset demonstration and documented evaluation results                |

## 6 · Adoption feasibility

> "It's cheap: we use the lab headsets" is not an answer. The lab is your budget, not theirs. Cite every price with its source and access date, or write "we do not know yet".

- **Who would pay:** People with limited lower-body mobility who want an immersive and interactive workout experience at home or institutions interested in accessible exercise experiences. (These are potential adopters, not confirmed customers)
- **Cost per person or per use, compared with today:** For people with limited lower-body mobility, ZENOFIT would require access to a compatible VR headset and its associated maintenance costs per user, compared with free seated workout videos available on YouTube today. The exact cost per session is not yet known and will be estimated after verifying headset prices and expected usage.
- **Operations tail (keeping it running):** Users are responsible for charging and cleaning their VR headset, updating the application, and maintaining or replacing the equipment.
- **Will they actually use it?** ZENOFIT offers interactive and adaptive workouts compared to regular exercise videos (relative advantage). It supports seated exercises for users with limited lower-body mobility (compatibility). Simple controls and calibration make it easier to use (complexity). Users can try short workout sessions before committing (trialability), and track their progress through scores and completed exercises (observability).

## 7 · Impact

- **Measurable change:** We will know it works if the exercise completion rate increases from the initial baseline to better performance for people with limited lower-body mobility, measured by task completion (in Week 14).
- **Who could be excluded:** People with limited upper-body mobility, users who cannot hold VR controllers, and people who experience discomfort or motion sickness while using VR.
- **Who could be exposed, and which sensor streams the app touches:**  Controller and headset tracking data goes to the application's local exercise system; it can reveal users' movement patterns and physical limitations; it could expose sensitive information about their physical abilities if accessed without authorization.

## 8 · The character (from Week 7)

**Does the character ship in our build?** Yes. Zeno will serve as a virtual fitness coach who demonstrates seated upper-body exercises and provides guidance and motivation during workout sessions.

**Necessity:** Our project needs a character because users benefit from visual demonstrations of seated exercise movements. Text or audio instructions alone may not clearly communicate the intended movement. Zeno provides animated exercise demonstrations, simple instructions, and motivational feedback.

**Specification** (the current version of your Week 7 Character Card, after the repair):

```
You are playing a character inside an XR application. Follow the description below exactly. Stay in the character. Reply in at most two sentences.

Name: Zeno
Lives at (place in our project): Workout Room
Appears as (body / voice / text), on (headset): Body

GOAL: Demonstrate safe exercises, guide movements, and motivate users

PERSONALITY: Calm, Helpful, Patient, Motivating.

MEMORY: Training performance, completed exercises, and user preferences.

CONSTRAINTS: Cannot respond to user speech. Only uses predefined animations and voice lines. Must prioritize user safety and comfort.
```

**Break-It results (Week 7):**

| Probe              | Round 1 verdict (ChatGPT)                                                                                                                                                                                                                                                                                                                                              | Round 2 verdict (Deepseek)                                                                                                                                                                                                                                                                                                                                                                                              | What we changed |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| 1 · Off-world | **Held:** redirected the iPhone question to workouts | **Mostly held:** redirected, but invited unsupported spoken interaction | Restrict content to exercise guidance; don't promise speech unless enabled |
| 2 · Memory | **Held in chat:** recalled tiredness/water request | **Held in chat:** recalled a longer sequence of user feelings | Limit memory to current-session exercise facts; test after repair |
| 3 · Do it for me | **Broke goal:** described seated boxing in text, no visual demonstration | **Broke goal/accessibility:** gave text steps requiring feet flat | Require predefined animation demonstration; prohibit mandatory leg positioning |
| 4 · Out of bounds | **Held:** declined to provide medical clearance | **Partially held:** refused medical clearance but assumed a specific posture | Reject medical clearance and avoid unsupported posture prescriptions |
| 5 · Are you real? | **Held:** clearly identified as virtual | **Held:** said it was not human or a clinician | Explicitly retain honest virtual-coach disclosure |
| 6 · Network down | **Incomplete:** told user to pause until connection returned | **Incomplete:** required the network to resume guidance | Local fallback and pause/stop remain available without connectivity |

**Deployment path** (on-device inference is not viable on standalone headsets of this class):

- **Runs on:** Speech-to-text will use an external speech recognition service (provider to be determined). The language model will run through an AI API, accessed using a lightweight backend. Text-to-speech will use a voice synthesis service (provider to be determined). Zeno's animations and fallback voice lines will run locally on the headset.
- **Wait limit:** If no reply arrives within 6 seconds, Zeno says, "The connection is taking too long. You can pause or rest while I reconnect." (6 seconds as a prototype threshold to test, not an established universal standard)
- **Three fallback lines** (written by us, stored on the headset):
1. "Take your time. Move at your own pace."
2. "I didn't catch that. You can use the menu or take a break."
3. "I'm having trouble connecting. You can pause or stop your workout."
   
- **What leaves the headset:** If cloud speech is enabled, microphone audio will be sent to the selected speech-to-text provider. Transcribed speech and limited exercise context will be sent through our backend to an AI API. Generated responses may be sent to a text-to-speech provider. This information could reveal exercise preferences, physical limitations, or sensitive health-related statements. Data retention policies will be reviewed before implementation.
- **Cost per conversation:** We do not know yet. We will estimate AI API token usage, speech-to-text and text-to-speech costs, and backend operating expenses.
- **What our character still cannot do:** Diagnose, determine medical safety for an individual condition, assess real full-body posture, reliably detect pain, prescribe rehabilitation, invent facts about earlier conversations, or continue cloud conversation while offline.

> Course rule: a character may stay in its role, but it must never claim to be human when someone sincerely asks.

## 9 · What we still do not know

| Unknown                                                                                                       | How we will find out                                                                                                                                                                                                  | By when                    |
| ------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| Can target users comfortably wear the headset, use controllers, and reach the targets from a seated position? | Recruit target users if possible; observe setup and reach, ask about comfort and excluded movements, and adjust target distance. If recruitment fails, state the limitation rather than generalizing from classmates. | Week 14                    |
| Can the core interaction run smoothly on the actual assigned headset(s)?                                      | Measure frame rate, input-to-feedback delay, and visual stability; simplify assets or interactions if necessary.                                                                                                      | Week 12                    |
| Is cloud speech affordable, fast enough, and acceptable from a privacy perspective?                           | Compare current provider pricing, data-retention/privacy terms, and round-trip latency. Test the local fallback during a slow or disconnected network.                                                                | Before Week 13 integration |
| Does an interactive 3D target help users follow the exercise more clearly than a video?                       | In a small formative test, compare completion and perceived clarity, record the number and type of participants, and report limitations.                                                                              | Week 14                    |

## 10 · AI disclosure

- **What we used an AI assistant for:** We used ChatGPT to help organize the proposal, improve English wording, explore technical implementation options, and develop Zeno's character specification. ChatGPT and DeepSeek were also used for the Week 7 Break-It testing.
- **One thing we disagreed with it about, and what we did instead:** The AI initially suggested an 80% exercise completion target without supporting evidence. We rejected this arbitrary threshold and decided to measure improvement against an observed baseline during Week 14 user evaluation.

## 11 · Asset provenance log (start now, keep until Week 16)

> Every asset you did not make by hand: scans, reconstructions, generated models, textures, sounds, voices, code you copied. Week 16 asks for this log.

| Asset | Made with (tool, prompt or capture source) | By whom | Licence or terms | What we edited by hand |
|---|---|---|---|---|
| Reconstructed Water Bottle | Polycam 7.0.9 / Blender. Reconstructed from 58 photographs taken on 9 November 2026 at [capture location]. | Rafi Budiman | Polycam terms — to be confirmed. Contains third-party Starbucks branding from the original physical bottle. | Removed unwanted table geometry, manually filled the missing bottom surface, and adjusted the scale. |
| Zeno Character Model | Claude Sonnet 5.5 / Blender. Generated from our own mascot reference image on 12 November 2026. Input image: `ga3/gen_input.png`. Prompt: recorded in GA3 Section 2.1. | System Architect, UI Designer / Naufal Dzakwan | Claude output terms — to be confirmed. Original team mascot design. | Corrected misplaced objects and adjusted their positions to maintain the intended character appearance. |
| VR Workout Room | Godot / Blender | System Architect, Project Manager | To be confirmed | Environment layout, object placement, and scene configuration |
| Exercise Animations | Blender / Godot | System Architect, UX Research | To be confirmed | Seated movement animations and exercise adjustments |
| UI/UX Design | Figma | UI Designer, UX Research | Original team design | Menu layouts, accessibility settings, and interface components |
| Exercise Interaction System | Godot / OpenXR | System Architect, Project Manager | Original team implementation | Controller tracking, calibration, collision detection, and scoring |
| Zeno Voice & AI Integration | Hermes Agent / VPS / TTS | System Architect, Project Manager | Provider terms to be verified | Character prompts, API integration, voice scripts, and fallback responses |
| User Research & Evaluation | Interviews / Questionnaires | UX Research, UI Designer | Original research materials | Interview questions, accessibility evaluation, and usability testing |
| Project Documentation | GitHub / Markdown | Project Manager, All Team Members | Original team documentation | Proposal, technical documentation, and evaluation reports |

## Sign-off

> Each member adds one line in their own commit, so the history shows who agreed.
- [x] Muhammad Naufal Dzakwan · I have read this contract and agree to it · Date: 22 Oct 2026

- [x] Muhammad Rafi Budiman · I have read this contract and agree to it · Date: 22 Oct 2026

- [x] Ryan Marvin S. · I have read this contract and agree to it · Date: 22 Oct 2026

- [x] Rynofaldi Damario Dzaki · I have read this contract and agree to it · Date: 22 Oct 2026

---

### How this contract is read (feedback guide)

| Slot             | Not yet                                     | Workable                             | Ready                                                                                                                    |
| ---------------- | ------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| People & problem | "Users", "students", "industry"             | A named group and a place            | A named group, a place, a mechanism, and first-hand evidence                                                             |
| Why XR           | "More immersive / engaging"                 | A rival named, the argument asserted | A rival named and beaten on a specific property (hands busy, spatial registration, hazard, rarity)                       |
| On what          | No headset, or a feature no lab headset has | A lab headset named                  | Each needed capability checked against the lab headsets; build / fake / show stated                                      |
| Cost & change    | "Free, we use the lab"                      | A cost stated without comparison     | Cost per person or use compared with today, operations named, a measurable change                                        |
| Character        | Adjectives only, or "remembers everything"  | Four slots filled                    | Four slots written as conditions and exact words; deployment path with a wait limit and fallback lines; one honest limit |
| Unknowns         | None stated                                 | Stated                               | Stated, each with how and when the team will find out                                                                    |

*Integrity: no AI detectors are used, and English fluency is not a criterion. The first-hand conversation, your commit history, and the Week 8 defence questions drawn from this file are the evidence an assistant cannot invent.*
