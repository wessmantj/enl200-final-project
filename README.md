# enl200-final-project

Concept:
Based on the novel `The Factory` by Hiroko Oyamada. This will be a 2D game, similar layout to `The Escapist` where each narrator is a playable character with an interactive enviornment, modeled off their in-book experiences and other concepts. There will be relevant dialogue, work tasks, day structure, etc.

Framework: GODOT
Visual Style: Similar to "The Escapists" (2D Pixel Art)
World Generation: Perlin noise for sprawling factory layout

---

## Playable Characters

### 1. Yoshiko Ushiyama
**Role:** Contract Worker — Shredder Squad, Print Services Branch Office (basement)

**Background:**
Liberal arts graduate who specialized in Japanese language and communication. Has cycled through five jobs without staying at any longer than a year. Applied for a permanent position at the factory and was redirected mid-interview into a contract role. Her brother also works at the factory, though neither knows the other is there at first.

**Job Mechanics (gameplay):**
- Operates industrial document shredders all day
- Receives containers of documents delivered by TRAN workers twice daily (~10am and 3pm)
- Shreds pages, disposes full bags, switches machines when one jams or overheats
- Works 9:00–5:30, Mon–Fri; bell chimes mark start, lunch, and end of day
- Wears a gray apron with a sewn-in employee number; red lanyard ID badge
- Signs a confidentiality pledge — no documents leave the factory

**Key NPCs:**
- **Captain Samukawa** — Team leader; old, frail, friendly; was hospitalized at start of game; keeps an exercise machine (Power Tower) at the station; invents "commercials" (spontaneous team dinners at Moo-Moo Yakiniku)
- **Itsumi** — Small, straight black hair in a ponytail, gold vine-frame glasses, a few gray hairs; warm and efficient; acts as de facto leader when the Captain is away; "big sister" of the squad
- **Hanzake** — Wide face, tiny nose, marble-like eyes, hobbles from an old industrial jack injury to his leg; former assembly-line worker; affectionate nickname (Giant Salamander)
- **The Giant** — 6'4", long fingers, almost entirely silent; expressive through grunts and grins
- **Goto** — Head of Print Services Branch Office; red-faced, cloudy/yellowed eyes, rumpled suits; incompetent but not unkind; delivers disorganized instructions

**Personality / Tone:**
Serious and earnest to a fault. Wants to do the job correctly even when no one is checking. Struggles to understand why the work feels so weightless. Quietly proud.

**Arc / Ending:**
Over time the rhythm of shredding grows hypnotic. In the final scene, feeding the last pages into the machine on a rainy morning, she becomes a black bird.

---

### 2. Yoshio Furufue
**Role:** Sole Employee — Environmental Improvement Division Office for Green-Roof Research

**Background:**
Bryologist and moss taxonomist, pushed into the factory job by his university advisor who nominated him without asking. Furufue had wanted to stay in academia. His parents were overjoyed. He is introverted, dislikes team dynamics, and genuinely puzzled by what the factory expects of him.

**Job Mechanics (gameplay):**
- Conducts "moss hunts" — walks the factory grounds collecting and classifying moss samples
- Has no colleagues, no supervisor, no hard deadlines; proceeds "at his own pace"
- Lives in a factory-provided two-story house (one floor is his lab/workspace); next door is a cleaning facility (constant hum of washers and irons, faint detergent smell)
- Receives a silver-strap ID badge — grants access to virtually all outdoor areas
- Leads the annual **Family Moss Hunt**, a guided event for factory employees and their children
- After 15 years, green-roofing was quietly outsourced; Furufue's actual impact on the factory is nil, though he's still employed and still studying moss

**Key NPCs:**
- **Aoyama (Izumi)** — PR department contact, later promoted to manager; smart, composed, Hokkaido-born; handles logistics for the moss hunt; the only person Furufue can really talk to
- **Goto** — Assigned Furufue's onboarding; cheerful, clueless about the job's real scope; later transfers to a different department
- **Old Man Samukawa & grandson Hikaru** — Attended the moss hunt; the grandson wrote a year-long report on factory fauna (shags, lizards, coypus) and brings it to Furufue's house; the old man is the Captain from Yoshiko's story

