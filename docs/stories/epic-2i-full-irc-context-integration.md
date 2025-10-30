# Epic 2I: Full IRC Channel Context Integration

**Epic ID**: EPIC-2I
**Status**: In Progress
**Priority**: High
**Created**: 2025-01-XX
**Target Completion**: 1-2 weeks
**Related PRD**: [docs/prd.md](../prd.md)
**Depends on**: Epic 1 (RAG system validation and optimization complete)
**Note**: Must be completed before Epic 3. Uses "2I" designation to avoid conflict with Epic 2 (CAG) which has active branch `epic-2-reimplement-cag`.

---

## Epic Goal

Modify chat history management to capture all IRC channel messages and include the complete conversation context (all user messages and bot responses) in LLM prompts, rather than only storing and using LLM-generated responses.

---

## Epic Description

### Existing System Context

**Current Relevant Functionality**:
- IRC bot framework with chat history management
- Chat history stored only when LLM generates a response (`add_to_history` called after LLM response)
- History format: User/Assistant pairs stored in `@user_chat_histories`
- Context assembly includes chat history via `get_chat_context` method
- History excludes messages that don't trigger LLM responses (e.g., command messages like "next", "ready", etc.)

**Technology Stack**:
- Language: Ruby 3.1+
- IRC Framework: Cinch library for IRC bot functionality
- Chat History: Stored in `@user_chat_histories` hash structure
- Context Assembly: `assemble_prompt` method combines chat history with other context

**Integration Points**:
- bot_manager.rb - Chat history management and context assembly
- IRC message handlers - Capture all channel messages
- LLM prompt assembly - Include full conversation context

### Current Problem

**Existing Behavior**:
- Chat history is only added when `add_to_history` is called after an LLM response (lines 929, 937)
- Only messages that trigger LLM responses are stored
- Commands and other non-LLM messages are not captured in chat context
- When LLM responds, it only sees previous LLM exchanges, not the full IRC conversation

**Desired Behavior**:
- All IRC channel messages should be captured
- Full conversation context (all messages from all users and bots) should be included in LLM context
- LLM should see the complete conversation flow, including commands, bot responses, and all user messages

### Enhancement Details

**What's Being Added/Changed**:

1. **Comprehensive Message Capture**
   - Capture all IRC channel messages in chat history
   - Track messages from all users (not just the current user)
   - Store bot response messages (including non-LLM responses like "next", "ready", etc.)
   - Maintain chronological order of all messages

2. **Enhanced Chat History Structure**
   - Extend history format to include message metadata (timestamp, user, type)
   - Store message type classification (user message, bot LLM response, bot command response, system message)
   - Support multi-user conversation tracking
   - Optional filtering of message types for context inclusion

3. **Full Context Assembly**
   - Modify `get_chat_context` to return complete conversation thread
   - Include all channel messages in chronological order
   - Format messages clearly (e.g., "User alice: message", "Bot: response", "User bob: message")
   - Support configurable message history window (last N messages)

4. **IRC Message Tracking**
   - Add global message handler to capture all channel messages
   - Store messages in chronological order per channel/user
   - Track both user messages and bot responses
   - Handle message filtering (optional exclusion of certain message types)

5. **Context Formatting Enhancements**
   - Format full conversation context clearly for LLM consumption
   - Include message timestamps (optional)
   - Distinguish between different message types
   - Support compact vs. verbose formatting options

**How It Integrates**:
- Extends `bot_manager.rb` message handlers to capture all IRC messages
- Modifies `add_to_history` or creates new method to capture all messages (not just LLM-triggered)
- Enhances `get_chat_context` to return full conversation thread
- Updates `assemble_prompt` to include complete conversation context
- Maintains backward compatibility - existing history structure supported, new format is enhancement

**Success Criteria**:
- ✅ All IRC channel messages are captured and stored
- ✅ LLM context includes complete conversation history (all messages)
- ✅ Conversation context shows chronological flow of all participants
- ✅ Message format clearly identifies speakers (users, bot)
- ✅ Existing chat history functionality continues to work
- ✅ Configurable message history window size
- ✅ Optional filtering of message types (commands, system messages, etc.)

