

# MITRE ATT&CK Framework Knowledge Base for CAG System
# This file contains structured knowledge about cybersecurity attack patterns

module MITREAttackKnowledge
  # MITRE ATT&CK Tactics and Techniques
  ATTACK_PATTERNS = [
    {
      id: 'T1003',
      name: 'OS Credential Dumping',
      tactic: 'Credential Access',
      description: 'Adversaries may attempt to dump credentials to obtain account login and credential material, commonly in the form of a hash or plaintext password.',
      techniques: [
        {
          technique_id: 'T1003.001',
          name: 'LSASS Memory',
          description: 'Adversaries may attempt to access credential material stored in the process memory of the Local Security Authority Subsystem Service (LSASS).'
        },
        {
          technique_id: 'T1003.002',
          name: 'Security Account Manager',
          description: 'Adversaries may attempt to extract credentials material from the Security Account Manager (SAM) database.'
        },
        {
          technique_id: 'T1003.003',
          name: 'NTDS',
          description: 'Adversaries may attempt to access or create a copy of the Active Directory database.'
        }
      ],
      related_tools: ['Mimikatz', 'ProcDump', 'NMap'],
      mitigation: 'Use Credential Guard, enable protected process for LSASS, implement privileged access management'
    },
    {
      id: 'T1059',
      name: 'Command-Line Interface',
      tactic: 'Execution',
      description: 'Adversaries may use command-line interfaces to interact with systems and execute commands, scripts, or binaries.',
      techniques: [
        {
          technique_id: 'T1059.001',
          name: 'PowerShell',
          description: 'Adversaries may abuse PowerShell commands to execute commands, scripts, or binaries.'
        },
        {
          technique_id: 'T1059.003',
          name: 'Windows Command Shell',
          description: 'Adversaries may abuse the Windows command shell for execution.'
        },
        {
          technique_id: 'T1059.004',
          name: 'Unix Shell',
          description: 'Adversaries may abuse Unix shell commands and scripts.'
        }
      ],
      related_tools: ['PowerShell', 'Cmd.exe', 'Bash', 'Zsh'],
      mitigation: ' PowerShell command logging, audit command-line usage, implement application whitelisting'
    },
    {
      id: 'T1078',
      name: 'Valid Accounts',
      tactic: 'Defense Evasion',
      description: 'Adversaries may obtain and abuse credentials of existing accounts as a means of gaining access to systems.',
      techniques: [
        {
          technique_id: 'T1078.001',
          name: 'Default Accounts',
          description: 'Adversaries may obtain and use credentials for default accounts.'
        },
        {
          technique_id: 'T1078.002',
          name: 'Domain Accounts',
          description: 'Adversaries may compromise domain accounts to access systems and resources.'
        },
        {
          technique_id: 'T1078.003',
          name: 'Local Accounts',
          description: 'Adversaries may obtain and use local account credentials.'
        }
      ],
      related_tools: ['Pass-the-Hash', 'Pass-the-Ticket', 'Kerberoasting'],
      mitigation: 'Disable default accounts, implement strong password policies, use multi-factor authentication'
    },
    {
      id: 'T1190',
      name: 'Exploit Public-Facing Application',
      tactic: 'Initial Access',
      description: 'Adversaries may attempt to exploit vulnerabilities in public-facing applications to gain initial access.',
      techniques: [
        {
          technique_id: 'T1190.001',
          name: 'Web Application Exploit',
          description: 'Adversaries may exploit web application vulnerabilities to gain access.'
        }
      ],
      related_tools: ['Metasploit', 'SQLMap', 'NMap'],
      mitigation: 'Keep software updated, implement web application firewalls, use secure coding practices'
    },
    {
      id: 'T1566',
      name: 'Phishing',
      tactic: 'Initial Access',
      description: 'Adversaries may send phishing emails to target users to steal credentials or deliver malware.',
      techniques: [
        {
          technique_id: 'T1566.001',
          name: 'Spearphishing Attachment',
          description: 'Adversaries may send spearphishing emails with malicious attachments.'
        },
        {
          technique_id: 'T1566.002',
          name: 'Spearphishing Link',
          description: 'Adversaries may send spearphishing emails with malicious links.'
        }
      ],
      related_tools: ['Social Engineering Toolkit', 'Gophish', 'Metasploit'],
      mitigation: 'Security awareness training, email filtering, sandbox suspicious attachments'
    }
  ]

  # Malware families and their characteristics
  MALWARE_FAMILIES = [
    {
      name: 'Emotet',
      type: 'Trojan',
      description: 'Modular malware that delivers banking trojans and ransomware',
      capabilities: ['credential theft', 'email spreading', 'downloader'],
      attack_patterns: ['T1003', 'T1059', 'T1078'],
      mitigation: 'Email filtering, network segmentation, endpoint detection'
    },
    {
      name: 'WannaCry',
      type: 'Ransomware',
      description: 'Ransomware worm that spreads using EternalBlue exploit',
      capabilities: ['worm propagation', 'file encryption', 'ransom demand'],
      attack_patterns: ['T1190', 'T1486'],
      mitigation: 'Patch management, network segmentation, backup systems'
    },
    {
      name: 'Mirai',
      type: 'Botnet',
      description: 'IoT malware that creates botnets for DDoS attacks',
      capabilities: ['DDoS attacks', 'device scanning', 'password cracking'],
      attack_patterns: ['T1110', 'T1498'],
      mitigation: 'Change default credentials, network monitoring, IoT device security'
    }
  ]

  # Common attack tools and their uses
  ATTACK_TOOLS = [
    {
      name: 'Metasploit Framework',
      type: 'Exploitation Framework',
      description: 'Advanced penetration testing platform with exploit development and testing capabilities',
      capabilities: ['exploit development', 'payload generation', 'post-exploitation'],
      attack_patterns: ['T1190', 'T1059', 'T1003'],
      detection: 'Network traffic monitoring, process monitoring, suspicious file creation'
    },
    {
      name: 'Mimikatz',
      type: 'Credential Theft',
      description: 'Advanced credential extraction tool focused on Windows systems',
      capabilities: ['credential theft', 'pass-the-hash', 'kerberoasting'],
      attack_patterns: ['T1003'],
      detection: ['LSASS access monitoring', 'credentialdumping', 'process monitoring']
    },
    {
      name: 'NMap',
      type: 'Network Scanning',
      description: 'Network discovery and security auditing tool',
      capabilities: ['port scanning', 'service detection', 'OS fingerprinting'],
      attack_patterns: ['T1046', 'T1592'],
      detection: ['Network scanning detection', 'port scan detection', 'service enumeration detection']
    },
    {
      name: 'Burp Suite',
      type: 'Web Testing',
      description: 'Integrated platform for performing security testing of web applications',
      capabilities: ['web vulnerability scanning', 'interception', 'fuzzing'],
      attack_patterns: ['T1190.001'],
      detection: ['Web application monitoring', 'HTTP traffic analysis', 'suspicious request patterns']
    }
  ]

  # Defenses and countermeasures
  DEFENSES = [
    {
      name: 'Endpoint Detection and Response (EDR)',
      type: 'Prevention',
      description: 'Advanced security solutions that monitor and respond to threats on endpoints',
      capabilities: ['process monitoring', 'behavior analysis', 'threat hunting'],
      effectiveness: 'High',
      attack_patterns: ['T1003', 'T1059', 'T1078']
    },
    {
      name: 'Security Information and Event Management (SIEM)',
      type: 'Detection',
      description: 'Centralized log management and security monitoring system',
      capabilities: ['log aggregation', 'correlation', 'alerting'],
      effectiveness: 'High',
      attack_patterns: ['T1078', 'T1190', 'T1566']
    },
    {
      name: 'Multi-Factor Authentication (MFA)',
      type: 'Prevention',
      description: 'Authentication method requiring multiple verification factors',
      capabilities: ['additional authentication', 'phishing resistance', 'credential protection'],
      effectiveness: 'Very High',
      attack_patterns: ['T1078', 'T1566']
    },
    {
      name: 'Network Segmentation',
      type: 'Prevention',
      description: 'Dividing network into smaller segments to limit attack surface',
      capabilities: ['access control', 'lateral movement prevention', 'breach containment'],
      effectiveness: 'Medium',
      attack_patterns: ['T1190', 'T1003']
    }
  ]

  # Method to convert knowledge base to CAG triplets
  def self.to_cag_triplets
    triplets = []

    # Add attack patterns
    ATTACK_PATTERNS.each do |pattern|
      # Attack pattern -> has tactic
      triplets << {
        subject: pattern[:name],
        relationship: 'HAS_TACTIC',
        object: pattern[:tactic],
        properties: { pattern_id: pattern[:id] }
      }

      # Attack pattern -> described as
      triplets << {
        subject: pattern[:name],
        relationship: 'DESCRIBED_AS',
        object: pattern[:description],
        properties: { pattern_id: pattern[:id] }
      }

      # Attack pattern -> mitigated by
      if pattern[:mitigation]
        triplets << {
          subject: pattern[:name],
          relationship: 'MITIGATED_BY',
          object: pattern[:mitigation],
          properties: { pattern_id: pattern[:id] }
        }
      end

      # Add techniques
      pattern[:techniques].each do |technique|
        # Attack pattern -> has technique
        triplets << {
          subject: pattern[:name],
          relationship: 'HAS_TECHNIQUE',
          object: technique[:name],
          properties: {
            technique_id: technique[:technique_id],
            pattern_id: pattern[:id]
          }
        }

        # Technique -> described as
        triplets << {
          subject: technique[:name],
          relationship: 'DESCRIBED_AS',
          object: technique[:description],
          properties: { technique_id: technique[:technique_id] }
        }
      end

      # Add related tools
      pattern[:related_tools].each do |tool|
        triplets << {
          subject: pattern[:name],
          relationship: 'RELATED_TO',
          object: tool,
          properties: { pattern_id: pattern[:id] }
        }
      end
    end

    # Add malware families
    MALWARE_FAMILIES.each do |malware|
      # Malware -> is type
      triplets << {
        subject: malware[:name],
        relationship: 'IS_TYPE',
        object: malware[:type],
        properties: { malware_type: malware[:type] }
      }

      # Malware -> described as
      triplets << {
        subject: malware[:name],
        relationship: 'DESCRIBED_AS',
        object: malware[:description],
        properties: { name: malware[:name] }
      }

      # Add capabilities
      malware[:capabilities].each do |capability|
        triplets << {
          subject: malware[:name],
          relationship: 'HAS_CAPABILITY',
          object: capability,
          properties: { name: malware[:name] }
        }
      end

      # Add attack patterns
      malware[:attack_patterns].each do |pattern_id|
        pattern_name = ATTACK_PATTERNS.find { |p| p[:id] == pattern_id }&.dig(:name)
        if pattern_name
          triplets << {
            subject: malware[:name],
            relationship: 'USES_ATTACK_PATTERN',
            object: pattern_name,
            properties: {
              malware_name: malware[:name],
              pattern_id: pattern_id
            }
          }
        end
      end
    end

    # Add attack tools
    ATTACK_TOOLS.each do |tool|
      # Tool -> is type
      triplets << {
        subject: tool[:name],
        relationship: 'IS_TYPE',
        object: tool[:type],
        properties: { tool_type: tool[:type] }
      }

      # Tool -> described as
      triplets << {
        subject: tool[:name],
        relationship: 'DESCRIBED_AS',
        object: tool[:description],
        properties: { name: tool[:name] }
      }

      # Add capabilities
      tool[:capabilities].each do |capability|
        triplets << {
          subject: tool[:name],
          relationship: 'HAS_CAPABILITY',
          object: capability,
          properties: { name: tool[:name] }
        }
      end
    end

    # Add defenses
    DEFENSES.each do |defense|
      # Defense -> is type
      triplets << {
        subject: defense[:name],
        relationship: 'IS_TYPE',
        object: defense[:type],
        properties: { defense_type: defense[:type] }
      }

      # Defense -> described as
      triplets << {
        subject: defense[:name],
        relationship: 'DESCRIBED_AS',
        object: defense[:description],
        properties: { name: defense[:name] }
      }

      # Defense -> has effectiveness
      triplets << {
        subject: defense[:name],
        relationship: 'HAS_EFFECTIVENESS',
        object: defense[:effectiveness],
        properties: { name: defense[:name] }
      }

      # Defense -> mitigates
      defense[:attack_patterns].each do |pattern_id|
        pattern_name = ATTACK_PATTERNS.find { |p| p[:id] == pattern_id }&.dig(:name)
        if pattern_name
          triplets << {
            subject: defense[:name],
            relationship: 'MITIGATES',
            object: pattern_name,
            properties: {
              defense_name: defense[:name],
              pattern_id: pattern_id
            }
          }
        end
      end
    end

    triplets
  end

  # Method to get RAG documents
  def self.to_rag_documents
    documents = []

    # Add attack pattern documents
    ATTACK_PATTERNS.each do |pattern|
      doc_content = "MITRE ATT&CK Attack Pattern: #{pattern[:name]}\n\n"
      doc_content += "ID: #{pattern[:id]}\n"
      doc_content += "Tactic: #{pattern[:tactic]}\n\n"
      doc_content += "Description:\n#{pattern[:description]}\n\n"

      doc_content += "Techniques:\n"
      pattern[:techniques].each do |technique|
        doc_content += "- #{technique[:name]} (#{technique[:technique_id]}): #{technique[:description]}\n"
      end

      doc_content += "\nRelated Tools:\n"
      pattern[:related_tools].each do |tool|
        doc_content += "- #{tool}\n"
      end

      doc_content += "\nMitigation:\n#{pattern[:mitigation]}"

      # Limit document length to avoid text too long errors
      max_length = 7000
      if doc_content.length > max_length
        # Truncate to a reasonable length
        truncated_content = doc_content[0...max_length]
        # Try to end at a good breaking point
        last_section_end = truncated_content.rindex(/\n\n/)
        if last_section_end && last_section_end > max_length - 500
          doc_content = truncated_content[0...last_section_end] + "\n\n[Note: Document truncated for length]"
        else
          doc_content = truncated_content + "\n\n[Note: Document truncated for length]"
        end
      end

      documents << {
        id: "mitre_attack_#{pattern[:id]}",
        content: doc_content,
        metadata: {
          source: 'MITRE ATT&CK',
          type: 'attack_pattern',
          tactic: pattern[:tactic],
          pattern_id: pattern[:id]
        }
      }
    end

    # Add malware family documents
    MALWARE_FAMILIES.each do |malware|
      doc_content = "Malware Family: #{malware[:name]}\n\n"
      doc_content += "Type: #{malware[:type]}\n\n"
      doc_content += "Description:\n#{malware[:description]}\n\n"

      doc_content += "Capabilities:\n"
      malware[:capabilities].each do |capability|
        doc_content += "- #{capability}\n"
      end

      doc_content += "\nAssociated Attack Patterns:\n"
      malware[:attack_patterns].each do |pattern_id|
        pattern_name = ATTACK_PATTERNS.find { |p| p[:id] == pattern_id }&.dig(:name)
        doc_content += "- #{pattern_name} (#{pattern_id})\n" if pattern_name
      end

      # Limit document length to avoid text too long errors
      max_length = 7000
      if doc_content.length > max_length
        # Truncate to a reasonable length
        truncated_content = doc_content[0...max_length]
        # Try to end at a good breaking point
        last_section_end = truncated_content.rindex(/\n\n/)
        if last_section_end && last_section_end > max_length - 500
          doc_content = truncated_content[0...last_section_end] + "\n\n[Note: Document truncated for length]"
        else
          doc_content = truncated_content + "\n\n[Note: Document truncated for length]"
        end
      end

      documents << {
        id: "malware_#{malware[:name].downcase.gsub(/\s+/, '_')}",
        content: doc_content,
        metadata: {
          source: 'Malware Database',
          type: 'malware_family',
          malware_type: malware[:type],
          name: malware[:name]
        }
      }
    end

    # Add attack tool documents
    ATTACK_TOOLS.each do |tool|
      doc_content = "Attack Tool: #{tool[:name]}\n\n"
      doc_content += "Type: #{tool[:type]}\n\n"
      doc_content += "Description:\n#{tool[:description]}\n\n"

      doc_content += "Capabilities:\n"
      tool[:capabilities].each do |capability|
        doc_content += "- #{capability}\n"
      end

      doc_content += "\nDetection Methods:\n#{tool[:detection]}"

      # Limit document length to avoid text too long errors
      max_length = 7000
      if doc_content.length > max_length
        # Truncate to a reasonable length
        truncated_content = doc_content[0...max_length]
        # Try to end at a good breaking point
        last_section_end = truncated_content.rindex(/\n\n/)
        if last_section_end && last_section_end > max_length - 500
          doc_content = truncated_content[0...last_section_end] + "\n\n[Note: Document truncated for length]"
        else
          doc_content = truncated_content + "\n\n[Note: Document truncated for length]"
        end
      end

      documents << {
        id: "tool_#{tool[:name].downcase.gsub(/\s+/, '_')}",
        content: doc_content,
        metadata: {
          source: 'Attack Tools Database',
          type: 'attack_tool',
          tool_type: tool[:type],
          name: tool[:name]
        }
      }
    end

    # Add defense documents
    DEFENSES.each do |defense|
      doc_content = "Security Defense: #{defense[:name]}\n\n"
      doc_content += "Type: #{defense[:type]}\n\n"
      doc_content += "Effectiveness: #{defense[:effectiveness]}\n\n"
      doc_content += "Description:\n#{defense[:description]}\n\n"

      doc_content += "Capabilities:\n"
      defense[:capabilities].each do |capability|
        doc_content += "- #{capability}\n"
      end

      doc_content += "\nMitigates Attack Patterns:\n"
      defense[:attack_patterns].each do |pattern_id|
        pattern_name = ATTACK_PATTERNS.find { |p| p[:id] == pattern_id }&.dig(:name)
        doc_content += "- #{pattern_name} (#{pattern_id})\n" if pattern_name
      end

      # Limit document length to avoid text too long errors
      max_length = 7000
      if doc_content.length > max_length
        # Truncate to a reasonable length
        truncated_content = doc_content[0...max_length]
        # Try to end at a good breaking point
        last_section_end = truncated_content.rindex(/\n\n/)
        if last_section_end && last_section_end > max_length - 500
          doc_content = truncated_content[0...last_section_end] + "\n\n[Note: Document truncated for length]"
        else
          doc_content = truncated_content + "\n\n[Note: Document truncated for length]"
        end
      end

      documents << {
        id: "defense_#{defense[:name].downcase.gsub(/\s+/, '_')}",
        content: doc_content,
        metadata: {
          source: 'Security Defenses Database',
          type: 'defense',
          defense_type: defense[:type],
          effectiveness: defense[:effectiveness],
          name: defense[:name]
        }
      }
    end

    documents
  end

  # Convert MITRE ATT&CK knowledge to RAG documents
  def self.to_rag_documents
    documents = []

    # Add attack pattern documents
    ATTACK_PATTERNS.each do |pattern|
      doc_content = "Attack Pattern: #{pattern[:name]} (#{pattern[:id]})\n\n"
      doc_content += "Tactic: #{pattern[:tactic]}\n\n"
      doc_content += "Description:\n#{pattern[:description]}\n\n"

      doc_content += "Techniques:\n"
      pattern[:techniques].each do |technique|
        doc_content += "- #{technique[:name]} (#{technique[:technique_id]})\n"
        doc_content += "  #{technique[:description]}\n"
      end

      doc_content += "\nRelated Tools:\n"
      pattern[:related_tools].each do |tool|
        doc_content += "- #{tool}\n"
      end

      doc_content += "\nMitigation:\n#{pattern[:mitigation]}"

      documents << {
        id: "pattern_#{pattern[:id]}",
        content: doc_content,
        metadata: {
          source: 'MITRE ATT&CK',
          type: 'attack_pattern',
          tactic: pattern[:tactic],
          pattern_id: pattern[:id],
          name: pattern[:name]
        }
      }
    end

    # Add malware family documents
    MALWARE_FAMILIES.each do |malware|
      doc_content = "Malware Family: #{malware[:name]}\n\n"
      doc_content += "Type: #{malware[:type]}\n\n"
      doc_content += "Description:\n#{malware[:description]}\n\n"

      doc_content += "Capabilities:\n"
      malware[:capabilities].each do |capability|
        doc_content += "- #{capability}\n"
      end

      doc_content += "\nAttack Patterns:\n"
      malware[:attack_patterns].each do |pattern_id|
        pattern_name = ATTACK_PATTERNS.find { |p| p[:id] == pattern_id }&.dig(:name)
        doc_content += "- #{pattern_name} (#{pattern_id})\n" if pattern_name
      end

      doc_content += "\nMitigation:\n#{malware[:mitigation]}"

      documents << {
        id: "malware_#{malware[:name].downcase.gsub(/\s+/, '_')}",
        content: doc_content,
        metadata: {
          source: 'MITRE ATT&CK',
          type: 'malware_family',
          malware_type: malware[:type],
          name: malware[:name]
        }
      }
    end

    # Add attack tool documents
    ATTACK_TOOLS.each do |tool|
      doc_content = "Attack Tool: #{tool[:name]}\n\n"
      doc_content += "Type: #{tool[:type]}\n\n"
      doc_content += "Description:\n#{tool[:description]}\n\n"

      doc_content += "Capabilities:\n"
      tool[:capabilities].each do |capability|
        doc_content += "- #{capability}\n"
      end

      doc_content += "\nDetection Methods:\n#{tool[:detection]}"

      documents << {
        id: "tool_#{tool[:name].downcase.gsub(/\s+/, '_')}",
        content: doc_content,
        metadata: {
          source: 'MITRE ATT&CK',
          type: 'attack_tool',
          tool_type: tool[:type],
          name: tool[:name]
        }
      }
    end

    # Add defense documents
    DEFENSES.each do |defense|
      doc_content = "Security Defense: #{defense[:name]}\n\n"
      doc_content += "Type: #{defense[:type]}\n\n"
      doc_content += "Effectiveness: #{defense[:effectiveness]}\n\n"
      doc_content += "Description:\n#{defense[:description]}\n\n"

      doc_content += "Capabilities:\n"
      defense[:capabilities].each do |capability|
        doc_content += "- #{capability}\n"
      end

      doc_content += "\nMitigates Attack Patterns:\n"
      defense[:attack_patterns].each do |pattern_id|
        pattern_name = ATTACK_PATTERNS.find { |p| p[:id] == pattern_id }&.dig(:name)
        doc_content += "- #{pattern_name} (#{pattern_id})\n" if pattern_name
      end

      documents << {
        id: "defense_#{defense[:name].downcase.gsub(/\s+/, '_')}",
        content: doc_content,
        metadata: {
          source: 'MITRE ATT&CK',
          type: 'defense',
          defense_type: defense[:type],
          effectiveness: defense[:effectiveness],
          name: defense[:name]
        }
      }
    end

    documents
  end

  # Convert MITRE ATT&CK knowledge to CAG triplets
  def self.to_cag_triplets
    triplets = []

    # Add attack pattern relationships
    ATTACK_PATTERNS.each do |pattern|
      # Pattern to tactic relationship
      triplets << {
        subject: pattern[:name],
        relationship: "IS_TYPE",
        object: pattern[:tactic],
        properties: {
          pattern_id: pattern[:id],
          source: "MITRE ATT&CK"
        }
      }

      # Pattern to techniques relationships
      pattern[:techniques].each do |technique|
        triplets << {
          subject: technique[:name],
          relationship: "IS_TECHNIQUE_OF",
          object: pattern[:name],
          properties: {
            technique_id: technique[:technique_id],
            source: "MITRE ATT&CK"
          }
        }
      end

      # Pattern to related tools relationships
      pattern[:related_tools].each do |tool_name|
        triplets << {
          subject: pattern[:name],
          relationship: "USES_TOOL",
          object: tool_name,
          properties: {
            pattern_id: pattern[:id],
            source: "MITRE ATT&CK"
          }
        }
      end

      # Pattern to mitigation relationships
      triplets << {
        subject: pattern[:mitigation],
        relationship: "MITIGATES",
        object: pattern[:name],
        properties: {
          pattern_id: pattern[:id],
          source: "MITRE ATT&CK"
        }
      }
    end

    # Add malware family relationships
    MALWARE_FAMILIES.each do |malware|
      # Malware to type relationship
      triplets << {
        subject: malware[:name],
        relationship: "IS_TYPE",
        object: malware[:type],
        properties: {
          source: "MITRE ATT&CK"
        }
      }

      # Malware to attack patterns relationships
      malware[:attack_patterns].each do |pattern_id|
        pattern = ATTACK_PATTERNS.find { |p| p[:id] == pattern_id }
        if pattern
          triplets << {
            subject: malware[:name],
            relationship: "IMPLEMENTS",
            object: pattern[:name],
            properties: {
              pattern_id: pattern_id,
              source: "MITRE ATT&CK"
            }
          }
        end
      end

      # Malware to mitigation relationships
      triplets << {
        subject: malware[:mitigation],
        relationship: "MITIGATES",
        object: malware[:name],
        properties: {
          source: "MITRE ATT&CK"
        }
      }
    end

    # Add attack tool relationships
    ATTACK_TOOLS.each do |tool|
      # Tool to type relationship
      triplets << {
        subject: tool[:name],
        relationship: "IS_TYPE",
        object: tool[:type],
        properties: {
          source: "MITRE ATT&CK"
        }
      }

      # Tool to attack patterns relationships
      tool[:attack_patterns].each do |pattern_id|
        pattern = ATTACK_PATTERNS.find { |p| p[:id] == pattern_id }
        if pattern
          triplets << {
            subject: tool[:name],
            relationship: "USED_IN",
            object: pattern[:name],
            properties: {
              pattern_id: pattern_id,
              source: "MITRE ATT&CK"
            }
          }
        end
      end
    end

    # Add defense relationships
    DEFENSES.each do |defense|
      # Defense to type relationship
      triplets << {
        subject: defense[:name],
        relationship: "IS_TYPE",
        object: defense[:type],
        properties: {
          effectiveness: defense[:effectiveness],
          source: "MITRE ATT&CK"
        }
      }

      # Defense to attack patterns relationships
      defense[:attack_patterns].each do |pattern_id|
        pattern = ATTACK_PATTERNS.find { |p| p[:id] == pattern_id }
        if pattern
          triplets << {
            subject: defense[:name],
            relationship: "MITIGATES",
            object: pattern[:name],
            properties: {
              pattern_id: pattern_id,
              effectiveness: defense[:effectiveness],
              source: "MITRE ATT&CK"
            }
          }
        end
      end
    end

    # Add some common cybersecurity entities and relationships
    common_entities = [
      { name: "IP Address", type: "Network Entity" },
      { name: "URL", type: "Network Entity" },
      { name: "Hash", type: "Forensic Artifact" },
      { name: "Filename", type: "File System Entity" },
      { name: "Port", type: "Network Entity" },
      { name: "Email", type: "Communication Entity" }
    ]

    common_entities.each do |entity|
      triplets << {
        subject: entity[:name],
        relationship: "IS_TYPE",
        object: entity[:type],
        properties: {
          source: "Cybersecurity Ontology"
        }
      }
    end

    triplets
  end
end
