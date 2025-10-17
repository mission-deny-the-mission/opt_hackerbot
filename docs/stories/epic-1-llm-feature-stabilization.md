# Epic 1: LLM Feature Stabilization

**Epic ID**: EPIC-1
**Status**: Not Started
**Priority**: High
**Created**: 2025-10-17
**Target Completion**: 2-4 weeks
**Related PRD**: [docs/prd.md](../prd.md)

---

## Epic Goal

Stabilize and validate RAG and CAG knowledge enhancement systems, ensuring at least one production-ready approach for cybersecurity training use cases through comprehensive testing and performance comparison.

---

## Epic Description

### Existing System Context

**Current Relevant Functionality**:
- IRC bot framework with multiple LLM provider support (Ollama, OpenAI, VLLM, SGLang)
- RAG (Retrieval-Augmented Generation) system using vector embeddings - functional but untested
- CAG (Cache-Augmented Generation) system using cached knowledge structures - non-functional (document loading failures)
- Knowledge bases: MITRE ATT&CK, man pages, markdown files, lab sheets
- Offline operation capability for air-gapped training environments

**Technology Stack**:
- Language: Ruby 3.1+
- Development: Nix environment with local gem management
- LLM Integration: Factory pattern with abstract llm_client interface
- Knowledge Enhancement: rag_cag_manager.rb coordinator
- Testing: Ruby test framework in test/ directory
- Deployment: Service-based (systemd), offline-capable

**Integration Points**:
- rag_cag_manager.rb - Unified RAG/CAG coordinator
- knowledge_bases/sources/ - Shared knowledge source loading
- cag/cag_manager.rb - CAG system coordinator (needs fixes)
- cag/in_memory_graph_client.rb - Current caching implementation (may be replaced)
- bot_manager.rb - IRC bot integration with RAG/CAG context

### Enhancement Details

**What's Being Added/Changed**:

1. **CAG System Fixes**: Diagnose and fix document loading failures in CAG system
   - Fix man page loading and caching
   - Fix lab sheet (markdown) loading and caching
   - May involve reimplementing with simpler caching approach (vs knowledge graph)
   - Time-boxed to 2 weeks with RAG-only fallback

2. **Comprehensive Testing**: Create test suites for both RAG and CAG systems
   - RAG test suite validating document retrieval and relevance
   - CAG test suite validating cache loading and retrieval
   - Performance comparison testing between RAG and CAG
   - 80% code coverage target for manager classes

3. **Performance Analysis**: Quantitative comparison to inform architectural decisions
   - Query response times (excluding LLM inference)
   - Memory usage profiles
   - Cache/index loading times
   - Result relevance evaluation
   - Minimum 100 test queries across cybersecurity topics

4. **Documentation**: Comprehensive findings and recommendations
   - Update RAG_CAG_IMPLEMENTATION_SUMMARY.md
   - Document architectural decision (RAG-only, CAG-only, or hybrid)
   - Establish performance baselines
   - SecGen integration considerations

**How It Integrates**:
- Fixes isolated to CAG subsystem (cag/ directory)
- Testing added to test/ directory following existing patterns
- Knowledge source fixes at knowledge_bases/sources/ level (shared)
- No changes to LLM client interfaces or IRC bot core
- Maintains backward compatibility with all existing configurations

**Success Criteria**:
- ✅ At least one system (RAG or CAG) is production-ready with comprehensive test coverage
- ✅ Performance baseline established and documented
- ✅ Architectural decision documented with data-driven rationale
- ✅ Existing IRC bot functionality and LLM integrations remain fully functional
- ✅ Offline operation capability maintained

---

## Stories

### Story 1.1: Diagnose CAG Document Loading Failures
**Priority**: Critical
**Estimated Effort**: 2-3 days
**Dependencies**: None

**Brief Description**: Trace all CAG document loading code paths, identify failure points in man page and lab sheet loading, analyze in-memory graph client caching behavior, and produce root cause analysis with fix approach recommendation (repair vs reimplement).

**File**: [story-1.1-diagnose-cag-loading.md](story-1.1-diagnose-cag-loading.md)

---

### Story 1.2: Implement CAG Fix or Simplified Reimplementation
**Priority**: Critical
**Estimated Effort**: 3-5 days
**Dependencies**: Story 1.1

**Brief Description**: Fix CAG document loading based on diagnosis findings. Implement solution (repair existing knowledge graph implementation or reimplement with simpler caching approach) to enable man page and lab sheet loading/caching.

