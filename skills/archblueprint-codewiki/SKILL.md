---
name: archwiki
description: "Generates comprehensive 4+1 Architecture Blueprint documentation for any codebase. Analyzes project structure, identifies architectural elements, and creates markdown wiki documents organized by Logical View, Process View, Development View, Physical View, and Scenarios (use cases). Produces Mermaid diagrams for each view. Use when the user wants to create architecture documentation, generate a deepwiki, analyze system architecture, or document a codebase using the 4+1 architectural views model."
model: claude-opus-4-6@20250213
license: MIT
metadata:
  author: Rovo Dev
  version: "1.0.0"
compatibility: Requires standard Unix tools (find, wc, grep). Optional ripgrep (rg) for faster code search.
---

# 4+1 Architecture Blueprint Wiki Generator

You are an expert software architect and technical writer. Your task is to analyze any codebase and generate a comprehensive architecture wiki using Philippe Kruchten's **"4+1" View Model of Software Architecture**. The output is a set of interconnected markdown documents saved to the `archwiki/` directory in the repository root.

## Background: The 4+1 View Model

The 4+1 model describes software architecture using five concurrent views, each addressing different stakeholder concerns:

| View | Stakeholders | Concerns | Components | Connectors |
|------|-------------|----------|------------|------------|
| **Logical** | End-user | Functionality | Classes, objects, packages | Association, inheritance, containment |
| **Process** | System integrator | Performance, scalability, fault-tolerance | Processes, tasks, threads | Messages, RPC, events, shared memory |
| **Development** | Programmers, managers | Organization, reuse, portability | Modules, subsystems, layers | Compilation dependencies, imports |
| **Physical** | System engineers | Deployment, topology, scalability | Nodes, containers, infrastructure | Network links, protocols |
| **Scenarios** | End-user, developer | Understandability, validation | Use cases, user stories | Interaction steps, scripts |

Scenarios (the "+1") tie all four views together and serve as both a driver for discovering architectural elements and a validation mechanism.

## Output Structure

Generate the following files in `./archwiki/`:

```
archwiki/
├── 0-Index.md                    # Table of contents and navigation
├── 1-Overview.md                 # Project overview and architecture summary
├── 2-Logical-View.md             # Object/class model, functional decomposition
├── 3-Process-View.md             # Concurrency, threading, runtime behavior
├── 4-Development-View.md         # Code organization, modules, layers, build
├── 5-Physical-View.md            # Deployment, infrastructure, hardware mapping
├── 6-Scenarios.md                # Key use cases tying all views together
├── 7-Architecture-Decisions.md   # Key design decisions and rationale
└── 8-Glossary.md                 # Terms, acronyms, definitions
```

## Workflow

### Phase 1: Project Discovery

**Objective**: Understand project structure, technology stack, and scope.

**Steps**:

1. **Get directory structure**:
```bash
find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/target/*' -not -path '*/__pycache__/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.next/*' -not -path '*/vendor/*' -not -path '*/.venv/*' -not -path '*/venv/*' | head -500
```

2. **Count files by type**:
```bash
find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/target/*' -not -path '*/__pycache__/*' | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20
```

3. **Read key files** (in priority order):
   - README.md or README files
   - Package/build configs: `package.json`, `Cargo.toml`, `pyproject.toml`, `pom.xml`, `go.mod`, `build.gradle`, `Makefile`
   - Entry points: `main.*`, `index.*`, `app.*`, `server.*`, `lib.*`
   - Configuration: `docker-compose.yml`, `Dockerfile`, `*.config.*`, `.env.example`

4. **Identify technology stack**: Languages, frameworks, databases, external services

5. **Map core source directories**: Identify the main source code locations and their purpose

### Phase 2: Deep Code Analysis

**Objective**: Extract architectural elements for each of the 4+1 views.

**Steps**:

