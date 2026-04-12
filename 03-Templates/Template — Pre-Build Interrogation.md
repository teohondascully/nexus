# Template — Pre-Build Interrogation

> Answer these 5 questions IN ORDER before touching code. Each one constrains the next. Skip one and you'll refactor later.

---

## 1. What is the core loop?

> Every product has one atomic action that users repeat.

**Format:** `User does X → system does Y → user gets Z`

**My answer:**


---

## 2. Who are the actors and what are their trust levels?

| Actor | Type | Can Read | Can Write | Can Delete |
|-------|------|----------|-----------|------------|
| | End user | | | |
| | Admin | | | |
| | External service | | | |
| | Background process | | | |

---

## 3. What are the data entities and their relationships?

**Core entities (3-5):**
1. 
2. 
3. 
4. 
5. 

**Relationships:**
- 

**Access patterns:**
- Read-heavy or write-heavy?
- What's queried by time range?
- What needs full-text search?
- What's relational vs. document/blob?

---

## 4. What are the failure modes?

| Scenario | Severity | Mitigation |
|----------|----------|------------|
| Database down 30s | | |
| Third-party API timeout | | |
| Double submission | | |
| Bad migration deployed | | |
| 10x traffic spike | | |
| Background job fails midway | | |

**Which ones would kill me?** →

---

## 5. What's the deployment topology?

- Single region or multi-region?
- Environments: local → staging → production (minimum)
- Rollback story:
- Data migration story:
- Monolith or services? (Start monolith.)

---

## Now What?
1. Write your [[Template — CLAUDE.md|CLAUDE.md]] based on these answers
2. Build [[The 15 Universal Layers|Foundation layers]] in the [[🗺️ Foundations MOC#Build Sequence|build sequence]]
3. Start with Layer 1 (repo structure) and work down

---

#templates #foundations #phase-0
