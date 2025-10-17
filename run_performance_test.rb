#!/usr/bin/env ruby

require_relative 'test/test_rag_cag_performance'

# Create an instance and run the test manually to see output
test_instance = RAGCAGPerformanceTest.new('test_rag_cag_performance_comparison')
test_instance.setup

puts "\n" + '=' * 80
puts 'RAG vs CAG Performance Comparison Test'
puts '=' * 80
puts "Testing #{RAGCAGPerformanceTest::CYBERSECURITY_QUERIES.length} cybersecurity queries"
puts "Test started at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
puts '=' * 80 + "\n"

begin
  test_instance.test_rag_cag_performance_comparison
rescue StandardError => e
  puts "Test failed with error: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\nTest completed!"