1. **Analyze imports and dependencies** across key source files to build a dependency graph
2. **Identify domain abstractions**: Core classes, interfaces, traits, types, data models
3. **Identify runtime behavior**: Entry points, event loops, background workers, queues, message handlers
4. **Map module/package boundaries**: How source code is organized into subsystems and layers
5. **Identify deployment artifacts**: Docker images, binaries, services, infrastructure config
6. **Extract key workflows**: Main user-facing operations, API endpoints, CLI commands

Read at least the top 20-30 most important source files. Prioritize:
- Files with many imports (central to the system)
- Entry point files
- Configuration and wiring files
- Core domain/business logic files
- API/interface definition files

### Phase 3: Document Generation

Generate each document following the templates below. Use **Mermaid diagrams** extensively.

### Phase 4: Quality Review

After generating all documents:
- Verify all Mermaid diagram syntax is valid
- Ensure cross-references between documents are correct
- Check that Scenarios reference elements from all four views
- Confirm no placeholder text remains

---

## Document Templates

### 0-Index.md

```markdown
# Architecture Blueprint: [Project Name]

> 4+1 Architectural View Model documentation generated from codebase analysis.

## About This Documentation

This architecture wiki documents **[Project Name]** using Philippe Kruchten's
4+1 View Model. Each view addresses different stakeholder concerns and together
they provide a complete picture of the system architecture.

## Navigation

| Document | View | Audience | Description |
|----------|------|----------|-------------|
| [1. Overview](1-Overview.md) | — | Everyone | Project purpose, tech stack, architecture summary |
| [2. Logical View](2-Logical-View.md) | Logical | End-users, analysts | Domain model, key abstractions, class relationships |
| [3. Process View](3-Process-View.md) | Process | Integrators | Concurrency, threads, runtime behavior, data flow |
| [4. Development View](4-Development-View.md) | Development | Developers, managers | Code organization, modules, layers, build system |
| [5. Physical View](5-Physical-View.md) | Physical | DevOps, SREs | Deployment topology, infrastructure, scaling |
| [6. Scenarios](6-Scenarios.md) | Scenarios (+1) | Everyone | Key use cases that tie all views together |
| [7. Architecture Decisions](7-Architecture-Decisions.md) | — | Architects | Key design decisions and rationale |
| [8. Glossary](8-Glossary.md) | — | Everyone | Terms, acronyms, definitions |

## 4+1 View Model

The views relate to each other as follows:

```​mermaid
graph TB
    S((Scenarios))
    L[Logical View<br/>End-user: Functionality]
    D[Development View<br/>Programmers: Organization]
    P[Process View<br/>Integrators: Performance]
    PH[Physical View<br/>Engineers: Deployment]

    S --> L
    S --> D
    S --> P
    S --> PH
    L --> D
    P --> PH
```​

---
*Generated using the 4+1 Architecture Blueprint model.*
```

IMPORTANT: In the actual output, use real ```mermaid fences (the template above uses ```​mermaid with a zero-width space to avoid nesting issues in this skill file).

---

### 1-Overview.md

Generate a project overview covering:

1. **Project Identity**: Name, one-line description, purpose
2. **Problem Statement**: What problem does this project solve?
3. **Key Features**: 5-10 main capabilities extracted from code analysis
4. **Technology Stack**: Languages (with approximate %), frameworks, key libraries, infrastructure
5. **Architecture Summary**: One paragraph describing the overall architectural style (monolith, microservices, layered, event-driven, etc.)
6. **System Context Diagram**: A Mermaid diagram showing the system and its external actors/systems

The System Context diagram should use this pattern:

```
graph TB
    User1[fa:fa-user User Type 1]
    User2[fa:fa-user User Type 2]
    System["[Project Name]<br/>Brief description"]
    Ext1[("External System 1")]
    Ext2[("External System 2")]

    User1 -->|"uses"| System
    User2 -->|"manages"| System
    System -->|"reads/writes"| Ext1
    System -->|"calls"| Ext2

    style System fill:#1168bd,stroke:#0b4884,color:#fff
```

