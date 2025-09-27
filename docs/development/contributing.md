# Contributing to Hackerbot

Thank you for your interest in contributing to Hackerbot! This guide provides comprehensive information for developers who want to contribute to the project.

## 🤝 How to Contribute

### Getting Started

1. **Fork the Repository**
   ```bash
   # Clone your fork
   git clone https://github.com/your-username/hackerbot.git
   cd hackerbot
   ```

2. **Set Up Development Environment**
   ```bash
   # Install Ruby dependencies
   gem install bundler
   bundle install
   
   # Install Ollama for local development
   curl -fsSL https://ollama.ai/install.sh | sh
   ollama pull gemma3:1b
   ```

3. **Create a Development Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Development Workflow

1. **Make Your Changes**
   - Write clean, well-documented code
   - Follow the existing code style and patterns
   - Add tests for new functionality
   - Update documentation as needed

2. **Run Tests**
   ```bash
   # Run all tests
   ruby test/run_tests.rb
   
   # Run specific test file
   ruby test/test_llm_client_factory.rb
   
   # Quick verification
   ruby test/quick_test.rb
   ```

3. **Test Your Changes**
   ```bash
   # Test with local bot
   ruby hackerbot.rb --config config/your-test-config.xml
   
   # Test knowledge enhancement
   ruby demo_rag_cag.rb
   ```

4. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature description
   
   - Add detailed description of changes
   - Include testing information
   - Reference any related issues"
   ```

5. **Submit Pull Request**
   - Push to your fork: `git push origin feature/your-feature-name`
   - Create a pull request against the main branch
   - Fill out the pull request template completely
   - Link any related issues

## 📝 Code Standards

### Ruby Style Guidelines

- Follow standard Ruby conventions (Ruby Style Guide)
- Use meaningful variable and method names
- Keep methods short and focused on single responsibility
- Use descriptive comments for complex logic
- Document all public methods with YARD-style comments

```ruby
# Good example
class ExampleClass
  # Processes user input and returns formatted response
  #
  # @param input [String] The raw user input
  # @param context [Hash] Additional context information
  # @return [String] Formatted response
  # @raise [InvalidInputError] If input is malformed
  def process_input(input, context = {})
    validate_input!(input)
    
    # Processing logic here
    formatted = format_response(input, context)
    
    formatted
  end
  
  private
  
  def validate_input!(input)
    raise InvalidInputError, "Input cannot be empty" if input.strip.empty?
  end
end
```

### Naming Conventions

- **Classes**: PascalCase (e.g., `LLMClientFactory`)
- **Methods**: snake_case (e.g., `generate_response`)
- **Variables**: snake_case (e.g., `chat_history`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `MAX_HISTORY_LENGTH`)
- **Files**: snake_case (e.g., `llm_client_factory.rb`)

### Error Handling

```ruby
# Use specific exception classes
class ConfigurationError < StandardError; end
class LLMConnectionError < StandardError; end

# Handle errors gracefully
def risky_operation
  result = perform_risky_call
rescue NetworkError => e
  log_error("Network operation failed", e)
  raise OperationFailedError, "Unable to complete operation"
end
```

### Testing Standards

#### Test Structure

```ruby
require_relative 'test_helper'

class TestMyComponent < Minitest::Test
  def setup
    super
    @component = MyComponent.new
  end
  
  def test_functionality_with_valid_input
    result = @component.my_method("valid_input")
    
    assert_equal "expected_result", result
    assert_includes result, "expected_content"
  end
  
  def test_functionality_with_invalid_input
    assert_raises(InvalidInputError) do
      @component.my_method("invalid_input")
    end
  end
  
  def test_functionality_edge_case
    # Test edge cases and boundary conditions
    result = @component.my_method("")
    assert_nil result
  end
end
```

#### Test Coverage Requirements

- **New Features**: Minimum 90% test coverage
- **Bug Fixes**: Include regression test for the fixed bug
- **Refactoring**: Ensure all existing tests still pass
- **Integration**: Test integration with other components when applicable

## 🏗️ Architecture Guidelines

### Adding New LLM Providers

1. **Implement the LLM Client Interface**
   ```ruby
   class NewProviderClient < LLMClient
     def generate_response(message, context = '', user_id = nil)
       # Provider-specific implementation
     end
     
     def generate_streaming_response(message, context = '', user_id = nil, &callback)
       # Streaming implementation if supported
     end
     
     def test_connection
       # Connection test implementation
     end
   end
   ```

2. **Register with Factory**
   ```ruby
   class LLMClientFactory
     PROVIDERS = {
       'ollama' => OllamaClient,
       'openai' => OpenAIClient,
       'newprovider' => NewProviderClient  # Add your provider
     }
   end
   ```

3. **Add Tests**
   ```ruby
   class TestNewProviderClient < LLMClientTest
     def test_generate_response_success
       # Test successful response generation
     end
     
     def test_connection_failure
       # Test connection error handling
     end
   end
   ```

### Adding New Knowledge Sources

1. **Implement Knowledge Source Interface**
   ```ruby
   class CustomKnowledgeSource < BaseKnowledgeSource
     def process_content
       # Process your custom data source
       documents = []
       triplets = []
       
       # Your processing logic here
       
       [documents, triplets]
     end
     
     def test_connection
       # Test data source connectivity
     end
   end
   ```

2. **Update Configuration Schema**
   ```xml
   <knowledge_sources>
     <source>
       <type>custom_type</type>
       <name>my_custom_source</name>
       <enabled>true</enabled>
       <!-- Custom configuration options -->
     </source>
   </knowledge_sources>
   ```

### Adding New Entity Types

1. **Extend Entity Extractor**
   ```ruby
   class CustomEntityExtractor < EntityExtractor
     def extract_custom_entities(text)
       text.scan(/custom-pattern/).map do |match|
         {
           type: 'custom_type',
           value: match,
           confidence: 0.9,
           context: get_context(text, match)
         }
       end
     end
   end
   ```

2. **Update Configuration**
   ```xml
   <entity_types>ip_address, url, hash, filename, port, email, custom_type</entity_types>
   ```

## 📚 Documentation Standards

### Code Documentation

- Document all public methods with YARD comments
- Include parameter types and return values
- Document any raised exceptions
- Provide usage examples for complex methods

```ruby
# Generates a response using the configured LLM provider
#
# @param message [String] The user's message
# @param context [String] Additional context information
# @param user_id [String, nil] User identifier for personalization
# @return [String] The generated response
# @raise [LLMConnectionError] If unable to connect to LLM provider
# @example
#   client.generate_response("Hello", "You are a helpful assistant")
#   # => "Hello! I'm a helpful assistant. How can I help you today?"
#
def generate_response(message, context = '', user_id = nil)
  # Implementation
