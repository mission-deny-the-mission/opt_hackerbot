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
- [x] Chat history structure enhanced to store message metadata
- [x] Support for multi-user conversation history
- [x] Chronological ordering of messages maintained
- [x] Message history window size configurable (default: last N messages)
- [x] Backward compatibility: existing history format still supported
- [x] History cleanup/pruning when exceeding max size
- [x] Unit tests verify history structure and operations

## Dev Agent Record

### Agent Model Used

Full Stack Developer (James) - Story 2I.2 Implementation

### Completion Notes

**Story 2I.2: Enhance Chat History Structure and Storage - COMPLETED**

All acceptance criteria have been implemented and verified through comprehensive testing.

**Implementation Summary:**

1. **Configurable History Window Sizes** - Enhanced chat history system with separate configurable limits:
   - `@max_history_length` (default: 10) - For traditional chat history (user/assistant pairs)
   - `@max_irc_message_history` (default: 20) - For enhanced IRC message history
   - Both can be configured per-bot via XML configuration (`max_history_length` and `max_irc_message_history` elements)

2. **XML Configuration Support** - Added parsing for history window size configuration in `read_bots`:
   - `<max_history_length>` - Sets traditional chat history limit per bot
   - `<max_irc_message_history>` - Sets IRC message history limit per bot
   - Defaults are used if not specified in XML

3. **Enhanced History Pruning** - Added dedicated pruning methods:
   - `prune_irc_message_history(bot_name, force)` - Prune IRC message history to max length
   - `prune_chat_history(bot_name, user_id)` - Prune traditional chat history (can target specific user or all users)
   - Both methods respect bot-specific configuration or fall back to defaults

4. **Backward Compatibility Maintained** - Existing chat history functionality continues to work:
   - `add_to_history` method updated to respect bot-specific `max_history_length`
   - `get_chat_context` continues to work with traditional format
   - Both history systems operate independently with their own limits

5. **Improved Automatic Pruning** - Enhanced `capture_irc_message` and `add_to_history` to:
   - Check bot-specific configuration before applying default limits
   - Automatically prune when limits are exceeded
   - Maintain chronological ordering during pruning

6. **Multi-User Support Enhanced** - Both history systems support:
   - Per-user history isolation
   - Independent history limits per user
   - Configurable storage modes (per_user or per_channel)

**Testing:**

- **New Comprehensive Tests** (14 tests in `test_enhanced_chat_history_structure.rb`):
  - Configurable history window size verification
  - Bot-specific history limits
  - Backward compatibility with traditional history
  - History pruning for both systems
  - Multi-user history isolation
  - Independent history limits
  - Empty history handling
  - Message structure consistency

- **Updated Existing Tests**:
  - Fixed `test_capture_irc_message_max_length_enforcement` to use new `@max_irc_message_history`
  - Fixed integration test to use correct max length variable

**Test Coverage:**
- All acceptance criteria verified through unit tests
- Backward compatibility tested and confirmed
- Configuration parsing tested
- Pruning functionality verified
- Multi-user scenarios validated

### File List

**Modified Files:**
- `bot_manager.rb` - Enhanced chat history structure:
  - Added `@max_irc_message_history` instance variable (default: 20)
  - Updated `capture_irc_message` to use bot-specific `max_irc_message_history` config
  - Updated `add_to_history` to use bot-specific `max_history_length` config
  - Added `prune_irc_message_history` method for IRC history pruning
  - Added `prune_chat_history` method for traditional history pruning
  - Added XML parsing for `max_history_length` and `max_irc_message_history` in `read_bots`

- `test/test_irc_message_capture.rb` - Updated to use `@max_irc_message_history` instead of `@max_history_length * 2`

- `test/test_irc_message_capture_integration.rb` - Updated to use `@max_irc_message_history`

**New Files Created:**
- `test/test_enhanced_chat_history_structure.rb` - Comprehensive unit tests for Story 2I.2 (14 tests covering all acceptance criteria)

---

### Story 2I.3: Update Context Assembly for Full Conversation
**Priority**: Critical
**Estimated Effort**: 2-3 days
**Dependencies**: Story 2I.2

**Brief Description**: Modify `get_chat_context` and `assemble_prompt` to include complete conversation context. Format all messages clearly for LLM consumption, showing full conversation flow with all participants.