Include a table of architectural goals and constraints:

| Goal/Constraint | Description | Impact |
|----------------|-------------|--------|
| Performance | ... | Influences Process View |
| Portability | ... | Influences Development View |
| Scalability | ... | Influences Physical View |

---

### 2-Logical-View.md — The Logical Architecture

This is the **functional decomposition** of the system. It answers: *What does the system do?*

**Stakeholders**: End-users, business analysts, domain experts
**Concerns**: Functionality, domain model, key abstractions

Generate the following sections:

1. **Overview**: Brief description of the logical decomposition approach
2. **Key Abstractions**: The major domain objects, classes, interfaces, or types that form the core model
3. **Domain Model Diagram**: A Mermaid class diagram showing key abstractions and their relationships

```
classDiagram
    class DomainObject1 {
        +attribute1: Type
        +operation1()
        +operation2()
    }
    class DomainObject2 {
        +attribute1: Type
        +operation1()
    }
    DomainObject1 --> DomainObject2 : uses
    DomainObject1 --o DomainObject3 : contains
    DomainObject2 --|> BaseClass : inherits
```

4. **Functional Groupings**: Group related classes/modules into logical categories (similar to "class categories" in the original 4+1 paper). For each group:
   - Name and purpose
   - Key abstractions within it
   - Responsibilities
   - Relationships to other groups

5. **Functional Groupings Diagram**: A high-level Mermaid diagram showing the logical groups and their relationships:

```
graph TB
    subgraph "Group A"
        A1[Abstraction 1]
        A2[Abstraction 2]
    end
    subgraph "Group B"
        B1[Abstraction 3]
        B2[Abstraction 4]
    end
    A1 --> B1
    A2 --> B2
```

6. **Key Mechanisms**: Common patterns, utilities, or cross-cutting services used across the system (e.g., error handling, logging, configuration, authentication)

7. **Design Patterns**: Identify and document any recognized design patterns (Observer, Strategy, Factory, Repository, etc.)

---

### 3-Process-View.md — The Process Architecture

This captures **runtime behavior**: concurrency, synchronization, distribution, and fault-tolerance.

**Stakeholders**: System integrators, performance engineers
**Concerns**: Performance, availability, fault-tolerance, scalability, concurrency

Generate the following sections:

1. **Overview**: How the system behaves at runtime — is it single-process, multi-threaded, event-driven, distributed?

2. **Process Inventory**: List all major processes, services, or runtime components:

| Process/Service | Type | Purpose | Communication |
|----------------|------|---------|---------------|
| Web Server | Long-running | Handles HTTP requests | REST API |
| Background Worker | Long-running | Processes async jobs | Message queue |
| CLI | Short-lived | User commands | Stdin/stdout |

3. **Concurrency Model**: Describe threading model, async patterns, event loops, worker pools

4. **Process Communication Diagram**: Mermaid diagram showing how processes/services communicate:

```
graph LR
    Client[Client] -->|HTTP| WebServer[Web Server]
    WebServer -->|enqueue| Queue[(Message Queue)]
    Queue -->|dequeue| Worker[Background Worker]
    Worker -->|write| DB[(Database)]
    WebServer -->|read/write| DB
```

5. **Key Runtime Workflows**: For the 2-3 most critical operations, show sequence diagrams:

```
sequenceDiagram
    participant User
    participant API
    participant Service
    participant DB

    User->>API: Request
    API->>Service: Process
    Service->>DB: Query
    DB-->>Service: Result
    Service-->>API: Response
    API-->>User: Result
```

6. **Synchronization and State Management**: How shared state is managed, locking strategies, caching

7. **Error Handling and Fault Tolerance**: Recovery strategies, retry logic, circuit breakers, graceful degradation

8. **Performance Characteristics**: Identify hot paths, bottlenecks, scaling dimensions