**File**: [story-1.2-fix-cag-caching.md](story-1.2-fix-cag-caching.md)

**Notes**: Time-boxed to 1 week maximum. Trigger RAG-only fallback decision if work extends beyond this.

---

### Story 1.3: Create Comprehensive RAG Test Suite
**Priority**: High
**Estimated Effort**: 2-3 days
**Dependencies**: None (can run parallel to 1.2)

**Brief Description**: Create automated test suite (test/test_rag_comprehensive.rb) validating RAG document loading, vector embedding generation/storage, similarity search accuracy, and context formatting. Target 80% code coverage for rag/rag_manager.rb.

**File**: [story-1.3-create-rag-tests.md](story-1.3-create-rag-tests.md)

---

### Story 1.4: Create Comprehensive CAG Test Suite
**Priority**: High
**Estimated Effort**: 2-3 days
**Dependencies**: Story 1.2

**Brief Description**: Create automated test suite (test/test_cag_comprehensive.rb) validating CAG document loading/caching, cache persistence, retrieval accuracy, and context formatting. Target 80% code coverage for cag/cag_manager.rb.

**File**: [story-1.4-create-cag-tests.md](story-1.4-create-cag-tests.md)

**Notes**: If RAG-only fallback triggered, this story may be cancelled or deferred.

---

### Story 1.5: Implement RAG vs CAG Performance Comparison
**Priority**: High
**Estimated Effort**: 3-4 days
**Dependencies**: Stories 1.3, 1.4

**Brief Description**: Create performance comparison test (test/test_rag_cag_performance.rb) with 100+ cybersecurity queries. Collect metrics (query latency, memory usage, load time) for both systems. Generate statistical analysis and recommendations.

**File**: [story-1.5-performance-comparison.md](story-1.5-performance-comparison.md)

**Notes**: If RAG-only fallback triggered, becomes "RAG Performance Validation" instead of comparison.

---

### Story 1.6: Document Findings and Architectural Recommendations
**Priority**: Medium
**Estimated Effort**: 1-2 days
**Dependencies**: Story 1.5

**Brief Description**: Update docs/development/RAG_CAG_IMPLEMENTATION_SUMMARY.md with complete findings, performance data, architectural decision (RAG-only/CAG-only/hybrid), known issues, optimization recommendations, and SecGen integration considerations.

**File**: [story-1.6-document-findings.md](story-1.6-document-findings.md)

---

## Compatibility Requirements

### Must Maintain
- ✅ All existing LLM provider integrations (Ollama, OpenAI, VLLM, SGLang)
- ✅ Existing bot XML configurations continue to work without modification
- ✅ IRC protocol compatibility and bot interface unchanged
- ✅ Offline/air-gapped operation capability
- ✅ RAG system functionality during CAG fixes
- ✅ Bot startup performance (<60 seconds with typical knowledge base)

### Performance Constraints
- ✅ Memory usage ≤ 4GB for typical knowledge bases (1000+ documents)
- ✅ Cache loading time ≤ 60 seconds
- ✅ Query response time ≤ 5 seconds (excluding LLM inference)
- ✅ Test suite execution time ≤ 5 minutes per suite

### Code Standards
- ✅ Ruby 3.1+ idioms and conventions
- ✅ Existing error handling patterns (Print.err logging)
- ✅ Factory pattern for component creation
- ✅ Interface-based abstractions maintained
- ✅ Offline-first design principles

---

## Risk Mitigation

### Primary Risks

**Risk 1: CAG Requires Complete Reimplementation Beyond 2-Week Time-Box**
- **Impact**: High - blocks CAG performance comparison
- **Probability**: Medium - implementation quality concerns suggest significant issues
- **Mitigation**:
  - Hard 2-week time-box on CAG fixes
  - Decision point after Story 1.1 diagnosis
  - RAG-only fallback is acceptable outcome
  - Document CAG issues for future work

**Risk 2: CAG Fixes Break Existing RAG Functionality**
- **Impact**: High - destabilizes working system
- **Probability**: Low - good separation of concerns in architecture
- **Mitigation**:
  - Isolate CAG changes where possible
  - Run existing tests before and after changes
  - Integration verification in each story
  - Test RAG system early (Story 1.3)