**Personality / Tone:**
Resigned and analytical. Finds the factory's logic genuinely baffling. Grows quietly content with a small, purposeless life — well-paid, low-pressure, intellectually hollow. Grows shiso and tomatoes in his backyard.

**Arc / Ending:**
Confronted after 15 years with the question of what he has actually accomplished. No clear answer. Meanwhile, the factory animals (birds that can't truly fly, coypus expanding from the sewers) grow stranger around him.

---

### 3. Unnamed Narrator (Yoshiko's Brother)
**Role:** Temp Worker — Document Division Proofreader

**Background:**
Former systems engineer at a small company, let go in a round of downsizing. Around thirty years old, living with his sister Yoshiko. Got the factory temp job through his girlfriend, who works as a sales coordinator at a temp agency. Embarrassed by the work; plans to return to IT as soon as the economy turns. Has no computer at his desk. Resents that he got the job through personal connections.

**Job Mechanics (gameplay):**
- Picks packets from a tall filing cabinet — each contains documents of various types (booklets, blueprints, manuscripts, operation manuals)
- Proofreads by hand using a red pen; consults a Japanese dictionary, an English–Japanese dictionary, a character dictionary, and a proofreader's handbook
- Marks errors using standardized proofreader's marks (though the system is old; improvisation is acceptable)
- Completed packets go to a return shelf; they are collected once a day
- No signature required — accountability is diffuse; errors are rarely traced back to anyone
- Falls asleep at his desk; partitions hide him from coworkers

**Key NPCs:**
- **Kasumi** — Temp from the same agency; heavy-set, kind wrinkles under her eyes, smells like peaches or pineapple candy; warm and experienced; acts as the narrator's guide; closest thing to a friend in the office
- **Irinoi** — Middle-aged temp with a brownish perm; voice roughened by drinking; blunt; offers unsolicited but accurate advice
- **Glasses** — Younger temp with blue glasses; quiet; listens to everything
- **Girlfriend** — Never named; coordinator at the temp agency; permanently employed, cheerful, gossipy; the narrator's only lifeline and source of quiet resentment

**Personality / Tone:**
Proud and slightly contemptuous of his situation. Tends to look down on others while depending on them. Prone to introspection that reveals his own hypocrisy. Falls asleep during work and wakes disoriented, unsure how much time has passed.

**Arc / Ending:**
Discovers his sister works in the same factory. Encounters Furufue's documents (the boy's fauna report) in a proofreading packet and dismisses them as fiction. The boundaries between sleep and waking, real and unreal, gradually blur.

---

## Shared World Elements

| Element | Detail |
|---|---|
| The Factory | Enormous, self-contained — has its own buses, cafeterias (nearly 100), restaurants, supermarkets, hotel, bowling alley, post office, bank, shrine, residential lots, museum |
| Four Gates | North, South, East, West — the only ways in or out |
| The River | Divides factory into north and south zones; crossed by a large central bridge |
| Black Birds | Oil-black, shag-like birds that live by the river; can't truly fly; population grows every year; called "factory shags"; unidentified species |
| Coypus | Large rodents living in the factory's sewers and drain systems; expanding outward; passive, unafraid of humans |
| Forest Pantser | A middle-aged man who runs through the factory forest trying to pull the pants off passersby; calls himself that; deters if you wear a suit; likely a factory employee |
| TRAN workers | Transport crew wearing jackets labelled TRAN; deliver document containers and collect full shred bags |
| Goto | Appears in all three narrators' stories; PR department; red-faced; a connective tissue between the three plotlines |
| Captain Samukawa | Yoshiko's team leader; his grandson Hikaru appears in Furufue's storyline |
