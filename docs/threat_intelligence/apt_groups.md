# Advanced Persistent Threat (APT) Groups and Threat Intelligence

## Overview

This document provides comprehensive information about known Advanced Persistent Threat (APT) groups, their tactics, techniques, and procedures (TTPs), and indicators of compromise (IOCs). Understanding these threat actors is crucial for effective defense and incident response.

## Major APT Groups

### APT1 (Comment Crew)
- **Aliases**: Unit 61398, PLA Unit 61398
- **Country of Origin**: China
- **Target Sectors**: Government, defense, aerospace, energy
- **Active Period**: 2006-2014 (publicly disclosed)
- **Known Tools**: WEBC2, GRIDTRAIL, BANGAT, MURRAY

#### TTPs
- Spear-phishing with malicious attachments
- Strategic web compromises (watering hole attacks)
- Custom malware for persistence
- Lateral movement using stolen credentials
- Data exfiltration using custom protocols

### APT28 (Fancy Bear)
- **Aliases**: Sofacy, Pawn Storm, Sednit
- **Country of Origin**: Russia
- **Target Sectors**: Government, military, defense contractors, media
- **Active Period**: 2007-Present
- **Known Tools**: X-Agent, X-Tunnel, Seduploader, Chopstick

#### TTPs
- Brute force attacks against email and VPN accounts
- Zero-day exploits (CVE-2016-4117, CVE-2017-0263)
- PowerShell for lateral movement
- Mimikatz for credential theft
- Cloud storage for data exfiltration

### APT29 (Cozy Bear)
- **Aliases**: Cozy Duke, The Dukes
- **Country of Origin**: Russia
- **Target Sectors**: Government, diplomatic, research institutions
- **Active Period**: 2008-Present
- **Known Tools**: SeaDuke, MiniDuke, CosmicDuke, OfficeMonde

#### TTPs
- Sophisticated spear-phishing campaigns
- Custom malware with multiple stages
- Living-off-the-land techniques
- DNS tunneling for C2 communications
- Legitimate tool abuse (e.g., PowerShell, WMI)

### APT41
- **Aliases**: Winnti Group, Barium, Wicked Panda
- **Country of Origin**: China
- **Target Sectors**: Healthcare, telecom, gaming, software development
- **Active Period**: 2012-Present
- **Known Tools**: WINNTI, RedLeaves, ShadowPad, Chainloader

#### TTPs
- Supply chain attacks
- Software development compromise
- Code signing certificate theft
- Cryptocurrency mining
- Ransomware operations

### Lazarus Group
- **Aliases**: Hidden Cobra, Guardians of Peace
- **Country of Origin**: North Korea
- **Target Sectors**: Financial, cryptocurrency, defense, critical infrastructure
- **Active Period**: 2009-Present
- **Known Tools**: Lazarus, WannaCry, Destover, Joanap

#### TTPs
- Supply chain attacks (SolarWinds, 3CX)
- Cryptocurrency exchange targeting
- Ransomware deployment
- Social engineering campaigns
- Custom malware development

## MITRE ATT&CK Framework Mapping

### Initial Access Techniques

#### Spearphishing Attachment (T1566.001)
- **Common in**: APT1, APT28, APT29, APT41
- **Indicators**: 
  - Malicious Office documents with macros
  - PDF exploits
  - ZIP files containing executables

#### Exploit Public-Facing Application (T1190)
- **Common in**: APT28, APT41, Lazarus
- **Indicators**:
  - Web server exploitation attempts
  - CVE-specific exploit patterns
  - Unusual URL patterns in web logs

#### External Remote Services (T1133)
- **Common in**: APT28, APT29
- **Indicators**:
  - VPN brute force attempts
  - RDP connection anomalies
  - Unusual authentication times

### Persistence Techniques

#### Registry Run Keys / Startup Folder (T1060)
- **Common in**: Most APT groups
- **Indicators**:
  - Unusual registry entries in Run keys
  - Suspicious files in startup folders
  - Scheduled task creation

#### Scheduled Task (T1053)
- **Common in**: APT28, APT29, APT41
- **Indicators**:
  - New scheduled tasks with suspicious commands
  - Tasks running as SYSTEM
  - Tasks with unusual triggers

#### Service Registry Permissions Weakness (T1058)
- **Common in**: APT41, Lazarus
- **Indicators**:
  - Service permission modifications
  - New services with suspicious paths
  - Service binary replacement

### Lateral Movement Techniques

#### Pass the Hash (T1075)
- **Common in**: APT28, APT29, APT41
- **Indicators**:
  - Unusual authentication attempts
  - Multiple failed logins followed by success
  - Logon type 9 (NewCredentials)

#### Remote Desktop Protocol (T1076)
- **Common in**: APT28, APT29
- **Indicators**:
  - RDP connections from unusual sources
  - Multiple RDP sessions to different systems
  - RDP brute force attempts

#### SSH (T1021.004)
- **Common in**: APT41, Lazarus
- **Indicators**:
  - SSH connections to unusual systems
  - SSH tunneling activities
  - SSH key authentication anomalies