**Acceptance Criteria**:
- [x] `get_chat_context` returns complete conversation thread (all messages)
- [x] Message formatting clearly identifies speakers: "User alice: ...", "Bot: ..."
- [x] Chronological order of messages preserved in context
- [x] LLM prompt includes full conversation context
- [x] Configurable message filtering (which message types to include)
- [x] Context length management (truncate oldest messages if needed)
- [x] Integration tests verify full conversation context in LLM prompts

## Dev Agent Record

### Agent Model Used

Full Stack Developer (James) - Story 2I.3 Implementation

### Completion Notes

**Story 2I.3: Update Context Assembly for Full Conversation - COMPLETED**

All acceptance criteria have been implemented and verified through comprehensive testing.

**Implementation Summary:**

1. **Enhanced `get_chat_context` Method** - Completely redesigned to return full conversation context from IRC message history:
   - Retrieves messages from IRC history instead of (or as fallback to) traditional chat history
   - Supports both `:per_user` and `:per_channel` storage modes
   - In per_user mode: merges messages from both user and bot, sorted chronologically
   - In per_channel mode: retrieves all messages from the channel
   - Maintains backward compatibility - falls back to traditional format when no IRC history exists

2. **Clear Speaker Identification** - Messages formatted with explicit speaker labels:
   - `"User {nickname}:"` for user messages
   - `"Bot:"` for bot LLM responses and command responses
   - `"System:"` for system messages
   - Optional timestamp formatting with `include_timestamps` option

3. **Chronological Order Preservation** - Messages sorted by timestamp to maintain conversation flow:
   - Merges user and bot messages in per_user mode using timestamp sorting
   - Preserves message order from capture time
   - Ensures conversation context reflects actual IRC conversation timeline

4. **Configurable Message Filtering** - Added flexible filtering options:
   - `include_types` parameter accepts array of message types (`:user_message`, `:bot_llm_response`, `:bot_command_response`, `:system_message`)
   - Default includes user messages, LLM responses, and command responses (excludes system messages)
   - Allows fine-grained control over which message types appear in context

5. **Context Length Management** - Added intelligent truncation:
   - `max_context_length` parameter limits total context size in characters
   - Truncates oldest messages when limit exceeded
   - Attempts to truncate at message boundaries (after newlines) to avoid cutting messages mid-sentence
   - Adds truncation marker: `"... (earlier messages truncated) ..."` when truncation occurs

6. **Current Message Exclusion** - Prevents duplication:
   - `exclude_message` parameter allows excluding the current message from context
   - Prevents duplicate inclusion when current message is already captured by global handler
   - Updated all `get_chat_context` calls in LLM response handlers to exclude current message

7. **Integration with `assemble_prompt`** - Verified compatibility:
   - `assemble_prompt` already properly includes chat context via `Chat History:` section
   - New formatted context integrates seamlessly with existing prompt assembly
   - Full conversation flow now visible to LLM in generated prompts

**Testing:**

- **New Comprehensive Tests** (11 tests in `test_full_conversation_context.rb`):
  - Complete conversation thread retrieval
  - Speaker identification formatting
  - Chronological order preservation
  - Full conversation in LLM prompts
  - Configurable message filtering
  - Context length management and truncation
  - Current message exclusion
  - Backward compatibility with traditional history
  - Per-channel mode support
  - Multi-user conversation support
  - Optional timestamp formatting

**Key Features:**

- **Message Merging**: In per_user mode, automatically merges messages from user and bot for complete conversation view
- **Flexible Filtering**: Programmatic control over which message types appear in context
- **Smart Truncation**: Intelligent truncation that respects message boundaries
- **No Breaking Changes**: Maintains full backward compatibility with existing code
- **Performance Optimized**: Efficient sorting and filtering using Ruby array operations

### File List

**Modified Files:**
- `bot_manager.rb` - Enhanced `get_chat_context` method:
  - Returns complete conversation thread from IRC message history
  - Supports message type filtering via `include_types` parameter
  - Supports context length management via `max_context_length` parameter
  - Supports timestamp inclusion via `include_timestamps` parameter
  - Supports current message exclusion via `exclude_message` parameter
  - Handles both per_user and per_channel storage modes
  - Merges user and bot messages in per_user mode with chronological sorting
  - Formats messages with clear speaker identification
  - Updated LLM response handler to exclude current message from context

**New Files Created:**
- `test/test_full_conversation_context.rb` - Comprehensive unit tests for Story 2I.3 (11 tests covering all acceptance criteria)

---

