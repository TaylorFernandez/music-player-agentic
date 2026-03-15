#!/bin/bash

# =============================================================================
# PostgreSQL Setup Script for Music Player Application
# =============================================================================
# This script installs and configures PostgreSQL for the Music Player backend.
# It creates the database, user, and configures basic settings.
#
# Usage: ./scripts/setup_postgres.sh
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_NAME="${DB_NAME:-musicplayer}"
DB_USER="${DB_USER:-musicplayer}"
DB_PASSWORD=""
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

# PostgreSQL version (adjust as needed)
PG_VERSION="${PG_VERSION:-14}"

# Log function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        error "Please do not run this script as root"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif [ -f /etc/debian_version ]; then
        OS="Debian"
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        OS="Red Hat"
        VER=""
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    log "Detected OS: $OS $VER"
}

# Check if PostgreSQL is installed
check_postgres() {
    if command -v psql &> /dev/null; then
        log "PostgreSQL is already installed"
        psql --version
        return 0
    else
        log "PostgreSQL is not installed"
        return 1
    fi
}

# Install PostgreSQL on Ubuntu/Debian
install_postgres_debian() {
    log "Installing PostgreSQL on Ubuntu/Debian..."

    sudo apt-get update
    sudo apt-get install -y postgresql postgresql-contrib libpq-dev

    # Start and enable PostgreSQL service
    sudo systemctl start postgresql
    sudo systemctl enable postgresql

    success "PostgreSQL installed successfully"
}

# Install PostgreSQL on Fedora/RHEL
install_postgres_fedora() {
    log "Installing PostgreSQL on Fedora/RHEL..."

    sudo dnf install -y postgresql postgresql-server

    # Initialize database
    sudo postgresql-setup --initdb

    # Start and enable service
    sudo systemctl start postgresql
    sudo systemctl enable postgresql

    success "PostgreSQL installed successfully"
}

# Install PostgreSQL on macOS
install_postgres_macos() {
    log "Installing PostgreSQL on macOS..."

    if command -v brew &> /dev/null; then
        brew install postgresql@14
        brew services start postgresql@14
        success "PostgreSQL installed successfully"
    else
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi
}

# Install PostgreSQL based on OS
install_postgres() {
    detect_os

    case "$OS" in
        *Ubuntu*|*Debian*)
            install_postgres_debian
            ;;
        *Fedora*|*Red*Hat*|*CentOS*)
            install_postgres_fedora
            ;;
        *Darwin*|*macOS*)
            install_postgres_macos
            ;;
        *)
            error "Unsupported OS: $OS"
            error "Please install PostgreSQL manually"
            exit 1
            ;;
    esac
}

# Generate random password
generate_password() {
    python3 -c "import secrets; print(secrets.token_urlsafe(32))"
}

# Create database and user
create_database() {
    log "Creating database and user..."

    # Prompt for password or generate one
    read -sp "Enter password for database user (leave empty to generate): " DB_PASSWORD
    echo

    if [ -z "$DB_PASSWORD" ]; then
        DB_PASSWORD=$(generate_password)
        warning "Generated password: $DB_PASSWORD"
        warning "Please save this password securely!"
    fi

    # Create SQL commands
    SQL_COMMANDS="
-- Create database
CREATE DATABASE $DB_NAME;

-- Create user with password
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

-- Connect to database
\\connect $DB_NAME;

-- Grant schema permissions
GRANT ALL ON SCHEMA public TO $DB_USER;

-- Grant table permissions
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
"

    # Execute SQL commands
    echo "$SQL_COMMANDS" | sudo -u postgres psql

    success "Database and user created successfully"
}

# Configure PostgreSQL
configure_postgres() {
    log "Configuring PostgreSQL..."

    # Find PostgreSQL configuration directory
    if [ -d "/etc/postgresql" ]; then
        # Ubuntu/Debian style
        CONF_DIR=$(sudo find /etc/postgresql -name "postgresql.conf" -printf "%h\n" | head -1)
    elif [ -d "/var/lib/pgsql/data" ]; then
        # Fedora/RHEL style
        CONF_DIR="/var/lib/pgsql/data"
    else
        warning "Could not find PostgreSQL configuration directory"
        return 1
    fi

    log "Configuration directory: $CONF_DIR"

    # Backup original configuration
    sudo cp "$CONF_DIR/postgresql.conf" "$CONF_DIR/postgresql.conf.backup"
    sudo cp "$CONF_DIR/pg_hba.conf" "$CONF_DIR/pg_hba.conf.backup"

    # Update postgresql.conf
    sudo tee -a "$CONF_DIR/postgresql.conf" > /dev/null << EOF

# Music Player Application Configuration
listen_addresses = 'localhost'
port = $DB_PORT
max_connections = 100
shared_buffers = 256MB
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
EOF

    # Update pg_hba.conf
    sudo tee -a "$CONF_DIR/pg_hba.conf" > /dev/null << EOF

# Music Player Application Access
local   $DB_NAME        $DB_USER                                 md5
host    $DB_NAME        $DB_USER        127.0.0.1/32            md5
host    $DB_NAME        $DB_USER        ::1/128                 md5
EOF

    # Restart PostgreSQL
    sudo systemctl restart postgresql

    success "PostgreSQL configured successfully"
}