---

## Stories

### Story 2I.1: Capture All IRC Channel Messages
**Priority**: Critical
**Estimated Effort**: 2-3 days
**Dependencies**: None

**Brief Description**: Modify IRC message handlers to capture all channel messages, not just those that trigger LLM responses. Store messages with metadata (user, timestamp, type) in an enhanced chat history structure.

**Acceptance Criteria**:
- [x] Global message handler captures all IRC channel messages
- [x] Messages stored with metadata: user, timestamp, message type, content
- [x] Message types classified: user_message, bot_llm_response, bot_command_response, system_message
- [x] Messages stored per channel or per user (configurable)
- [x] Chronological ordering maintained
- [x] Unit tests verify message capture for all message types
- [x] Integration tests verify message storage across multiple users and messages

---

## Dev Agent Record

### Agent Model Used

Full Stack Developer (James) - Story 2I.1 Implementation

### Completion Notes

**Story 2I.1: Capture All IRC Channel Messages - COMPLETED**

All acceptance criteria have been implemented and verified through comprehensive testing.

**Implementation Summary:**

1. **Enhanced Chat History Structure** - Added `@irc_message_history` data structure to store messages with complete metadata:
   - User nickname
   - Message content
   - Timestamp
   - Message type classification
   - Channel information

2. **Message Type Classification** - Implemented `classify_message_type` method that automatically classifies messages as:
   - `:user_message` - Messages from users
   - `:bot_llm_response` - LLM-generated bot responses
   - `:bot_command_response` - Bot responses to commands (e.g., "next", "ready")
   - `:system_message` - System-level IRC messages

3. **Global Message Capture** - Added global message handler in bot creation that captures all IRC channel messages before they are processed by other handlers. This ensures all user messages are captured with metadata.

4. **Bot Response Capture** - Integrated message capture for bot responses, particularly:
   - LLM-generated responses (captured after generation)
   - Command responses (captured when bot replies to commands)

5. **Storage Configuration** - Messages are stored per user (configurable mode: `:per_user` or `:per_channel`) to maintain conversation history per user while supporting multi-user conversations.

6. **Chronological Ordering** - Messages are stored in chronological order using Ruby arrays, with timestamps for verification.

7. **Message History Management** - Added methods for:
   - `capture_irc_message` - Capture messages with metadata
   - `get_irc_message_history` - Retrieve message history
   - `clear_irc_message_history` - Clear history for cleanup
   - Automatic pruning when history exceeds max length

**Testing:**

- **Unit Tests** (19 tests, all passing): Verified message capture, type classification, chronological ordering, max length enforcement, multi-user support, and metadata completeness
- **Integration Tests** (7 tests, all passing): Verified multi-user conversations, mixed message types, chronological ordering across users, message isolation per bot, and conversation flow with commands and LLM responses

**Test Results:**
- Unit tests: 19 runs, 45 assertions, 0 failures
- Integration tests: 7 runs, 63 assertions, 0 failures
- Total: 26 tests, 108 assertions, all passing

### File List

**Modified Files:**
- `bot_manager.rb` - Added message capture infrastructure:
  - New `@irc_message_history` data structure for enhanced message storage
  - `@message_storage_mode` configuration for per-user or per-channel storage
  - `classify_message_type` method for automatic message type classification
  - `capture_irc_message` method for capturing messages with full metadata
  - `get_irc_message_history` method for retrieving message history
  - `clear_irc_message_history` method for cleanup
  - Global message handler in `create_bot` to capture all IRC messages
  - Bot response capture in LLM response handlers

**New Files Created:**
- `test/test_irc_message_capture.rb` - Unit tests for message capture functionality (19 tests)
- `test/test_irc_message_capture_integration.rb` - Integration tests for multi-user message storage (7 tests)

---

### Story 2I.2: Enhance Chat History Structure and Storage
**Priority**: Critical
**Estimated Effort**: 2-3 days
**Dependencies**: Story 2I.1