### Story 2I.4: Message Type Filtering and Configuration
**Priority**: Medium
**Estimated Effort**: 1-2 days
**Dependencies**: Story 2I.3

**Brief Description**: Add configuration options for filtering which message types are included in LLM context. Allow control over whether commands, system messages, and other message types are included in conversation context.

**Acceptance Criteria**:
- [x] Configuration option for message type filtering
- [x] XML/config option to specify which message types to include/exclude
- [x] Default behavior: include all message types except system messages (configurable)
- [x] Message filtering respects configured rules
- [x] Tests verify filtering works correctly
- [x] Documentation on message type filtering options

## Dev Agent Record

### Agent Model Used

Full Stack Developer (James) - Story 2I.4 Implementation

### Completion Notes

**Story 2I.4: Message Type Filtering and Configuration - COMPLETED**

All acceptance criteria have been implemented and verified through comprehensive testing.

**Implementation Summary:**

1. **XML Configuration Support** - Added parsing for `<message_type_filter>` element in bot XML configuration:
   - Supports multiple `<type>` child elements specifying message types to include
   - Valid message types: `user_message`, `bot_llm_response`, `bot_command_response`, `system_message`
   - Invalid types are gracefully ignored with warning messages
   - Empty configuration falls back to default behavior

2. **Default Behavior** - Default message type filter includes:
   - `:user_message` - Messages from users
   - `:bot_llm_response` - LLM-generated bot responses
   - `:bot_command_response` - Bot responses to commands
   - Excludes `:system_message` by default (configurable to include)

3. **Bot-Specific Configuration** - Each bot can have its own message type filter:
   - Stored in `@bots[bot_name]['message_type_filter']`
   - Applied automatically when `get_chat_context` is called without explicit `include_types` option
   - Allows per-bot customization of context filtering behavior

4. **Override Support** - Explicit `include_types` option in `get_chat_context`:
   - Overrides bot-specific configuration when provided
   - Maintains backward compatibility - existing code continues to work
   - Provides programmatic control when needed

5. **Error Handling** - Robust validation and error handling:
   - Invalid message types are detected and ignored with warnings
   - Empty filter configurations use sensible defaults
   - Missing configuration uses default filter (excludes system messages)

**Testing:**

- **New Comprehensive Tests** (7 tests added to `test_full_conversation_context.rb`):
  - XML configuration parsing verification
  - Bot-specific configuration usage as default
  - Explicit override behavior
  - Default behavior when no configuration
  - Invalid type handling
  - Empty configuration handling
  - All types included scenario

**Key Features:**

- **XML Configuration Format:**
  ```xml
  <message_type_filter>
    <type>user_message</type>
    <type>bot_llm_response</type>
    <type>bot_command_response</type>
    <!-- Optional: <type>system_message</type> -->
  </message_type_filter>
  ```

- **Backward Compatible**: Existing code continues to work; filtering is opt-in via configuration
- **Flexible**: Supports per-bot configuration and programmatic overrides
- **Safe Defaults**: Sensible defaults that exclude system messages but can be configured to include all types

### File List

**Modified Files:**
- `bot_manager.rb` - Added message type filtering configuration:
  - XML parsing for `<message_type_filter>` element in `read_bots` method
  - Validation of message types with error handling
  - Bot-specific configuration storage (`@bots[bot_name]['message_type_filter']`)
  - Updated `get_chat_context` to use bot-specific configuration as default
  - Updated documentation comments to reflect configuration support

- `test/test_full_conversation_context.rb` - Added comprehensive tests:
  - `test_message_type_filter_xml_configuration_parsing` - Verifies XML parsing
  - `test_message_type_filter_uses_bot_configuration_as_default` - Verifies bot config usage
  - `test_message_type_filter_explicit_override_overrides_configuration` - Verifies override behavior
  - `test_message_type_filter_default_when_no_configuration` - Verifies default behavior
  - `test_message_type_filter_invalid_types_handled_gracefully` - Verifies error handling
  - `test_message_type_filter_empty_configuration_uses_default` - Verifies empty config handling
  - `test_message_type_filter_all_types_included` - Verifies all types scenario

### Change Log

**2025-01-XX - Story 2I.4 Implementation:**
- Added XML configuration parsing for message type filtering in `read_bots`
- Updated `get_chat_context` to use bot-specific message type filter configuration
- Added 7 comprehensive tests for message type filtering configuration
- Updated documentation comments in `bot_manager.rb`

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

