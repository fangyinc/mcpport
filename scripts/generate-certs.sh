#!/bin/bash
# SSL Certificate Generation Script - Supports Custom Domain and IP Address
# Usage: ./generate-certs.sh --domain example.com --ip 192.168.1.10 --output /path/to/certs

set -e

# DEFAULTS
DOMAIN="localhost"
IP_ADDRESSES="127.0.0.1"
OUTPUT_DIR="./certs"
DAYS=365
KEY_SIZE=2048
CA_NAME="My Custom CA"
COUNTRY="CN"
STATE="Beijing"
LOCALITY="Beijing"
ORGANIZATION="My Organization"
OU="IT Department"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --domain)
      DOMAIN="$2"
      shift 2
      ;;
    --ip)
      if [[ -z "$2" || "$2" == --* ]]; then
        echo "Error: --ip requires an IP address"
        exit 1
      fi
      if [[ "$IP_ADDRESSES" == "127.0.0.1" ]]; then
        IP_ADDRESSES="$2"
      else
        IP_ADDRESSES="$IP_ADDRESSES,$2"
      fi
      shift 2
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --days)
      DAYS="$2"
      shift 2
      ;;
    --key-size)
      KEY_SIZE="$2"
      shift 2
      ;;
    --ca-name)
      CA_NAME="$2"
      shift 2
      ;;
    --country)
      COUNTRY="$2"
      shift 2
      ;;
    --state)
      STATE="$2"
      shift 2
      ;;
    --locality)
      LOCALITY="$2"
      shift 2
      ;;
    --org)
      ORGANIZATION="$2"
      shift 2
      ;;
    --ou)
      OU="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --domain DOMAIN       Domain name for the certificate (default: localhost)"
      echo "  --ip IP               IP address to include in the certificate (can be specified multiple times)"
      echo "  --output DIR          Output directory for certificates (default: ./certs)"
      echo "  --days DAYS           Validity period in days (default: 365)"
      echo "  --key-size SIZE       RSA key size in bits (default: 2048)"
      echo "  --ca-name NAME        CA common name (default: 'My Custom CA')"
      echo "  --country CODE        Country code (default: CN)"
      echo "  --state STATE         State or province (default: Beijing)"
      echo "  --locality LOCALITY   Locality name (default: Beijing)"
      echo "  --org ORG             Organization name (default: 'My Organization')"
      echo "  --ou OU               Organizational unit (default: 'IT Department')"
      echo "  --help                Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
echo "Certificates will be saved to: $OUTPUT_DIR"

# Create OpenSSL configuration file
cat > "$OUTPUT_DIR/openssl.cnf" << EOF
[ req ]
default_bits        = $KEY_SIZE
default_md          = sha256
prompt              = no
encrypt_key         = no
distinguished_name  = req_dn
req_extensions      = req_ext
x509_extensions     = x509_ext

[ req_dn ]
countryName         = $COUNTRY
stateOrProvinceName = $STATE
localityName        = $LOCALITY
organizationName    = $ORGANIZATION
organizationalUnitName = $OU
commonName          = $DOMAIN

[ req_ext ]
subjectAltName      = @alt_names

[ x509_ext ]
subjectAltName      = @alt_names
basicConstraints    = critical, CA:false
keyUsage            = critical, digitalSignature, keyEncipherment
extendedKeyUsage    = serverAuth, clientAuth

[ ca ]
default_ca          = CA_default

[ CA_default ]
dir                 = $OUTPUT_DIR
certs               = $OUTPUT_DIR
new_certs_dir       = $OUTPUT_DIR
database            = $OUTPUT_DIR/index.txt
serial              = $OUTPUT_DIR/serial
RANDFILE            = $OUTPUT_DIR/rand
private_key         = $OUTPUT_DIR/ca.key
certificate         = $OUTPUT_DIR/ca.crt
default_days        = $DAYS
default_md          = sha256
policy              = policy_match
copy_extensions     = copy

[ policy_match ]
countryName         = match
stateOrProvinceName = match
organizationName    = match
organizationalUnitName = optional
commonName          = supplied

[ alt_names ]
DNS.1 = $DOMAIN
EOF

# Add additional domain names if the domain is not localhost and localhost is not explicitly added
if [[ "$DOMAIN" != "localhost" ]]; then
    echo "DNS.2 = localhost" >> "$OUTPUT_DIR/openssl.cnf"
fi

# Add IP addresses to the configuration file
IFS=',' read -r -a IP_ARRAY <<< "$IP_ADDRESSES"
for i in "${!IP_ARRAY[@]}"; do
    echo "IP.$((i+1)) = ${IP_ARRAY[$i]}" >> "$OUTPUT_DIR/openssl.cnf"
done

# Prepare CA database files
touch "$OUTPUT_DIR/index.txt"
echo "01" > "$OUTPUT_DIR/serial"

echo "=== Generating CA Key ==="
openssl genrsa -out "$OUTPUT_DIR/ca.key" $KEY_SIZE

echo "=== Generating CA Certificate ==="
openssl req -x509 -new -nodes -key "$OUTPUT_DIR/ca.key" -sha256 -days $((DAYS*2)) \
    -out "$OUTPUT_DIR/ca.crt" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$OU/CN=$CA_NAME"

echo "=== Generating Server Key ==="
openssl genrsa -out "$OUTPUT_DIR/server.key" $KEY_SIZE

echo "=== Generating Server CSR ==="
openssl req -new -key "$OUTPUT_DIR/server.key" \
    -out "$OUTPUT_DIR/server.csr" \
    -config "$OUTPUT_DIR/openssl.cnf"

echo "=== Signing Server Certificate with our CA ==="
openssl x509 -req -in "$OUTPUT_DIR/server.csr" \
    -CA "$OUTPUT_DIR/ca.crt" \
    -CAkey "$OUTPUT_DIR/ca.key" \
    -CAcreateserial \
    -out "$OUTPUT_DIR/server.crt" \
    -days $DAYS \
    -sha256 \
    -extfile "$OUTPUT_DIR/openssl.cnf" \
    -extensions x509_ext

echo "=== Verifying Certificate ==="
openssl verify -CAfile "$OUTPUT_DIR/ca.crt" "$OUTPUT_DIR/server.crt"

echo "=== Certificate Information ==="
openssl x509 -in "$OUTPUT_DIR/server.crt" -text -noout | grep -E 'Subject:|Issuer:|Not Before:|Not After:|DNS:|IP Address:'

echo ""
echo "=== Certificates Generated Successfully ==="
echo "CA Certificate:      $OUTPUT_DIR/ca.crt"
echo "Server Certificate:  $OUTPUT_DIR/server.crt"
echo "Server Key:          $OUTPUT_DIR/server.key"
echo ""
echo "To use with your WebSocket server:"
echo "  --ssl-enabled --ssl-keyfile $OUTPUT_DIR/server.key --ssl-certfile $OUTPUT_DIR/server.crt"
echo ""
echo "To verify from client side:"
echo "  --ssl-ca-cert $OUTPUT_DIR/ca.crt"
echo ""
echo "To skip verification (not recommended for production):"
echo "  --no-ssl-verify"