**Brief Description**: Redesign chat history storage to accommodate full conversation context. Update data structures to store all messages with metadata, supporting multi-user conversations and message type classification.

**Acceptance Criteria**:
- [ ] Chat history structure enhanced to store message metadata
- [ ] Support for multi-user conversation history
- [ ] Chronological ordering of messages maintained
- [ ] Message history window size configurable (default: last N messages)
- [ ] Backward compatibility: existing history format still supported
- [ ] History cleanup/pruning when exceeding max size
- [ ] Unit tests verify history structure and operations

---

### Story 2I.3: Update Context Assembly for Full Conversation
**Priority**: Critical
**Estimated Effort**: 2-3 days
**Dependencies**: Story 2I.2

**Brief Description**: Modify `get_chat_context` and `assemble_prompt` to include complete conversation context. Format all messages clearly for LLM consumption, showing full conversation flow with all participants.

**Acceptance Criteria**:
- [ ] `get_chat_context` returns complete conversation thread (all messages)
- [ ] Message formatting clearly identifies speakers: "User alice: ...", "Bot: ..."
- [ ] Chronological order of messages preserved in context
- [ ] LLM prompt includes full conversation context
- [ ] Configurable message filtering (which message types to include)
- [ ] Context length management (truncate oldest messages if needed)
- [ ] Integration tests verify full conversation context in LLM prompts

---

### Story 2I.4: Message Type Filtering and Configuration
**Priority**: Medium
**Estimated Effort**: 1-2 days
**Dependencies**: Story 2I.3

**Brief Description**: Add configuration options for filtering which message types are included in LLM context. Allow control over whether commands, system messages, and other message types are included in conversation context.

**Acceptance Criteria**:
- [ ] Configuration option for message type filtering
- [ ] XML/config option to specify which message types to include/exclude
- [ ] Default behavior: include all message types
- [ ] Message filtering respects configured rules
- [ ] Tests verify filtering works correctly
- [ ] Documentation on message type filtering options

---

## Compatibility Requirements

- [x] Existing APIs remain unchanged (optional parameters added)
- [x] Backward compatibility maintained - existing history format still works
- [x] Existing chat history clear/show commands continue to work
- [x] No breaking changes to context assembly interfaces
- [x] Performance impact is acceptable (efficient message storage and retrieval)

## Risk Mitigation

- **Primary Risk**: Performance degradation from storing all messages
  - **Mitigation**: Efficient data structures; configurable history window; message pruning when exceeding limits
- **Primary Risk**: Context size growth from including all messages
  - **Mitigation**: Configurable message window size; truncation of oldest messages; context length management in prompt assembly
- **Primary Risk**: Privacy concerns from storing all user messages
  - **Mitigation**: Clear documentation; opt-in/opt-out configuration; message filtering options
- **Primary Risk**: Breaking existing functionality
  - **Mitigation**: Backward compatibility maintained; gradual migration; existing chat history structure preserved
- **Rollback Plan**: Message capture can be disabled via configuration; existing behavior preserved as fallback

## Definition of Done

- [ ] All stories completed with acceptance criteria met
- [ ] All IRC channel messages are captured and stored
- [ ] LLM receives complete conversation context including all messages
- [ ] Existing chat history functionality verified through integration testing
- [ ] Performance impact is acceptable (no significant slowdown)
- [ ] No regression in existing features
- [ ] Code coverage maintained for new functionality
- [ ] Documentation updated (configuration guide, architecture docs)

---

## Notes

This epic addresses the core requirement of including the entire IRC conversation as context for LLM responses, rather than just LLM-triggered exchanges. This provides:

- **Better Context Awareness**: LLM sees complete conversation flow
- **Multi-User Support**: Can track conversations with multiple users
- **Command Awareness**: LLM understands what commands were issued and responses received
- **Natural Conversation Flow**: Context reflects actual IRC channel state

The implementation maintains backward compatibility while adding comprehensive message tracking and enhanced context assembly.