---

### 4-Development-View.md — The Development Architecture

This describes the **static organization** of the software in its development environment.

**Stakeholders**: Programmers, software managers
**Concerns**: Code organization, reuse, portability, build process, team structure

Generate the following sections:

1. **Overview**: How the codebase is organized — monorepo, multi-package, workspace structure

2. **Module/Package Structure**: Complete listing of major modules with their purpose:

| Module/Package | Purpose | Key Files | Dependencies |
|---------------|---------|-----------|--------------|
| `src/core/` | Core domain logic | ... | ... |
| `src/api/` | HTTP API layer | ... | core |
| `src/db/` | Data persistence | ... | core |

3. **Layer Diagram**: Show the layered architecture using a Mermaid diagram:

```
graph TB
    subgraph "Layer 5: Presentation"
        UI[UI / CLI / API Routes]
    end
    subgraph "Layer 4: Application"
        App[Application Services]
    end
    subgraph "Layer 3: Domain"
        Domain[Domain Logic / Business Rules]
    end
    subgraph "Layer 2: Infrastructure"
        Infra[Database / External Services / IO]
    end
    subgraph "Layer 1: Foundation"
        Found[Utilities / Common / Config]
    end

    UI --> App
    App --> Domain
    Domain --> Infra
    Infra --> Found
```

Adapt the number and names of layers to match the actual project (typically 3-6 layers).

4. **Dependency Graph**: A Mermaid diagram showing inter-module dependencies:

```
graph LR
    A[module-a] --> B[module-b]
    A --> C[module-c]
    B --> D[module-d]
    C --> D
```

5. **Build System**: How the project is built, tested, and packaged. Include:
   - Build tool and commands
   - Test framework and test organization
   - Linting and formatting tools
   - CI/CD pipeline overview (if detectable)

6. **Third-Party Dependencies**: Key external libraries and their role:

| Dependency | Version | Purpose | Category |
|-----------|---------|---------|----------|
| express | ^4.18 | HTTP server | Framework |
| prisma | ^5.0 | ORM / DB access | Data |

7. **Development Guidelines**: Inferred coding conventions, patterns, naming conventions observed in the codebase

---

### 5-Physical-View.md — The Physical Architecture

This describes the **deployment topology** — how software maps onto hardware/infrastructure.

**Stakeholders**: System engineers, DevOps, SREs
**Concerns**: Availability, reliability, performance, scalability, topology

Generate the following sections:

1. **Overview**: Deployment model — local binary, containerized, cloud-native, serverless, hybrid

2. **Deployment Diagram**: Mermaid diagram showing how the system is deployed:

```
graph TB
    subgraph "Cloud / Production"
        subgraph "Load Balancer"
            LB[Nginx / ALB]
        end
        subgraph "Application Tier"
            App1[App Instance 1]
            App2[App Instance 2]
        end
        subgraph "Data Tier"
            DB[(Primary DB)]
            Cache[(Redis Cache)]
        end
    end

    Internet[Internet] --> LB
    LB --> App1
    LB --> App2
    App1 --> DB
    App2 --> DB
    App1 --> Cache
    App2 --> Cache
```

3. **Infrastructure Components**:

| Component | Technology | Purpose | Scaling Strategy |
|-----------|-----------|---------|-----------------|
| App Server | Node.js in Docker | Business logic | Horizontal |
| Database | PostgreSQL | Persistence | Vertical + replicas |
| Cache | Redis | Session + cache | Cluster |

4. **Network Topology**: Communication paths, protocols, ports, security boundaries

5. **Configuration Management**: Environment variables, config files, secrets management approach

6. **Scaling Considerations**: How the system scales — horizontal vs vertical, stateless components, data partitioning

7. **Development vs Production**: Differences between local dev setup and production deployment

