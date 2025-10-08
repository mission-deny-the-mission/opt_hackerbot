#!/usr/bin/env ruby

# Test script to check if man pages are available on the system
require_relative '../knowledge_bases/utils/man_page_processor'

puts "Testing Man Page Availability"
puts "=" * 40

def test_man_page_availability
  man_processor = ManPageProcessor.new
  man_pages_to_test = ['lsattr', 'chattr', 'chmod', 'ls', 'cat', 'grep']

  puts "Testing man page availability for: #{man_pages_to_test.join(', ')}"
  puts

  missing_pages = []
  available_pages = []

  man_pages_to_test.each do |man_page|
    exists = man_processor.man_page_exists?(man_page)

    if exists
      available_pages << man_page
      puts "✓ #{man_page} - Available"

      # Try to get content
      content = man_processor.get_man_page(man_page)
      if content && content['content'] && !content['content'].empty?
        puts "  Content length: #{content['content'].length} characters"

        # Try to generate RAG document
        rag_doc = man_processor.to_rag_document(man_page)
        if rag_doc
          puts "  ✓ RAG document generated: #{rag_doc[:id]}"
        else
          puts "  ✗ Failed to generate RAG document"
        end

        # Try to generate CAG triplets
        triplets = man_processor.to_cag_triplets(man_page)
        if triplets && triplets.any?
          puts "  ✓ Generated #{triplets.length} CAG triplets"

          # Show first few triplets
          triplets.first(3).each do |triplet|
            puts "    - #{triplet[:subject]} → #{triplet[:predicate]} → #{triplet[:object]}"
          end
        else
          puts "  ✗ Failed to generate CAG triplets"
        end
      else
        puts "  ✗ No content retrieved"
      end
    else
      missing_pages << man_page
      puts "✗ #{man_page} - Not available"
    end

    puts
  end

  puts "Summary:"
  puts "  Available: #{available_pages.length} man pages"
  puts "  Missing: #{missing_pages.length} man pages"

  if missing_pages.any?
    puts "Missing pages: #{missing_pages.join(', ')}"
    puts "Consider installing missing packages or generating manual documentation."
  end

  return available_pages, missing_pages
end

def generate_fallback_man_pages
  puts "Generating fallback man page content for missing commands..."

  fallback_content = {
    'lsattr' => {
      name: 'lsattr',
      section: 1,
      description: 'List file attributes on a Linux second extended file system',
      synopsis: 'lsattr [ -RVadlpv ] [ files... ]',
      purpose: 'Display file attributes that can help with file system security',
      security_relevance: 'Important for file system security monitoring'
    },
    'chattr' => {
      name: 'chattr',
      section: 1,
      description: 'Change file attributes on a Linux second extended file system',
      synopsis: 'chattr [ -RVf ] [ -v version ] [ mode ] files...',
      purpose: 'Modify file attributes for enhanced security (e.g., making files immutable)',
      security_relevance: 'Critical for file system security controls'
    },
    'chmod' => {
      name: 'chmod',
      section: 1,
      description: 'Change file mode bits',
      synopsis: 'chmod [OPTION]... MODE[,MODE]... FILE...',
      purpose: 'Control file permissions and access rights',
      security_relevance: 'Fundamental for access control and file security'
    }
  }

  # Create simple man page files in the man_pages directory
  man_pages_dir = '../knowledge_bases/sources/man_pages'

  fallback_content.each do |command, info|
    filename = "#{man_pages_dir}/#{command}.txt"

    # Create directory if it doesn't exist
    Dir.mkdir(man_pages_dir) unless Dir.exist?(man_pages_dir)

    man_content = <<~MANPAGE
      #{info[:name]}(#{info[:section]})                  Linux User Commands                  #{info[:name]}(#{info[:section]})

      NAME
          #{info[:name]} - #{info[:description]}

      SYNOPSIS
          #{info[:synopsis]}

      DESCRIPTION
          #{info[:description]}. #{info[:purpose]}.

      SECURITY CONSIDERATIONS
          #{info[:security_relevance]}. This command is essential for maintaining file system
          security and preventing unauthorized access or modification.

      SEE ALSO
          lsattr(1), chattr(1), chmod(1), ls(1), stat(1)
    MANPAGE

    File.write(filename, man_content)
    puts "✓ Generated fallback man page: #{filename}"
  end
end

def main
  puts "Testing Man Page System"
  puts "=" * 40

  available, missing = test_man_page_availability

  if missing.include?('lsattr') || missing.include?('chattr') || missing.include?('chmod')
    puts "\nSome important security-related man pages are missing."
    puts "Generating fallback content..."
    generate_fallback_man_pages
  end

  puts "\n" + "=" * 40
  puts "Man Page Availability Test Completed"

  if available.include?('lsattr') && available.include?('chattr') && available.include?('chmod')
    puts "✅ All target man pages are available and ready for CAG integration!"
  else
    puts "⚠ Some man pages are missing, but fallback content has been generated."
  end
end

if __FILE__ == $0
  main
end