**Risk 3: Knowledge Base Loading Issues Affect Both Systems**
- **Impact**: High - blocks both RAG and CAG
- **Probability**: Medium - man page loading is shared code
- **Mitigation**:
  - Fix at knowledge source level (knowledge_bases/sources/)
  - Test both systems after knowledge source fixes
  - Comprehensive edge case testing

**Risk 4: Neither RAG Nor CAG Meets Performance Requirements**
- **Impact**: Medium - affects SecGen integration timeline
- **Probability**: Low - systems showing acceptable basic performance
- **Mitigation**:
  - Document findings honestly
  - Optimization becomes follow-on work
  - Adjust requirements if needed based on data

### Rollback Plan

**If CAG fixes fail or exceed time-box**:
1. Document CAG issues comprehensively in Story 1.1/1.2
2. Proceed with RAG-only mode (cancel Story 1.4)
3. Story 1.5 becomes "RAG Performance Validation"
4. Document RAG as recommended approach with CAG as future work

**If RAG system has critical issues**:
1. Address RAG issues in Story 1.3 before proceeding
2. May extend timeline but RAG is functional baseline
3. Document any limitations or constraints

**If both systems have critical issues**:
1. Escalate to stakeholders
2. Re-evaluate LLM knowledge enhancement approach
3. Document findings for architectural review

---

## Definition of Done

### Epic Complete When:

- ✅ **Story Completion**: All stories completed with acceptance criteria met (or explicitly cancelled per fallback plan)
- ✅ **Testing**: Comprehensive test suites in place with ≥80% coverage for manager classes
- ✅ **System Validation**: At least one system (RAG or CAG) validated as production-ready
- ✅ **Performance Baseline**: Quantitative performance metrics established and documented
- ✅ **Architectural Decision**: Clear recommendation documented (RAG-only, CAG-only, or hybrid) with data-driven rationale
- ✅ **Regression Testing**: Existing IRC bot functionality verified through testing
- ✅ **Integration Points**: All integration points working correctly
- ✅ **Documentation**: docs/development/RAG_CAG_IMPLEMENTATION_SUMMARY.md updated with complete findings
- ✅ **Compatibility**: All compatibility requirements met (LLM providers, configs, offline operation)
- ✅ **No Regression**: Existing features function as before epic started

### Success Levels

**Mandatory (Minimum Acceptable)**:
- RAG system validated and tested
- CAG issues documented (if not fixable)
- RAG performance validated
- Decision documented: Proceed with RAG-only

**Preferred (Target Outcome)**:
- Both RAG and CAG functional and tested
- Quantitative performance comparison complete
- Clear data-driven recommendation on approach

**Stretch (Best Case)**:
- Both systems optimized and production-ready
- Hybrid approach identified with clear use cases
- Performance exceeds requirements
- Zero regressions, all systems operational

---

## Timeline and Milestones

### Week 1: Diagnosis and Initial Fixes
- **Days 1-3**: Story 1.1 - CAG diagnosis complete
- **Days 4-7**: Story 1.2 - CAG fixes underway

### Week 2: Complete Fixes and Begin Testing
- **Days 8-10**: Story 1.2 complete OR fallback decision made
- **Days 8-14**: Story 1.3 - RAG tests (parallel work)

### Week 3: Testing and Comparison
- **Days 15-17**: Story 1.4 - CAG tests (or skip if RAG-only)
- **Days 18-21**: Story 1.5 - Performance comparison

### Week 4: Documentation and Validation
- **Days 22-23**: Story 1.6 - Documentation
- **Days 24-28**: Buffer for issues, final validation

**Critical Decision Points**:
- **Day 3**: Post-diagnosis - Repair vs reimplement vs fallback
- **Day 10**: Mid-fix checkpoint - Continue CAG or trigger RAG-only fallback
- **Day 21**: Post-comparison - Final architectural recommendation

---

## Notes

- This epic is critical for SecGen re-integration timeline
- Solo developer has full implementation responsibility
- RAG-only outcome is acceptable - not a failure condition
- Maintain offline operation capability throughout (non-negotiable)
- CAG may pivot from knowledge graph to simpler caching approach
- Document all architectural decisions for future reference

---

## Related Documentation

- **PRD**: [docs/prd.md](../prd.md)
- **Architecture**: docs/development/architecture.md
- **Implementation Summary**: docs/development/RAG_CAG_IMPLEMENTATION_SUMMARY.md
- **Project Guide**: AGENTS.md
- **README**: README.md

---

**Epic Owner**: Development Team
**Reviewers**: PM (Product Manager), Architect, QA
