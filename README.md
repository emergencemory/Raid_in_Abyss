# Raid in Abyss

*Fight through endless depths and carve your legend in steel and blood.*

## Overview

- **Elevator Pitch**: Descend into the abyss in a fantasy hack’n’slash. Every layer brings stronger foes—can you reach S rank? A fantasy hack’n’slash where players descend layer by layer into the abyss. Procedural levels ensure no run is the same.
- **Genre**: Hack’n’slash, action RPG, Dungeon Crawler
- **Platform**: PC and Browser
- **Target Audience**: Fans of skill-based melee combat, procedural roguelikes, and progression-driven action games.
- **Inspirations**:
    - https://store.steampowered.com/app/48700/Mount__Blade_Warband/
    - https://dos.zone/warcraft-ii-tides-of-darkness/
    - https://lf2.net/index_old.html
    
    ![“Fallen” from Diablo II (left) / Mount and Blade directional combat (right)](attachment:816384ee-dba2-4331-8ee5-1982252c05d2:8504608660ff4720bbfb37b2.webp)
    
    “Fallen” from Diablo II (left) / Mount and Blade directional combat (right)
    
    ![gm-46e32543-571d-40da-96c7-22c51c66fa1a-mount-blade-2-bannerlord-action.jpg](attachment:e819f6d1-68b1-4856-a6ed-8946adb43716:gm-46e32543-571d-40da-96c7-22c51c66fa1a-mount-blade-2-bannerlord-action.jpg)
    

---

## Vision & Player Experience

- **Player Fantasy**: Become a lone warrior plunging deeper into the abyss, mastering precision combat while outsmarting swarms of enemies. Start as a humble peasant, survive wave after wave, and claw your way up to commanding knights and legendary heroes in an endless war.
- **Core Loop**: Spawn → Fight → Gain XP→ Push Territory → Descend or Ascend → Class Up → Repeat.
- **Progression Loop**: XP-based levelling system (class system in future)

![combat_4.PNG](attachment:7fdab681-017d-4daf-b48b-3d301a8391db:combat_4.png)

![aoB4v.png](attachment:d57d6b5e-60f6-4926-8c1e-5141686c2d95:aoB4v.png)

![LF2 style combos (guard, direction, attack/jump) can accomplish special attacks (bottom left)](attachment:0e4efeba-dce8-4d10-8e62-acd2626897e8:30zc23emk5g51.webp)

LF2 style combos (guard, direction, attack/jump) can accomplish special attacks (bottom left)

---

## Game Systems

- **Primary Mechanics**
    - Directional cooldown based melee combat (cursor-based swings, blocks, & parries, Mount & Blade style).
    - Spacebar skill (ie: spacebar, kick, does knockback and stun to the enemy directly in front of character)
    - Leveling system (cooldowns, health, parry, damage).
- **Secondary Mechanics**
    - Boss battles with unique mechanics.
    - Procedural level generation.
- **Controls**: Touchscreen or Keyboard/Mouse
- **UI**: RPG style health, cooldowns, minimap, zoom controls, combat log

[M&B promotion trees](attachment:242aee37-2a8d-417e-b661-409887e39e37:screenshot-244-cropped.avif)

M&B promotion trees

[Bannerlord-2-1.avif](attachment:bfa26b61-ca1b-4c9e-906b-314eda15befc:Bannerlord-2-1.avif)

---

## Content & Presentation

- **Art Direction**: Angled top-down, square grid terrain, straight top down characters, Warcraft II meets Diablo II vibes
- **Audio Direction**: Original soundtrack and SFX by SmthngClvr, thematic to fantasy & abyssal descent.

![Warcraft II mixes straight top down and slight angle](attachment:af94d94e-a63d-4896-9470-67f29851cfcc:image_2024-11-14_050037783.webp)

Warcraft II mixes straight top down and slight angle

![warcraft-ii-remastered-pc-cd-key-2.webp](attachment:61434396-60ec-4818-88db-f657002ac51d:warcraft-ii-remastered-pc-cd-key-2.webp)

---

## Technical & Production

- **Engine**: Godot
- **Constraints**: Theme: Into the Depths. Procedural generation must not block progress
- **Development Timeline**: Ludum Dare 57: 4-16 April 2025 (1.5 weeks)
    - MVP:
        - Single biome
        - Single soldier type per team
        - Only knight team player controlled
        - Single-player
        - Procedural generation
        - Combat mechanics
        - Levelling
        - UI: Minimap, Combat Log, Rebindable Inputs, Audio Controls, Fullscreen
        - PC build
    - Stretch:
        - Score attack mechanic
        - Endless mode option
        - Boss fight
        - Kicking enemy off cliff
        - Destructable Terrain
        - Touchscreen Controls
        - Browser Build

![shenk2.jpg](attachment:1958b1e2-5cd3-4642-810f-ed9b207140a0:shenk2.jpg)

![Diablo II fighting orcs (left) / Warcraft III heroes (right)](attachment:d549c221-0e6c-4783-8fec-10b3506efedf:qza5mg3yruk71.png)

Diablo II fighting orcs (left) / Warcraft III heroes (right)

---

### MVP Feedback