If the project is a library/CLI tool with no deployment infrastructure, simplify this view to cover:
- Distribution mechanism (npm, crates.io, PyPI, etc.)
- Installation and runtime requirements
- Platform compatibility

---

### 6-Scenarios.md — Scenarios (Use Cases)

Scenarios are the "+1" that **ties all four views together**. Each scenario traces through the Logical, Process, Development, and Physical views.

**Stakeholders**: All — end-users, developers, architects, operators
**Concerns**: Understandability, architectural validation

Generate the following sections:

1. **Overview**: Explain that scenarios validate the architecture by showing how the four views work together

2. **Scenario Catalog**: List 3-6 key scenarios (the most important use cases):

| # | Scenario | Actors | Views Touched |
|---|----------|--------|---------------|
| 1 | User creates an account | End-user, API, DB | All |
| 2 | System processes a job | Worker, Queue, DB | Process, Physical |
| 3 | Developer adds a feature | Developer | Development |

3. **Detailed Scenarios**: For each scenario, provide:

#### Scenario N: [Name]

**Actors**: [Who is involved]
**Preconditions**: [What must be true before]
**Flow**:

```
sequenceDiagram
    participant Actor
    participant Component1
    participant Component2
    participant Component3

    Actor->>Component1: Step 1 action
    Component1->>Component2: Step 2 action
    Component2->>Component3: Step 3 action
    Component3-->>Component2: Step 4 response
    Component2-->>Component1: Step 5 response
    Component1-->>Actor: Step 6 result
```

**Architectural Trace**:
- **Logical View**: Which domain abstractions are involved (reference 2-Logical-View.md)
- **Process View**: Which processes/threads execute this (reference 3-Process-View.md)
- **Development View**: Which modules contain the code (reference 4-Development-View.md)
- **Physical View**: Which nodes/containers are involved (reference 5-Physical-View.md)

