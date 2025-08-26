require 'sinatra'
require 'json'
require 'ip2location_ruby'
require 'ip2proxy_ruby'
require 'open-uri'
require 'zip'
require 'fileutils'

# === Config ===
TOKEN       = ENV['IP2LOCATION_TOKEN'] || 'your_token_here'
DB11_CODE   = 'DB11LITEBINIPV6'
ASN_CODE    = 'DBASNLITEBINIPV6'
PX12_CODE   = 'PX12LITEBIN'
DB_DIR      = File.expand_path('data', __dir__)
DB11_FILE   = 'IP2LOCATION-LITE-DB11.IPV6.BIN'
ASN_FILE    = 'IP2LOCATION-LITE-ASN.IPV6.BIN'
PX12_FILE   = 'IP2PROXY-LITE-PX12.BIN'

# === DB Download Logic ===
def download_and_extract(file_code, target_filename)
  zip_path = File.join(DB_DIR, "#{file_code}.zip")
  FileUtils.mkdir_p(DB_DIR)

  url = "https://www.ip2location.com/download/?token=#{TOKEN}&file=#{file_code}"
  puts "[INFO] Downloading #{file_code} from #{url}"

  URI.open(url) do |remote_file|
    File.open(zip_path, 'wb') { |file| file.write(remote_file.read) }
  end

  # Validate ZIP file signature
  if File.zero?(zip_path) || File.read(zip_path, 4) != "PK\x03\x04"
    raise "Downloaded file #{zip_path} is not a valid ZIP archive."
  end

  Zip::File.open(zip_path) do |zip_file|
    zip_file.each do |entry|
      if entry.name == target_filename
        entry.extract(File.join(DB_DIR, target_filename)) { true }
        puts "[INFO] Extracted #{entry.name} to #{DB_DIR}"
      end
    end
  end

  File.delete(zip_path) if File.exist?(zip_path)
end

# === App Init ===
configure do
  set :threaded, true
  FileUtils.mkdir_p(DB_DIR)

  begin
    puts "[INFO] Attempting to download latest IP2Location DBs..."
    download_and_extract(DB11_CODE, DB11_FILE)
    download_and_extract(ASN_CODE, ASN_FILE)
    download_and_extract(PX12_CODE, PX12_FILE)
    puts "[INFO] Initial DB download complete."
  rescue => e
    puts "[WARN] DB download failed: #{e.message}"
    puts "[WARN] Using existing files in ./data if available."
  end

  # Start background thread for daily updates
  Thread.new do
    loop do
      sleep 86_400  # 24 hours
      begin
        puts "[INFO] Daily DB update starting..."
        download_and_extract(DB11_CODE, DB11_FILE)
        download_and_extract(ASN_CODE, ASN_FILE)
        download_and_extract(PX12_CODE, PX12_FILE)
        puts "[INFO] Daily DB update completed."
      rescue => e
        puts "[WARN] Daily DB update failed: #{e.message}"
      end
    end
  end
end

# === Helpers ===
helpers do
  def ip2location_db11
    Thread.current[:ip2location_db11] ||= Ip2location.new.open(File.join(DB_DIR, DB11_FILE))
  end

  def ip2location_asn
    Thread.current[:ip2location_asn] ||= Ip2location.new.open(File.join(DB_DIR, ASN_FILE))
  end

  def ip2proxy_px12
    Thread.current[:ip2proxy_px12] ||= Ip2proxy.new.open(File.join(DB_DIR, PX12_FILE))
  end
end

# === Routes ===
get '/' do
  'IP2Location API Service is running! This uses IP2Location LITE data available from http://www.ip2location.com.'
end

get '/ip/:ip_address' do
  content_type :json

  begin
    ip_address = params['ip_address']

    record_db11 = ip2location_db11.get_all(ip_address)
    record_asn  = ip2location_asn.get_all(ip_address)
    record_px12 = ip2proxy_px12.get_all(ip_address)

    {
      ip:                  ip_address,
      alpha2_country_code: record_db11['country_short'],
      country:             record_db11['country_long'],
      region:              record_db11['region'],
      city:                record_db11['city'],
      latitude:            record_db11['latitude'],
      longitude:           record_db11['longitude'],
      zipcode:             record_db11['zipcode'],
      timezone:            record_db11['timezone'],
      asn_asn:             "AS#{record_asn['asn']}",
      asn_name:            record_asn['as'],
      is_proxy:            record_px12['is_proxy'] == 1,
      proxy_type:          record_px12['proxy_type'],
      threat:              record_px12['threat'],
      provider:            record_px12['provider']
    }.to_json
  rescue StandardError => e
    status 400
    { error: e.message }.to_json
  end
end

# === Manual Refresh Endpoint ===
post '/refresh' do
  content_type :json

  begin
    download_and_extract(DB11_CODE, DB11_FILE)
    download_and_extract(ASN_CODE, ASN_FILE)
    download_and_extract(PX12_CODE, PX12_FILE)
    { message: 'Database refreshed successfully' }.to_json
  rescue => e
    status 500
    { error: e.message }.to_json
  end
end
