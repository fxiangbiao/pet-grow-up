# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

游戏化宠物养成系统 — A gamified pet-raising learning system that transforms K-12 learning (Chinese, Math, English) into an adventure experience. Students complete learning tasks to raise "learning spirits" (学习精灵) and explore subject-themed fantasy worlds.

## Status

The project is currently in the **design phase**. The only artifact is `游戏化宠物养成系统设计方案.md` — the product design document (v1.0, 2026-04-20). No implementation code exists yet.

## Architecture (from Design Doc)

**Core concept**: "One Core, Three Pillars, Two Bonds"
- **1 Core**: Learning Energy System (学习能量系统) — all learning generates energy, all game content consumes it
- **3 Pillars**: Battle/Exploration System, Emotional Connection System, Collection/Achievement System
- **2 Bonds**: Subject-Specific Systems, Social Interaction System

### Subsystems by Priority

| Priority | Subsystems |
|----------|-----------|
| **P0** | Learning Energy, Exploration/Battle, Pet Raising, Subject Systems (3 subjects), Instant Feedback |
| **P1** | Achievement Medals, Social Interaction, Shop/Items, Daily Challenges |
| **P2** | Time-Space Rift System |

### Three Subject Worlds

- **语文 — 诗词大陆 (Poetry Continent)**: Chinese classical poetry themed. Gameplay: poetry recitation, comprehension quizzes, poetry creation, collection system. NPCs are historical poets.
- **数学 — 智慧王国 (Wisdom Kingdom)**: Math/logic themed. Gameplay: problem-solving, logical deduction, mathematical proofs. Features a "Wisdom Tower" progression system and equipment system.
- **英语 — 魔法学院 (Magic Academy)**: English language themed. Gameplay: vocabulary collection, "spell" learning (phrases), NPC dialogue practice. Weather system reflects learning status.

### Learning Energy Formula

```
Final Energy = Base Energy × Quality Multiplier × Difficulty Coefficient × Subject Coefficient
```

Where Quality Multiplier accounts for accuracy, time spent, and consecutive study days.

## Tech Stack

| Layer | Choice |
|-------|--------|
| Frontend | Vite + Svelte 5 (runes) + SvelteKit + Tailwind CSS |
| Backend | Spring Boot 3.2+ + Mybatis-Flex + Maven |
| Database | MySQL 8.0 (schema.sql via Spring Boot init) |
| Auth | JWT (jjwt 0.12.x, access + refresh tokens) |
| Communication | REST + STOMP over WebSocket (Phase 1 Sprint 6) |

## Project Structure

```
pet-grow-up/
├── frontend/                 # Vite + SvelteKit
│   └── src/
│       ├── routes/           # SvelteKit file-based routing
│       │   ├── (auth)/       # Login / Register
│       │   └── app/          # Authenticated app (/app, /app/study, /app/spirit)
│       └── lib/
│           ├── components/   # layout, spirit, study, energy, feedback, world, common
│           ├── stores/       # Svelte 5 rune state (auth.svelte.ts)
│           ├── api/          # Fetch wrapper + API client
│           └── types/        # TypeScript interfaces
├── backend/                  # Spring Boot + Mybatis-Flex
│   └── src/main/java/com/petgrowup/
│       ├── auth/             # JWT auth (entity, mapper, service, controller, dto)
│       ├── common/           # ApiResponse, exception handling, JwtUtil, EnergyCalculator
│       ├── config/           # SecurityConfig, WebConfig, JwtAuthFilter, WebSocketConfig
│       ├── energy/           # Learning energy system
│       ├── spirit/           # Pet/spirit system
│       ├── study/            # Exploration/quiz system
│       └── websocket/        # Real-time study updates
├── docker-compose.yml        # MySQL 8.0
└── .gitignore
