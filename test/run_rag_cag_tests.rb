#!/usr/bin/env ruby

# Simple test runner script for RAG and CAG systems
require 'minitest/autorun'
require 'fileutils'

# Add the project root to the load path
project_root = File.dirname(File.dirname(__FILE__))
$LOAD_PATH.unshift(project_root)

puts "Starting RAG + CAG System Test Suite"
puts "=" * 50

# Test files to run
test_files = [
  'test/rag/test_rag_manager.rb',
  'test/rag/test_chromadb_client.rb',
  'test/rag/test_embedding_service_interface.rb',
  'test/cag/test_cag_manager.rb',
  'test/cag/test_knowledge_graph_interface.rb',
  'test/cag/test_in_memory_graph_client.rb',
  'test/test_rag_cag_system.rb',
  'test/rag_cag_integration_test.rb'
]

# Change to project directory
Dir.chdir(project_root) do
  total_tests = 0
  passed_tests = 0
  failed_tests = 0

  test_files.each do |test_file|
    if File.exist?(test_file)
      puts "\nRunning #{test_file}..."
      puts "-" * 40

      begin
        # Capture test output
        output = `ruby -I #{project_root} #{test_file} 2>&1`
        exit_code = $?.exitstatus

        if exit_code == 0
          puts "✓ #{test_file} - All tests passed"
          passed_tests += 1
        else
          puts "✗ #{test_file} - Tests failed"
          puts output if ENV['VERBOSE']
          failed_tests += 1
        end

        total_tests += 1

      rescue => e
        puts "✗ #{test_file} - Error: #{e.message}"
        failed_tests += 1
        total_tests += 1
      end
    else
      puts "✗ #{test_file} - File not found"
      failed_tests += 1
      total_tests += 1
    end
  end

  # Print summary
  puts "\n" + "=" * 50
  puts "Test Suite Summary"
  puts "=" * 50
  puts "Total Test Files: #{total_tests}"
  puts "Passed: #{passed_tests}"
  puts "Failed: #{failed_tests}"

  if failed_tests > 0
    puts "\n❌ Test suite completed with #{failed_tests} failures"
    exit 1
  else
    puts "\n✅ All tests passed!"
    exit 0
  end
end