**Postconditions**: [What is true after]
**Error Cases**: [What can go wrong and how it's handled]

4. **Scenario Coverage Matrix**: Show which architectural elements are exercised by which scenarios:

| Architectural Element | Scenario 1 | Scenario 2 | Scenario 3 |
|----------------------|:---:|:---:|:---:|
| Component A | ✓ | ✓ | |
| Component B | ✓ | | ✓ |
| Database | ✓ | ✓ | |

---

### 7-Architecture-Decisions.md

Document key architectural decisions using a lightweight ADR (Architecture Decision Record) format:

1. **Overview**: Explain that these decisions shape the architecture

2. **Decision Log**: For each significant decision found in the codebase:

#### ADR-N: [Decision Title]

- **Status**: Accepted / Proposed / Deprecated
- **Context**: What is the problem or situation?
- **Decision**: What was decided?
- **Rationale**: Why was this chosen over alternatives?
- **Consequences**: What are the trade-offs?
- **Affected Views**: Which architectural views are impacted?

Infer decisions from:
- Choice of language and framework
- Database technology selection
- API style (REST, GraphQL, gRPC)
- Authentication approach
- Deployment strategy (containers, serverless)
- State management approach
- Testing strategy
- Monolith vs microservices
- Monorepo vs multi-repo

---

### 8-Glossary.md

Generate a glossary of terms, acronyms, and project-specific jargon discovered during analysis:

| Term | Definition |
|------|-----------|
| ... | ... |

Include both domain-specific terms and technical terms relevant to the architecture.

---

## Mermaid Diagram Guidelines

1. **Keep diagrams focused**: Maximum 12-15 nodes per diagram. Split larger diagrams.
2. **Use consistent styling**: Apply `style` directives for the main system component.
3. **Label all relationships**: Every arrow should have a label describing the interaction.
4. **Use appropriate diagram types**:
   - `graph TB/LR` for architecture and dependency diagrams
   - `classDiagram` for domain models in Logical View
   - `sequenceDiagram` for scenarios and runtime workflows
   - `flowchart` for data flow and process pipelines
5. **Test syntax**: Ensure all diagrams use valid Mermaid syntax. Avoid special characters in labels that could break rendering.
6. **Use subgraphs** to group related components visually.

## Writing Style Guidelines

1. **Be concrete and specific**: Use actual names from the codebase — real class names, file paths, module names. Never use placeholder text.
2. **Evidence-based**: Every claim must be traceable to code you read. If you're uncertain, say so.
3. **Professional but accessible**: Write for both technical and non-technical audiences where possible.
4. **Progressive detail**: Start each document with a high-level overview, then drill into details.
5. **Cross-reference extensively**: Link between documents (e.g., "See [Logical View](2-Logical-View.md) for the domain model").
6. **Quantify where possible**: Number of modules, lines of code, number of endpoints, etc.

## Execution Steps

1. Create the `archwiki/` directory in the repository root
2. Execute Phase 1 (Project Discovery) — scan files, read configs, identify tech stack
3. Execute Phase 2 (Deep Code Analysis) — read key source files, extract architectural elements
4. Generate `0-Index.md` — table of contents
5. Generate `1-Overview.md` — project overview and system context
6. Generate `2-Logical-View.md` — domain model and functional decomposition
7. Generate `3-Process-View.md` — runtime behavior and concurrency
8. Generate `4-Development-View.md` — code organization and layers
9. Generate `5-Physical-View.md` — deployment topology
10. Generate `6-Scenarios.md` — key use cases tracing through all views
11. Generate `7-Architecture-Decisions.md` — key design decisions
12. Generate `8-Glossary.md` — terms and definitions
13. Execute Phase 4 (Quality Review) — verify diagrams, cross-references, completeness
14. Report results to user

## Tailoring the Model

Per Kruchten's original paper, not all projects need the full 4+1 views:

- **Single-process CLI/library**: Simplify Process View to describe internal concurrency only. Simplify Physical View to distribution/installation.
- **Pure library with no deployment**: Physical View covers packaging and distribution instead of infrastructure.
- **Simple single-tier application**: Logical and Development views may overlap significantly — note this and avoid redundancy.
- **Serverless/FaaS**: Process View focuses on function invocation patterns. Physical View covers cloud provider topology.

Always generate all documents, but adapt depth to what's relevant for the specific project.

## Error Handling

- If a source file cannot be read, skip it and note the gap
- If a view has limited information (e.g., no deployment config for Physical View), generate a minimal version and note the limitation
- If the codebase is very large (>1000 files), focus on the most architecturally significant modules
- Always produce all 9 documents, even if some are brief

## Completion Message

After generating all documents, output:

```
✅ 4+1 Architecture Blueprint generated!

Project: [Project Name]
Output:  ./archwiki/

Generated documents:
  ├── 0-Index.md                    (Navigation & overview)
  ├── 1-Overview.md                 (Project summary & system context)
  ├── 2-Logical-View.md             (Domain model & functional groups)
  ├── 3-Process-View.md             (Runtime behavior & concurrency)
  ├── 4-Development-View.md         (Code organization & layers)
  ├── 5-Physical-View.md            (Deployment & infrastructure)
  ├── 6-Scenarios.md                (Key use cases across all views)
  ├── 7-Architecture-Decisions.md   (Design decisions & rationale)
  └── 8-Glossary.md                 (Terms & definitions)

Stats:
  - Documents: 9
  - Mermaid diagrams: [N]
  - Source files analyzed: [N]
  - Architectural elements identified: [N]

View: cat ./archwiki/0-Index.md
```

## Important Notes

- All analysis is done by reading the codebase directly — no external API calls required
- Focus on architecturally significant elements, not implementation details
- Base everything on evidence from the code — do not invent features
- Use Mermaid for all diagrams — no external image dependencies
- Keep each document self-contained but cross-referenced
- The Scenarios document is the most important — it validates that the four views are consistent
- Adapt the level of detail to the project size and complexity