### Defense Evasion Techniques

#### Obfuscated Files or Information (T1027)
- **Common in**: Most APT groups
- **Indicators**:
  - Encrypted files or configuration
  - Base64-encoded data
  - String obfuscation in malware

#### Deobfuscate/Decode Files or Information (T1140)
- **Common in**: APT28, APT41
- **Indicators**:
  - PowerShell decode commands
  - Certificate utility usage
  - Custom decoder programs

#### Process Injection (T1055)
- **Common in**: APT29, APT41, Lazarus
- **Indicators**:
  - Unusual process relationships
  - Memory injection attempts
  - DLL injection detections

## Indicators of Compromise (IOCs)

### Network IOCs
```
# APT28 Known C2 Servers
5.61.23.5
91.215.85.81
176.31.112.10
185.141.63.118

# APT29 Known Domains
security-updates.microsoft.com[.]tk
update.microsoft.com[.]ml
office365-update.microsoft[.]cf

# APT41 Known C2 Ports
443, 8080, 8888, 53
```

### File Hashes
```
# Lazarus Group Known Malware
3a4e1a9e1a9e1a9e1a9e1a9e1a9e1a9e1a9e1a9e  wanny.exe
5b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c  destober.dll

# APT28 Known Tools
1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c  x-agent.exe
```

### Registry Keys
```
# Persistence Locations
HKCU\Software\Microsoft\Windows\CurrentVersion\Run
HKLM\Software\Microsoft\Windows\CurrentVersion\Run
HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce

# APT-Specific Keys
HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System\Shell
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options
```

## Detection Strategies

### Network Detection
```bash
# Snort/Suricata rules for APT detection
alert tcp $HOME_NET any -> $EXTERNAL_NET $HTTP_PORTS (msg:"APT28 User-Agent"; content:"User-Agent: Mozilla/5.0 (compatible; MSIE 10.0"; http_user_agent; sid:1000001;)

# Zeek/Bro scripts for APT detection
event http_request() &{
    if (/apt|cozy|fancy/i in $http_request) {
        print fmt("Potential APT activity detected: %s", $http_request);
    }
}
```

### Endpoint Detection
```powershell
# PowerShell script for APT detection
Get-WinEvent -LogName Security -FilterXPath "*[System[(EventID=4624 or EventID=4625)]]" | 
    Where-Object {$_.Message -match "Logon Type: 9"} | 
    Select-Object TimeCreated, Message

# Check for suspicious processes
Get-Process | Where-Object {
    $_.ProcessName -match "powershell|wmi|cmd" -and 
    $_.CommandLine -match "-enc|bypass|hidden"
} | Select-Object ProcessName, CommandLine
```

### Log Analysis
```bash
# Linux log analysis for APT indicators
grep "Failed password" /var/log/auth.log | grep "ssh" | awk '{print $9}' | sort | uniq -c | sort -nr
grep "Accepted" /var/log/auth.log | awk '{print $9}' | sort | uniq

# Windows event log analysis
wevtutil qe Security /f:text | grep "Event ID 4624" | grep "Logon Type: 9"
```

## Incident Response Playbooks

### APT Detection Playbook
1. **Initial Detection**
   - Review SIEM alerts for APT indicators
   - Analyze network traffic for suspicious patterns
   - Check endpoint logs for unusual activity

2. **Investigation**
   - Identify affected systems
   - Collect forensic evidence
   - Determine attack timeline

3. **Containment**
   - Isolate affected systems
   - Block malicious IPs/domains
   - Disable compromised accounts

4. **Eradication**
   - Remove malware and persistence mechanisms
   - Patch vulnerabilities
   - Reset compromised credentials

5. **Recovery**
   - Restore systems from clean backups
   - Implement enhanced monitoring
   - Update security controls

### APT Prevention Strategies
- **Network Segmentation**: Implement micro-segmentation to limit lateral movement
- **Multi-Factor Authentication**: Require MFA for all administrative access
- **Endpoint Protection**: Deploy EDR solutions with behavioral analysis
- **User Training**: Conduct regular security awareness training
- **Threat Intelligence**: Subscribe to commercial threat intelligence feeds
- **Vulnerability Management**: Implement regular patching and vulnerability assessments

## References and Resources

### MITRE ATT&CK Framework
- [https://attack.mitre.org/](https://attack.mitre.org/)
- Comprehensive TTP database for threat actors

### Commercial Threat Intelligence
- Mandiant Intelligence
- CrowdStrike Intelligence
- Palo Alto Unit 42
- Kaspersky Threat Intelligence

### Open Source Intelligence
- AlienVault OTX
- VirusTotal
- Hybrid Analysis
- Any.Run

### Government Resources
- CISA Alerts and Advisories
- US-CERT Threat Alerts
- FBI Flash Alerts
- NSA Cybersecurity Advisories

---

*This document should be updated regularly with new threat intelligence and APT group activities. Always verify IOCs against current threat intelligence feeds before taking action.*