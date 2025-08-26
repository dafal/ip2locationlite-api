# IP2Location LITE API Service

A Ruby/Sinatra REST API service that provides comprehensive IP geolocation and proxy detection using IP2Location databases. The service combines geolocation data, ASN information, and proxy/anonymizer detection in a single API response.

## Features

- **IP Geolocation**: Country, region, city, coordinates, timezone, and postal code
- **ASN Information**: Autonomous System Number and organization name  
- **Proxy Detection**: Identifies proxy servers, VPNs, and anonymizer services
- **Threat Assessment**: Security threat analysis for IP addresses
- **Auto-Updates**: Daily automatic database updates
- **Thread-Safe**: Concurrent request handling with thread-local database instances

## Databases Used

- **DB11LITEBINIPV6**: IP geolocation data (IP2Location LITE)
- **DBASNLITEBINIPV6**: ASN (Autonomous System Number) data (IP2Location LITE)  
- **PX12LITEBIN**: Proxy/anonymizer detection data (IP2Proxy LITE)

## Quick Start

### Using Docker (Recommended)

```bash
# Start the service
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the service
docker-compose down
```

### Local Development

```bash
# Install dependencies
bundle install

# Run the application
bundle exec puma --port 4567 --threads 0:50

# Or with rackup
bundle exec rackup -p 4567
```

## API Endpoints

### Health Check
```
GET /
```

Returns service status message.

### IP Lookup
```
GET /ip/{ip_address}
```

Returns comprehensive IP information including geolocation and proxy detection.

**Example Request:**
```bash
curl http://localhost:4567/ip/8.8.8.8
```

**Example Response:**
```json
{
  "ip": "8.8.8.8",
  "alpha2_country_code": "US",
  "country": "United States of America",
  "region": "California", 
  "city": "Mountain View",
  "latitude": "37.386051177978516",
  "longitude": "-122.08384704589844",
  "zipcode": "94035",
  "timezone": "-07:00",
  "asn_asn": "AS15169",
  "asn_name": "Google LLC",
  "is_proxy": false,
  "proxy_type": "-",
  "threat": "-",
  "provider": "-"
}
```

### Manual Database Refresh
```
POST /refresh
```

Manually triggers database updates for all three databases.

**Example Request:**
```bash
curl -X POST http://localhost:4567/refresh
```

## Configuration

### Environment Variables

- `IP2LOCATION_TOKEN`: Your IP2Location download token (optional for LITE databases)

Set the token for automatic database updates:
```bash
export IP2LOCATION_TOKEN=your_actual_token_here
```

### Database Files

The service automatically downloads and updates database files to the `data/` directory:
- `IP2LOCATION-LITE-DB11.IPV6.BIN`
- `IP2LOCATION-LITE-ASN.IPV6.BIN`
- `IP2PROXY-LITE-PX12.BIN`

## Dependencies

- Ruby 3.2+
- Sinatra web framework
- ip2location_ruby gem
- ip2proxy_ruby gem
- Puma web server
- rubyzip for archive handling

## Architecture

- **Main Application**: `app.rb` - Sinatra web app with REST endpoints
- **Auto-Updates**: Background thread updates databases every 24 hours
- **Thread Safety**: Uses thread-local storage for database instances
- **Error Handling**: Graceful fallback to existing files if downloads fail
- **Container Support**: Docker and Docker Compose ready

## Response Fields

### Geolocation Fields
- `ip`: The queried IP address
- `alpha2_country_code`: ISO 3166-1 alpha-2 country code
- `country`: Full country name
- `region`: State/province/region name
- `city`: City name
- `latitude`: Geographic latitude coordinate
- `longitude`: Geographic longitude coordinate
- `zipcode`: Postal/ZIP code
- `timezone`: UTC timezone offset

### ASN Fields
- `asn_asn`: Autonomous System Number (e.g., "AS15169")
- `asn_name`: Organization name for the ASN

### Proxy Detection Fields
- `is_proxy`: Boolean indicating if IP is detected as proxy/VPN
- `proxy_type`: Type of proxy service detected
- `threat`: Threat level assessment
- `provider`: Infrastructure provider information

## License

This project uses IP2Location LITE databases which are available for free from [IP2Location.com](http://www.ip2location.com).