# Test database connection
test_connection() {
    log "Testing database connection..."

    # Set environment variables for connection
    export PGPASSWORD="$DB_PASSWORD"

    # Test connection
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1; then
        success "Database connection successful!"
        return 0
    else
        error "Database connection failed"
        error "Please check your configuration"
        return 1
    fi
}

# Create .env file
create_env_file() {
    log "Creating .env file..."

    ENV_FILE="backend/.env"

    if [ -f "$ENV_FILE" ]; then
        warning "$ENV_FILE already exists"
        read -p "Overwrite? (y/N): " OVERWRITE
        if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
            log "Skipping .env file creation"
            return 0
        fi
    fi

    # Generate secret key
    SECRET_KEY=$(python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")

    # Create .env file
    cat > "$ENV_FILE" << EOF
# =============================================================================
# Music Player Backend - Environment Configuration
# =============================================================================
# Generated by setup_postgres.sh on $(date)
# =============================================================================

# Django Settings
SECRET_KEY=$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=localhost,127.0.0.1

# Database Settings (PostgreSQL)
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT

# CORS Settings
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Email Settings (configure as needed)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
DEFAULT_FROM_EMAIL=noreply@musicplayer.com

# Security Settings
SECURE_SSL_REDIRECT=False
SESSION_COOKIE_SECURE=False
CSRF_COOKIE_SECURE=False

# Logging
LOG_LEVEL=INFO
EOF

    # Set permissions
    chmod 600 "$ENV_FILE"

    success "Created $ENV_FILE"
    warning "Please review and update email settings in $ENV_FILE"
}

# Create backup script
create_backup_script() {
    log "Creating backup script..."

    BACKUP_SCRIPT="scripts/backup_postgres.sh"

    cat > "$BACKUP_SCRIPT" << 'EOF'
#!/bin/bash

# PostgreSQL Backup Script for Music Player Application
# Usage: ./scripts/backup_postgres.sh

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups}"
DB_NAME="${DB_NAME:-musicplayer}"
DB_USER="${DB_USER:-musicplayer}"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup database
echo "Creating backup..."
sudo -u postgres pg_dump "$DB_NAME" | gzip > "$BACKUP_FILE"

# Keep only last 7 days
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete

# Log backup
echo "[$(date)] Backup created: $BACKUP_FILE" >> "$BACKUP_DIR/backup.log"

echo "Backup completed: $BACKUP_FILE"
EOF

    chmod +x "$BACKUP_SCRIPT"

    success "Created $BACKUP_SCRIPT"
}

# Print summary
print_summary() {
    echo ""
    echo "=========================================="
    echo "    PostgreSQL Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Database Details:"
    echo "  Database Name: $DB_NAME"
    echo "  User Name:      $DB_USER"
    echo "  Password:        $DB_PASSWORD"
    echo "  Host:            $DB_HOST"
    echo "  Port:            $DB_PORT"
    echo ""
    echo "Configuration Files:"
    echo "  Environment:     backend/.env"
    echo "  Backup Script:   scripts/backup_postgres.sh"
    echo ""
    echo "Next Steps:"
    echo "  1. Review backend/.env file"
    echo "  2. cd backend"
    echo "  3. source venv/bin/activate"
    echo "  4. pip install -r requirements-prod.txt"
    echo "  5. python manage.py migrate"
    echo "  6. python manage.py createsuperuser"
    echo "  7. python manage.py runserver"
    echo ""
    warning "IMPORTANT: Save your database password securely!"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "=========================================="
    echo "  Music Player - PostgreSQL Setup"
    echo "=========================================="
    echo ""

    # Check if running as root
    check_root

    # Detect OS
    detect_os

    # Check/install PostgreSQL
    if ! check_postgres; then
        read -p "PostgreSQL is not installed. Install now? (y/N): " INSTALL
        if [ "$INSTALL" = "y" ] || [ "$INSTALL" = "Y" ]; then
            install_postgres
        else
            error "PostgreSQL is required. Exiting."
            exit 1
        fi
    fi

    # Create database
    read -p "Create database and user? (Y/n): " CREATE_DB
    if [ "$CREATE_DB" != "n" ] && [ "$CREATE_DB" != "N" ]; then
        create_database
    fi

    # Configure PostgreSQL
    read -p "Configure PostgreSQL? (Y/n): " CONFIGURE
    if [ "$CONFIGURE" != "n" ] && [ "$CONFIGURE" != "N" ]; then
        configure_postgres
    fi

    # Test connection
    read -p "Test database connection? (Y/n): " TEST
    if [ "$TEST" != "n" ] && [ "$TEST" != "N" ]; then
        test_connection
    fi

    # Create .env file
    read -p "Create .env file? (Y/n): " CREATE_ENV
    if [ "$CREATE_ENV" != "n" ] && [ "$CREATE_ENV" != "N" ]; then
        create_env_file
    fi

    # Create backup script
    read -p "Create backup script? (Y/n): " CREATE_BACKUP
    if [ "$CREATE_BACKUP" != "n" ] && [ "$CREATE_BACKUP" != "N" ]; then
        create_backup_script
    fi

    # Print summary
    print_summary
}

# Run main function
main