end
```

### User Documentation

- Update relevant documentation files for new features
- Include configuration examples
- Add troubleshooting information for common issues
- Update the changelog with user-facing changes

### API Documentation

- Document new API endpoints or methods
- Include request/response examples
- Document error conditions and status codes
- Provide authentication/authorization requirements

## 🧪 Testing Guidelines

### Unit Testing

- Test each component in isolation
- Mock external dependencies
- Test both success and error cases
- Include edge cases and boundary conditions

### Integration Testing

- Test component interactions
- Use real dependencies when possible
- Test configuration loading and validation
- Verify end-to-end workflows

### Performance Testing

- Test with large datasets
- Measure memory usage and execution time
- Test under concurrent load
- Verify resource cleanup

### Test Data Management

```ruby
# Use test fixtures for consistent data
def test_with_sample_data
  data = load_test_fixture('sample_knowledge.json')
  result = @processor.process(data)
  
  assert_equal expected_result, result
end

# Clean up test data
def teardown
  super
  cleanup_test_data
end
```

## 🔒 Security Guidelines

### Input Validation

- Validate all user inputs
- Sanitize data before processing
- Use parameterized queries for database operations
- Implement rate limiting for API endpoints

### API Key Management

- Never commit API keys to the repository
- Use environment variables for sensitive configuration
- Implement secure key rotation procedures
- Use different keys for development and production

### Data Privacy

- Anonymize sensitive data in logs
- Implement proper data retention policies
- Follow GDPR and other privacy regulations
- Obtain user consent for data collection

## 🚀 Release Process

### Version Management

- Follow Semantic Versioning (SemVer)
- Update version numbers in all relevant files
- Create release notes for each version
- Tag releases in Git

### Release Checklist

- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Changelog is updated
- [ ] Version numbers are updated
- [ ] Release notes are written
- [ ] Security review is completed
- [ ] Performance tests pass
- [ ] Integration tests pass

### Deployment

- Update documentation and examples
- Create release announcement
- Update package repositories
- Monitor for post-release issues

## 🎯 Areas for Contribution

### High Priority

1. **Additional LLM Providers**
   - Anthropic Claude integration
   - Google Gemini integration
   - Local model providers (Llama.cpp, etc.)

2. **Knowledge Source Enhancements**
   - Web scraping and crawling
   - Database integrations (SQL, NoSQL)
   - Real-time threat intelligence feeds

3. **Performance Optimization**
   - Parallel processing for RAG operations
   - Improved caching strategies
   - Memory usage optimization

### Medium Priority

1. **User Interface Improvements**
   - Web-based admin interface
   - Real-time monitoring dashboard
   - Enhanced visualization tools

2. **Testing Enhancements**
   - Integration test automation
   - Performance benchmarking
   - Code coverage improvements

3. **Documentation**
   - Video tutorials
   - Additional examples and templates
   - API reference documentation

### Low Priority

1. **Experimental Features**
   - Multi-modal capabilities (images, audio)
   - Advanced NLP features
   - Machine learning enhancements

2. **Tooling and Utilities**
   - Development CLI tools
   - Configuration validators
   - Performance profiling tools

## 🤝 Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers get started
- Collaborate and share knowledge

### Communication

- Use GitHub issues for bug reports and feature requests
- Join discussions in GitHub Discussions
- Ask questions in the appropriate channels
- Be patient and helpful with community members

### Issue Reporting

When reporting issues, please include:

- Clear description of the problem
- Steps to reproduce the issue
- Expected vs. actual behavior
- System information (Ruby version, OS, etc.)
- Relevant logs or error messages

### Feature Requests

When requesting features, please include:

- Clear description of the requested feature
- Use case and motivation
- Proposed implementation approach
- Any relevant examples or references

## 🏆 Recognition

Contributors will be recognized through:

- Acknowledgment in release notes
- Contributor badges on GitHub
- Recognition in project documentation
- Invitation to become a maintainer for significant contributions

## 📞 Getting Help

- **Documentation**: Start with the project documentation
- **Issues**: Search existing issues before creating new ones
- **Discussions**: Join community discussions
- **Discord/Slack**: Join our community chat (if available)
- **Email**: Contact maintainers directly for sensitive issues

---

Thank you for contributing to Hackerbot! Your help makes this project better for everyone. 🎉