- **Overview:**
    
    Feedback collected from Ludum Dare 57 ratings (30.5 received), player comments, and livestream playthroughs. Game was praised for presentation and ambition, with consistent notes on polish, clarity, and balance.
    
- **Key Strengths:**
    - **Art & Audio**: Retro aesthetic, smooth animations, polished sprites/UI, satisfying SFX, strong main menu music.
    - **Concept & Systems**: Directional combat, shield/kick mechanics, possession-style respawning, procedural endless dungeon.
    - **Feel**: Combat satisfying when it clicked; players liked aggressive playstyles, positioning choices, and “plodding” feel.
    - **Atmosphere**: Strong Diablo/Dark Souls/Warcraft 1 vibes with high production values for a jam build.
- **Key Issues:**
    - **Combat Clarity**: Shield/block felt inconsistent; kick too snappy; unclear ally vs. enemy distinction; attacks lacked feedback at times.
    - **Flow & Balance**: EXP reset after death + scaling bosses led to frustration; ally AI often idle or exploitable; progression could swing between overpowered and too punishing.
    - **Performance/Technical**: Occasional invisible enemies, lag in web builds, sprites rendering outside playfield, collision oddities.
    - **UX/Presentation**: Font readability issues; small web viewport; no fullscreen option; movement/camera tied to grid felt clunky for some.
    - **Repetition**: Traversal across empty space felt tedious; gameplay loop could drag without new enemy types or objectives.
- **Player Requests / Suggestions:**
    - Add dash/backstab mechanics and more varied enemy behaviors.
    - Improve ally teamwork (banners, call-for-help mechanics).
    - Introduce points of interest (chests, idols, unique rooms) to break up repetition.
    - Clarify ally/enemy visuals and add EXP penalties for friendly fire.
    - Improve camera & movement smoothness, font readability, and add fullscreen support.
- **Action Items:**
    - Short-term:
        - Fix bugs (invisible enemies, ally collision, EXP/level UI desync).
        - Polish combat feel (shield timing, kick animation, clearer hit feedback).
        - Improve font readability and add fullscreen option for web build.
    - Mid-term:
        - Refine progression loop (less punishing EXP resets, clearer ally/enemy distinction).
        - Add new enemy types and combat variety (dash, backstabs, teamwork).
    - Long-term:
        - Expand dungeon generation with points of interest and environmental variety.

---

### Future & Stretch Goals

- Multiplayer Server (Move to Websocket client-server architecture for multiplayer) (Issue #9, 23)
- UI Cleanup (Issue #24, 22)
- Dash Move to bypass allies (Issue #21)
- Tutorial (Issue #15)
- Player controlled orc and knight characters)
- Redo combat visual cues (Issue #20)
- Pathfinding refinement (Issue #5)
- Permanent meta-progression (pickable classes). (peasant → footsoldier → archer → knight → mounted knight → hero) (Issue #10, 11, 13)
- Expanded progression with new combo skills LF2 style. (or majicka?)
- Hero spawns (more bosses)(Issue #12)
- Order/Command NPC’s (Issue #7)
- Tile Placing in-game (Issue #9, 14)
- Story Mode (Issue #15)
- 
![Ludum Dare](https://img.shields.io/badge/LudumDare-57-f79122?labelColor=ee5533&link=https%3A%2F%2Fldjam.com%2Fevents%2Fludum-dare%2F56)
![Ludum Dare](https://img.shields.io/badge/LudumDare57-Extra-66cc23?labelColor=ee5533&link=https%3A%2F%2Fldjam.com%2Fevents%2Fludum-dare%2F56)
Entry for ludum dare 57
Theme: depths
Knights (blue, left) raiding abyss full of Orcs (red, right)

Credits:
Game - Emery Smith - staticleapstudios.com
Music/SFX - Smthngclvr - https://youtube.com/@smthngclvr?feature=shared

Main Goals:
melee-system
terrain-generator
minimap

Controls (rebindable)
WASD - move up/down/left/right
Left Click - prepare attack and parry from the mouse direction relative to the character's facing direction
Release Left Click - initiate attack
Right Click - block attacks from the mouse direction relative to the character's facing direction
E - kick (stun and knockback in some conditions)
Scroll Up - zoom in
Scroll Down - zoom out
Escape - Menu
Tilde - dev console

Post-LD57 game jam features planned:

Functionality - Touch Screen Controls
Functionality - Mac OS, Linux, Android, IOS builds
Functionality - Web and Exe builds merged
Functionality - A Star Grid 2D Pathfinding

Game Mode - Story
Game Mode - Wave Defense
Game Mode - Building
Game Mode - Gungame Skirmish
Game Mode - P2P Coop

Mechanic - Command NPCs
Mechanic - Auto Target / Turn to Face

Content - Tier 0_melee & 0_range Characters (Peasant / Goblin)
Content - Tier 1 Characters (Militia / Gnoll)
Content - Tier 2_range Characters (Elven Archer/Dark Elf)
Content - Tier 3 Characters (Zweihander / Troll)
Content - Tier 4 Characters (Knight / Warg Rider)
Content - Tier 5 Characters (Dwarf Paladin)
Content - Tier 6 Characters (Wizard / Necromancer)
