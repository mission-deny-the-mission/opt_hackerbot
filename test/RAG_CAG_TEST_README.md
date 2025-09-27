# From the opt_hackerbot directory
cd test
ruby run_rag_cag_tests.rb

### Running Specific Test Categories

# Run only RAG tests
ruby run_rag_cag_tests.rb --rag

# Run only CAG tests  
ruby run_rag_cag_tests.rb --cag

# Run only integration tests
ruby run_rag_cag_tests.rb --integration

### Running Individual Test Files

# Run specific RAG tests
ruby rag/test_rag_manager.rb
ruby rag/test_chromadb_client.rb
ruby rag/test_embedding_service_interface.rb

# Run specific CAG tests
ruby cag/test_cag_manager.rb
ruby cag/test_knowledge_graph_interface.rb
ruby cag/test_in_memory_graph_client.rb

# Run integration tests
ruby test_rag_cag_system.rb
ruby rag_cag_integration_test.rb

### Running with Verbose Output

# Run with detailed output
ruby run_rag_cag_tests.rb --verbose

# Run with performance metrics
ruby run_rag_cag_tests.rb --performance

## Test Configuration

The tests use mock configurations to avoid external dependencies:

### RAG Configuration
@rag_config = {
  vector_db: {
    provider: 'chromadb',
    host: 'localhost',
    port: 8000
  },
  embedding_service: {
    provider: 'openai',
    api_key: 'test_api_key',
    model: 'text-embedding-ada-002'
  },
  rag_settings: {
    max_results: 5,
    similarity_threshold: 0.5,
    enable_caching: true
  }
}

### CAG Configuration
@cag_config = {
  knowledge_graph: {
    provider: 'in_memory'
  },
  entity_extractor: {
    provider: 'rule_based'
  },
  cag_settings: {
    max_context_depth: 2,
    max_context_nodes: 15,
    enable_caching: true
  }
}

## Test Output

The test runner provides comprehensive output including:

### Test Results Summary
==============================================================
Test Suite Summary
==============================================================
Total Tests: 156
Passed: 154
Failed: 2
Duration: 12.34 seconds
Success Rate: 98.7%

❌ Test suite completed with 2 failures

### Detailed Failure Information
Failure Details:
--------------------
File: test_rag_manager.rb
Category: RAG
Failures: 1
Error: Expected context to contain document references

File: test_cag_manager.rb
Category: CAG  
Failures: 1
Error: Knowledge triplet addition failed

### Performance Metrics
Performance Metrics:
+- RAG System average response time: 0.234s
+- CAG System average response time: 0.156s
+- Integration tests average: 0.892s
+- Memory usage peak: 45MB
+- Cache hit rate: 87.3%

## Best Practices

### Writing New Tests

1. **Follow Naming Conventions**: Use descriptive test method names that follow the pattern `test_[feature]_[scenario]`

2. **Use Test Helpers**: Leverage existing test utilities in `test_helper.rb` for common operations

3. **Mock External Dependencies**: Use mock objects for external services to ensure tests are self-contained

4. **Test Edge Cases**: Include tests for invalid inputs, error conditions, and boundary cases

5. **Performance Testing**: Include performance benchmarks for critical operations

6. **Cleanup Resources**: Always clean up test resources in `teardown` methods

### Test Organization

- **Unit Tests**: Focus on individual components and methods
- **Integration Tests**: Test component interactions and workflows  
- **Performance Tests**: Validate system behavior under load
- **Edge Case Tests**: Handle unusual inputs and error conditions

### Continuous Integration

The test suite is designed to run in CI/CD environments:

# Example GitHub Actions workflow
name: RAG CAG Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 2.7
      - name: Install dependencies
        run: bundle install
      - name: Run tests
        run: cd test && ruby run_rag_cag_tests.rb

## Troubleshooting

### Common Issues

1. **Missing Dependencies**: Ensure all required gems are installed
2. **Port Conflicts**: Tests use localhost ports that may conflict with running services
3. **Memory Issues**: Large test datasets may require increased memory limits
4. **File Permissions**: Ensure test files have appropriate read/write permissions

### Debugging Tests

# Run with debug output
ruby run_rag_cag_tests.rb --debug

# Run specific test with detailed output
ruby -I test test/rag/test_rag_manager.rb --name=test_initialization --verbose

# Check test coverage (if simplecov is installed)
COVERAGE=true ruby run_rag_cag_tests.rb

## Contributing

When adding new tests:

1. **Update Test Documentation**: Add new test descriptions to this README
2. **Maintain Coverage**: Ensure new features have corresponding tests
3. **Follow Patterns**: Use existing test patterns and conventions
4. **Test Performance**: Include performance tests for new functionality
5. **Update Test Data**: Add appropriate test data and configurations

## License

This test suite is part of the Hackerbot project and follows the same license terms as the main project.

---

For more information about the RAG + CAG system implementation, see the main project documentation and `RAG_CAG_IMPLEMENTATION_SUMMARY.md`.