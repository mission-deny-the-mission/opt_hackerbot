# Hackerbot Brownfield Enhancement PRD

**Version**: v1.0
**Date**: 2025-10-17
**Type**: LLM Feature Stabilization (Brownfield Enhancement)
**Status**: Draft

---

## Table of Contents

1. [Intro Project Analysis and Context](#1-intro-project-analysis-and-context)
2. [Requirements](#2-requirements)
3. [Technical Constraints and Integration Requirements](#3-technical-constraints-and-integration-requirements)
4. [Epic and Story Structure](#4-epic-and-story-structure)
5. [Epic 1: LLM Feature Stabilization](#5-epic-1-llm-feature-stabilization)

---

## 1. Intro Project Analysis and Context

### 1.1 Analysis Source

**Analysis Source**: IDE-based fresh analysis + existing documentation review

Analyzed documentation:
- README.md - Comprehensive project overview
- docs/development/architecture.md - Detailed architecture documentation
- docs/development/RAG_CAG_IMPLEMENTATION_SUMMARY.md - LLM feature documentation
- AGENTS.md - Development guide
- Core codebase structure and configuration

### 1.2 Current Project State

**Hackerbot** is a Ruby-based IRC bot framework designed for cybersecurity training exercises. It combines traditional attack simulation with modern AI capabilities.

**Current Functionality**:
- **LLM Integration**: Multiple provider support (Ollama, OpenAI, VLLM, SGLang) with streaming responses and per-user chat history
- **RAG System**: Retrieval-Augmented Generation using vector database for document retrieval and semantic search (functional)
- **CAG System**: Cache-Augmented Generation using knowledge graph for cached entity-based knowledge retrieval (currently non-functional - document loading issues)
- **Knowledge Bases**: MITRE ATT&CK framework, man pages, markdown files
- **Training Scenarios**: Progressive attack simulation with dynamic bot personalities
- **Deployment**: Service-based operation with offline/air-gapped support

**Primary Purpose**: Educational cybersecurity training platform providing realistic, AI-powered attack and defense scenarios in controlled lab environments

### 1.3 Available Documentation

**Existing Documentation Quality**: ✅ Excellent

**Available Documentation**:
- ✅ Tech Stack Documentation (README.md, AGENTS.md)
- ✅ Source Tree/Architecture (docs/development/architecture.md - comprehensive)
- ✅ API Documentation (docs/development/api-reference.md)
- ✅ Technical Implementation Summaries (RAG/CAG, multi-personality features)
- ✅ User Guides (configuration, deployment, user manual)
- ✅ Development Guide (docs/development/development-guide.md)
- ⚠️ UX/UI Guidelines (N/A - CLI/IRC interface)
- ⚠️ Technical Debt Documentation (implicit in code, not formally documented)

**Assessment**: No need to run document-project task - existing documentation is comprehensive and well-maintained.

### 1.4 Enhancement Scope Definition

**Enhancement Type**:
- ☑ **Bug Fix and Stability Improvements** (PRIMARY)
- ☑ **Major Feature Modification** (CAG system requires fixes/reimplementation)
- ☑ **Performance/Scalability Improvements** (RAG vs CAG performance comparison)

**Enhancement Description**:

This PRD documents the stabilization of recently-implemented LLM features (RAG and CAG systems) for the Hackerbot framework. The CAG (Cache-Augmented Generation) system currently fails to load and cache documents (man pages, lab sheets) into its knowledge graph, preventing performance testing and comparison with the functional RAG (Retrieval-Augmented Generation) system. This enhancement will diagnose and fix CAG issues, validate both systems through comprehensive testing, and provide performance comparison data between these two alternative knowledge enhancement approaches.

**Impact Assessment**:
- ☑ **Moderate to Significant Impact**
  - CAG subsystem requires diagnosis and potential reimplementation
  - Testing infrastructure needs expansion
  - Performance benchmarking required to compare RAG vs CAG approaches
  - Existing RAG system should remain largely untouched
  - Core IRC bot functionality unaffected

### 1.5 Goals and Background Context

**Goals**:
- Fix CAG document loading and caching functionality for man pages and lab sheets
- Create comprehensive test suites for both RAG and CAG systems
- Perform quantitative performance comparison between RAG and CAG approaches
- Determine which knowledge enhancement approach (RAG, CAG, or hybrid) is optimal for cybersecurity training use cases
- Validate chosen system(s) are production-ready for SecGen re-integration
- Document findings and architectural recommendations
- Establish baseline performance metrics for future optimization

**Background Context**:

The Hackerbot project recently implemented two alternative LLM knowledge enhancement approaches: RAG (Retrieval-Augmented Generation) and CAG (Cache-Augmented Generation). RAG uses vector embeddings and similarity search to retrieve relevant documents, while CAG uses cached knowledge structures for faster, pre-indexed knowledge retrieval. Both systems aim to enhance the quality and relevance of AI-powered training interactions, but they represent fundamentally different architectural approaches with different performance characteristics.

The RAG system appears functional but requires comprehensive validation testing. The CAG system, which should provide faster cached access to structured cybersecurity knowledge (especially man pages and lab sheets), has critical issues preventing document loading and caching. This prevents the critical performance comparison needed to determine which approach is better suited for cybersecurity training scenarios.

This enhancement is essential to complete the LLM integration feature set before re-integrating Hackerbot into the larger SecGen (Security Scenario Generator) project. The solo developer needs at least one system functional and validated to proceed. A 2-week time-box has been established for CAG fixes, with RAG-only mode as an acceptable fallback if CAG proves too complex to remediate.

**Important Note**: CAG does not necessarily require a knowledge graph implementation. A simpler approach using pre-cached prompts or fixed document structures may be more appropriate and easier to maintain.

### 1.6 Change Log

| Change | Date | Version | Description | Author |
|--------|------|---------|-------------|--------|
| Initial PRD Creation | 2025-10-17 | v1.0 | Brownfield PRD for LLM Feature Stabilization | PM Agent |
| Corrected CAG Definition | 2025-10-17 | v1.0 | Fixed CAG = Cache-Augmented Generation | PM Agent |

---

## 2. Requirements

### 2.1 Functional Requirements

**FR1**: The CAG system shall successfully load documents (man pages, lab sheets, markdown files) from configured knowledge sources into its cache mechanism.

**FR2**: The CAG system shall persist cached documents for subsequent retrieval without requiring reload on each query.

**FR3**: Both RAG and CAG systems shall provide knowledge-enhanced responses to user queries through their respective LLM integrations.

**FR4**: The system shall support independent enabling/disabling of RAG and CAG systems per bot configuration.

**FR5**: The system shall provide a test suite that validates RAG document retrieval accuracy and relevance.

**FR6**: The system shall provide a test suite that validates CAG cache loading, persistence, and retrieval functionality.

**FR7**: The system shall generate quantitative performance metrics comparing RAG and CAG approaches including response time, memory usage, and answer quality.

**FR8**: The system shall maintain existing IRC bot functionality, LLM provider integrations, and attack scenario features while CAG fixes are implemented.

**FR9**: The system shall support offline operation for both RAG and CAG systems without external API dependencies (when using Ollama).

**FR10**: The system shall document CAG architectural decisions including cache implementation approach (knowledge graph, pre-cached prompts, or alternative).

### 2.2 Non-Functional Requirements

**NFR1**: CAG system fixes must not degrade existing RAG system performance or functionality.

**NFR2**: Memory usage for CAG system shall not exceed 4GB for typical knowledge base sizes (1000+ documents).

**NFR3**: CAG cache loading time shall not exceed 60 seconds for initial knowledge base population.

**NFR4**: Both RAG and CAG query response times shall not exceed 5 seconds for typical cybersecurity training queries (excluding LLM inference time).

**NFR5**: Test suites shall achieve minimum 80% code coverage for RAG and CAG manager classes.

**NFR6**: Performance comparison testing shall include minimum 100 test queries covering diverse cybersecurity topics.

**NFR7**: All CAG fixes and new test code shall follow existing Ruby coding standards and conventions established in the codebase.

**NFR8**: CAG reimplementation decision (knowledge graph vs simpler caching) shall be documented with architectural rationale.

**NFR9**: System shall maintain backward compatibility with existing bot XML configurations.

**NFR10**: All changes shall be testable in the existing Nix development environment without additional infrastructure requirements.

### 2.3 Compatibility Requirements

**CR1: LLM Provider Compatibility**: CAG fixes shall maintain compatibility with all existing LLM providers (Ollama, OpenAI, VLLM, SGLang) without requiring provider-specific modifications.

**CR2: Configuration Compatibility**: Existing bot XML configurations shall continue to function without modification; new CAG configuration options shall be optional with sensible defaults.

**CR3: Knowledge Base Compatibility**: Both RAG and CAG systems shall support the same knowledge source types (MITRE ATT&CK, man pages, markdown files, lab sheets) through the base knowledge source interface.

**CR4: Offline Operation Compatibility**: CAG system shall maintain offline/air-gapped operation capability matching RAG system requirements for secure training environments.

**CR5: IRC Protocol Compatibility**: All enhancements shall maintain full compatibility with the existing IRC bot interface and command structure.

---

## 3. Technical Constraints and Integration Requirements

### 3.1 Existing Technology Stack

**Languages**: Ruby 3.1+

**Frameworks & Libraries**:
- **IRC**: ircinch (IRC bot framework)
- **XML Parsing**: nokogiri, nori
- **HTTP**: httparty (for LLM API calls)
- **Standard Library**: json, set, time, etc.

**LLM Providers**:
- Ollama (local, offline-capable)
- OpenAI API
- VLLM (open-source inference server)
- SGLang (fast LLM serving)

**Knowledge Enhancement Systems**:
- **RAG**: Vector database (ChromaDB in-memory), embedding services (OpenAI, Ollama)
- **CAG**: In-memory knowledge graph client (current implementation - may be replaced)

**Database**:
- In-memory data structures (no external database)
- Vector database: ChromaDB (in-memory mode)
- Knowledge graph: In-memory implementation (cag/in_memory_graph_client.rb)

**Infrastructure**:
- Ruby runtime via Nix development environment
- IRC server (custom Python implementation - simple_irc_server.py)
- Offline/air-gapped deployment support
- Service-based deployment (systemd or equivalent)

**External Dependencies**:
- Ollama server (optional, for local LLM)
- External LLM APIs (optional, based on provider choice)
- Man pages (system documentation)
- Knowledge base files (markdown, MITRE ATT&CK data)

**Development Environment**:
- Nix flakes for reproducible builds
- Local gem installation (.gems/ directory)
- Makefile for common operations
- Test suite (test/ directory)

### 3.2 Integration Approach

**Database Integration Strategy**:
- No traditional database required
- CAG system uses in-memory data structures for caching
- RAG system uses in-memory ChromaDB vector store
- Consideration: CAG may be reimplemented with simpler file-based caching or pre-loaded data structures instead of knowledge graph
- All data structures must support offline operation

**API Integration Strategy**:
- LLM providers accessed through factory pattern (llm_client_factory.rb)
- All LLM API calls go through abstract llm_client.rb interface
- CAG and RAG integrated via rag_cag_manager.rb unified coordinator
- No changes to LLM client interfaces required for CAG fixes

**Frontend Integration Strategy**:
- N/A - IRC text-based interface only
- Bot responses enhanced with RAG/CAG context transparently to users
- No UI changes required

**Testing Integration Strategy**:
- Test files in test/ directory following existing patterns
- New test files: test/test_rag_comprehensive.rb, test/test_cag_comprehensive.rb
- Performance comparison test: test/test_rag_cag_performance.rb
- Integration with existing test runner: test/run_tests.rb
- Tests must run in Nix development environment

### 3.3 Code Organization and Standards

**File Structure Approach**:
```
opt_hackerbot/
├── rag/                          # RAG system (minimal changes)
├── cag/                          # CAG system (fixes/reimplementation here)
│   ├── cag_manager.rb           # Main coordinator (fix or rewrite)
│   ├── in_memory_graph_client.rb # Current impl (may replace with simpler approach)
│   └── knowledge_graph_interface.rb
├── knowledge_bases/              # Knowledge sources (shared by RAG/CAG)
│   ├── sources/
│   │   ├── man_pages/           # Man page loading (needs fixes)
│   │   └── markdown_files/      # Markdown loading
├── test/                         # Test suites
│   ├── test_rag_comprehensive.rb     # New
│   ├── test_cag_comprehensive.rb     # New
│   └── test_rag_cag_performance.rb   # New
└── docs/                         # Documentation updates
```

**Naming Conventions**:
- Ruby snake_case for files, methods, variables
- CamelCase for class names
- Descriptive names following existing patterns (e.g., cag_manager.rb, test_cag_*.rb)

**Coding Standards**:
- Ruby 3.1+ idioms
- Error handling with rescue blocks and Print.err logging
- Factory pattern for component creation
- Interface-based abstractions (base classes with raise NotImplementedError)
- Configuration via XML files or hash parameters
- Offline-first design (graceful degradation when services unavailable)

**Documentation Standards**:
- Inline comments for complex logic
- Method-level documentation for public APIs
- Update docs/development/RAG_CAG_IMPLEMENTATION_SUMMARY.md with findings
- Architecture decisions documented in PRD and architecture docs

### 3.4 Deployment and Operations

**Build Process Integration**:
- No build step required (interpreted Ruby)
- Gem dependencies managed via Gemfile and local .gems/ directory
- Nix environment ensures reproducible dependencies

**Deployment Strategy**:
- Service-based deployment (systemd unit or equivalent)
- Offline deployment support (no external dependencies required)
- Configuration via XML files in config/ directory
- Knowledge bases deployed as files in knowledge_bases/ directory

**Monitoring and Logging**:
- Print utility class for structured logging (Print.info, Print.err, Print.debug)
- IRC bot logs to stdout/stderr
- Performance metrics collected during testing phase
- No external monitoring systems required

**Configuration Management**:
- Bot configuration: XML files in config/ directory
- RAG/CAG configuration: Embedded in bot XML or passed as hash
- Environment variables for IRC server, ports
- Knowledge source paths configurable per bot

### 3.5 Risk Assessment and Mitigation

**Technical Risks**:

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| CAG requires complete reimplementation beyond 2-week time-box | High | Medium | Time-box at 2 weeks; fallback to RAG-only mode |
| RAG has undiscovered issues during testing | Medium | Low | Test RAG early; address before comparison |
| Neither RAG nor CAG meets latency requirements | Medium | Low | Document findings; optimization becomes follow-on work |

**Integration Risks**:

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| CAG fixes break existing RAG functionality | High | Low | Comprehensive regression testing; isolate changes |
| Knowledge base loading issues affect both systems | High | Medium | Fix at knowledge source level; test both systems |

**Deployment Risks**:

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Nix environment issues prevent testing | Medium | Low | Document environment setup; test in clean shell |
| Offline operation breaks due to new dependencies | High | Low | Explicit requirement; test offline mode |

**Mitigation Strategies**:
1. **Time-boxing**: Hard 2-week limit on CAG fixes; decision point after diagnosis
2. **Incremental testing**: Test RAG first, then CAG, then comparison
3. **Architectural flexibility**: Open to simpler CAG implementation (pre-cached vs graph)
4. **Regression protection**: Run existing tests before and after changes
5. **Documentation**: Record all architectural decisions and trade-offs
6. **Fallback plan**: RAG-only mode is acceptable outcome

---

## 4. Epic and Story Structure

### 4.1 Epic Approach

**Epic Structure Decision**: Single comprehensive epic for LLM Feature Stabilization

**Rationale**:

This enhancement focuses on a cohesive goal (stabilizing and validating RAG/CAG systems) with clear dependencies between stories. The work is tightly coupled:
- CAG diagnosis informs fix approach
- Both systems need testing before comparison
- Performance comparison depends on both systems functional
- All work targets same outcome (production-ready knowledge enhancement)

A single epic provides clear progress tracking and logical story sequencing. Multiple epics would create artificial boundaries in what is fundamentally a unified stabilization effort.

**Estimated Timeline**: 2-4 weeks
- Week 1: CAG diagnosis and initial fixes
- Week 2: CAG completion or fallback decision
- Week 3: Comprehensive testing (RAG and CAG/RAG-only)
- Week 4: Performance comparison and documentation

---

## 5. Epic 1: LLM Feature Stabilization

**Epic Goal**: Stabilize and validate RAG and CAG knowledge enhancement systems, ensuring at least one production-ready approach for cybersecurity training use cases through comprehensive testing and performance comparison.

**Integration Requirements**:
- Maintain backward compatibility with existing bot configurations
- Preserve all LLM provider integrations (Ollama, OpenAI, VLLM, SGLang)
- Ensure offline operation capability throughout
- No breaking changes to IRC bot interface or attack scenario functionality

---

### Story 1.1: Diagnose CAG Document Loading Failures

As a **developer**,
I want to **identify the root causes preventing CAG from loading and caching documents**,
so that I can determine the most efficient fix approach (repair vs reimplementation).

**Acceptance Criteria**:
1. All code paths for document loading in cag_manager.rb are traced and documented
2. Failure points in man page and lab sheet loading are identified with specific error messages
3. In-memory graph client behavior is analyzed for caching issues
4. Knowledge source integration (knowledge_bases/sources/man_pages/) is validated
5. Root cause analysis document created listing all issues found
6. Recommendation made: repair existing implementation or reimplement with simpler approach
7. Time estimate provided for chosen fix approach

**Integration Verification**:
- **IV1**: Verify RAG system continues to function correctly during CAG diagnosis
- **IV2**: Verify existing bot configurations remain valid
- **IV3**: Verify no performance degradation to running systems during diagnostic testing

**Dependencies**: None (starting point)

**Estimated Effort**: 2-3 days

---

### Story 1.2: Implement CAG Fix or Simplified Reimplementation

As a **developer**,
I want to **fix CAG document loading based on diagnosis findings**,
so that the CAG system can cache and retrieve knowledge sources.

**Acceptance Criteria**:
1. CAG system successfully loads man pages from knowledge_bases/sources/man_pages/
2. CAG system successfully loads lab sheets (markdown files) from configured sources
3. Cached documents persist in memory for subsequent retrieval
4. CAG manager can retrieve cached content without reloading
5. Implementation approach documented (knowledge graph retained, simplified, or replaced)
6. Error handling implemented for missing or malformed documents
7. Basic functional testing passes (manual verification of load/retrieve cycle)

**Integration Verification**:
- **IV1**: Verify RAG system functionality unchanged
- **IV2**: Verify bot startup time remains acceptable (<60 seconds with typical knowledge base)
- **IV3**: Verify memory usage stays within bounds (NFR2: <4GB)

**Dependencies**: Story 1.1 (diagnosis complete)

**Estimated Effort**: 3-5 days (depends on approach - repair vs reimplement)

**Notes**:
- Time-boxed to align with 2-week CAG fix window
- If this story extends beyond 1 week, trigger decision point for RAG-only fallback

---

### Story 1.3: Create Comprehensive RAG Test Suite

As a **developer**,
I want to **create thorough automated tests for the RAG system**,
so that I can validate its correctness and establish performance baseline.

**Acceptance Criteria**:
1. Test file created: test/test_rag_comprehensive.rb
2. Tests cover document loading from all knowledge source types (MITRE ATT&CK, man pages, markdown)
3. Tests verify vector embedding generation and storage
4. Tests verify similarity search returns relevant results for sample queries
5. Tests validate RAG context formatting for LLM consumption
6. Edge cases tested: empty queries, no matches, large result sets
7. Test coverage >80% for rag/rag_manager.rb and related classes
8. All tests pass in Nix development environment

**Integration Verification**:
- **IV1**: Verify tests don't modify production knowledge bases
- **IV2**: Verify test execution time reasonable (<5 minutes for full suite)
- **IV3**: Verify tests can run offline (no external API dependencies for core functionality)

**Dependencies**: None (can run parallel to Story 1.2)

**Estimated Effort**: 2-3 days

---

### Story 1.4: Create Comprehensive CAG Test Suite

As a **developer**,
I want to **create thorough automated tests for the CAG system**,
so that I can validate the fixes and ensure reliable caching behavior.

**Acceptance Criteria**:
1. Test file created: test/test_cag_comprehensive.rb
2. Tests cover document loading and caching for all knowledge source types
3. Tests verify cache persistence (load once, retrieve multiple times)
4. Tests verify cache retrieval returns correct content for sample queries
5. Tests validate CAG context formatting for LLM consumption
6. Edge cases tested: cache misses, empty cache, large cache sizes
7. Test coverage >80% for cag/cag_manager.rb and related classes
8. All tests pass in Nix development environment

**Integration Verification**:
- **IV1**: Verify tests don't modify production knowledge bases
- **IV2**: Verify test execution time reasonable (<5 minutes for full suite)
- **IV3**: Verify tests can run offline

**Dependencies**: Story 1.2 (CAG fixes complete)

**Estimated Effort**: 2-3 days

**Notes**:
- If CAG fixes incomplete, adjust tests to document known failures
- If RAG-only fallback decided, this story may be cancelled

---

### Story 1.5: Implement RAG vs CAG Performance Comparison

As a **developer**,
I want to **quantitatively compare RAG and CAG system performance**,
so that I can make data-driven architectural decisions about which approach to use.

**Acceptance Criteria**:
1. Test file created: test/test_rag_cag_performance.rb
2. Test corpus created: 100+ diverse cybersecurity training queries
3. Metrics collected for both systems:
   - Query response time (excluding LLM inference)
   - Memory usage during operation
   - Cache/index load time
   - Result relevance (manual spot-check of sample results)
4. Performance report generated comparing both systems
5. Statistical analysis included (mean, median, p95 latency)
6. Memory profiling data captured
7. Recommendations documented based on findings

**Integration Verification**:
- **IV1**: Verify performance testing doesn't interfere with normal bot operation
- **IV2**: Verify test data representative of actual training scenarios
- **IV3**: Verify results reproducible across test runs

**Dependencies**: Story 1.3 (RAG tests), Story 1.4 (CAG tests)

**Estimated Effort**: 3-4 days

**Notes**:
- If RAG-only fallback decided, this becomes "RAG Performance Validation" instead of comparison
- Comparison may reveal neither system meets all requirements - document findings

---

### Story 1.6: Document Findings and Architectural Recommendations

As a **product manager**,
I want to **comprehensive documentation of test results and architectural recommendations**,
so that stakeholders can make informed decisions about SecGen integration.

**Acceptance Criteria**:
1. Update docs/development/RAG_CAG_IMPLEMENTATION_SUMMARY.md with findings
2. Performance comparison results documented with charts/tables
3. Architectural decision recorded: RAG-only, CAG-only, or hybrid approach recommended
4. Known issues and limitations documented for chosen approach
5. Recommendations for future optimization work documented
6. SecGen integration considerations documented
7. Baseline performance metrics established for future reference

**Integration Verification**:
- **IV1**: Verify documentation accuracy against actual test results
- **IV2**: Verify recommendations align with project constraints (offline, performance)
- **IV3**: Verify documentation useful for future developers

**Dependencies**: Story 1.5 (performance comparison complete)

**Estimated Effort**: 1-2 days

---

### Epic Success Criteria

✅ **Mandatory**:
- At least one system (RAG or CAG) is production-ready and tested
- Performance baseline established for chosen approach
- Comprehensive test suites in place
- Architectural decision documented with rationale

✅ **Preferred** (if time allows):
- Both RAG and CAG functional and tested
- Quantitative performance comparison complete
- Clear recommendation on which approach to use

✅ **Minimum Acceptable** (fallback):
- RAG system validated and tested
- CAG issues documented for future work
- RAG performance validated for SecGen integration

**Total Epic Estimated Effort**: 13-20 days (aligns with 2-4 week timeline)

---

## Appendix: Glossary

**RAG (Retrieval-Augmented Generation)**: Knowledge enhancement approach using vector embeddings and similarity search to retrieve relevant documents for LLM context.

**CAG (Cache-Augmented Generation)**: Alternative knowledge enhancement approach using pre-cached knowledge structures (potentially knowledge graphs, pre-cached prompts, or other caching mechanisms) for faster knowledge retrieval.

**SecGen (Security Scenario Generator)**: Larger project into which Hackerbot will be re-integrated after LLM feature stabilization.

**Ollama**: Local LLM inference server enabling offline operation.

**IRC (Internet Relay Chat)**: Text-based communication protocol used for bot-user interaction.

**MITRE ATT&CK**: Comprehensive knowledge base of adversary tactics and techniques used in cybersecurity training.

---

**End of PRD Document**
