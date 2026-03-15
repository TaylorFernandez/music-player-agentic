# Update package list
sudo apt-get update

# Install PostgreSQL and additional modules
sudo apt-get install postgresql postgresql-contrib libpq-dev

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verify installation
psql --version
```

### Fedora/RHEL/CentOS

```bash
# Install PostgreSQL
sudo dnf install postgresql postgresql-server

# Initialize database
sudo postgresql-setup --initdb

# Start and enable service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verify installation
psql --version
```

### macOS (using Homebrew)

```bash
# Install PostgreSQL
brew install postgresql@14

# Start service
brew services start postgresql@14

# Verify installation
psql --version
```

## Database Setup

### Step 1: Create Database and User

```bash
# Switch to postgres user
sudo -u postgres psql

# Create database
CREATE DATABASE musicplayer;

# Create user with password
CREATE USER musicplayer WITH PASSWORD 'your_secure_password_here';

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE musicplayer TO musicplayer;

# Exit psql
\q
```

### Step 2: Configure Authentication

Edit PostgreSQL configuration file:

```bash
# Find postgresql.conf location
sudo -u postgres psql -c "SHOW config_file;"

# Edit configuration (Ubuntu/Debian)
sudo nano /etc/postgresql/14/main/postgresql.conf

# For Fedora/RHEL, the location may differ
sudo nano /var/lib/pgsql/data/postgresql.conf
```

Update the following settings:

```conf
# Listen on all addresses (for development)
listen_addresses = 'localhost'

# Or for production, be more restrictive:
# listen_addresses = '127.0.0.1'

# Set port (default is 5432)
port = 5432

# Configure max connections
max_connections = 100

# Set shared buffers (25% of total RAM recommended)
shared_buffers = 256MB

# Configure logging
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
```

### Step 3: Configure pg_hba.conf

Edit client authentication configuration:

```bash
# Ubuntu/Debian
sudo nano /etc/postgresql/14/main/pg_hba.conf

# Fedora/RHEL
sudo nano /var/lib/pgsql/data/pg_hba.conf
```

Add or modify these lines:

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local connections
local   musicplayer     musicplayer                             md5
local   all             all                                     peer

# IPv4 local connections (use md5 for password authentication)
host    musicplayer     musicplayer     127.0.0.1/32            md5
host    all             all             127.0.0.1/32            md5

# IPv6 local connections
host    musicplayer     musicplayer     ::1/128                 md5
host    all             all             ::1/128                 md5

# For production, you might want to restrict to specific IPs
# host    musicplayer     musicplayer     192.168.1.0/24         md5
```

### Step 4: Restart PostgreSQL

```bash
# Restart service
sudo systemctl restart postgresql

# Check status
sudo systemctl status postgresql
```

## Django Configuration

### Step 1: Install Dependencies

```bash
cd backend
source venv/bin/activate

# Install PostgreSQL adapter
pip install psycopg2-binary

# Or for production (requires PostgreSQL development headers)
# pip install psycopg2
```

### Step 2: Configure Django Settings

Update `backend/musicplayer/settings.py` or create environment-specific settings:

```python
# Development (SQLite)
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Production (PostgreSQL) - Use settings_prod.py
# Or use environment variables:
import os

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'musicplayer'),
        'USER': os.environ.get('DB_USER', 'musicplayer'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
        'OPTIONS': {
            'connect_timeout': 10,
            'options': '-c statement_timeout=30000',
        },
        'CONN_MAX_AGE': 600,  # 10 minutes
        'ATOMIC_REQUESTS': True,
    }
}
```

### Step 3: Set Environment Variables

Create `.env` file in `backend/`:

```bash
# Database settings
DB_NAME=musicplayer
DB_USER=musicplayer
DB_PASSWORD=your_secure_password_here
DB_HOST=localhost
DB_PORT=5432

# Django settings
DEBUG=False
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1,yourdomain.com
```

### Step 4: Run Migrations

```bash
cd backend
source venv/bin/activate

# Create migrations
python manage.py makemigrations

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser
```

## Performance Tuning

### PostgreSQL Configuration

Add these settings to `postgresql.conf` for better performance:

```conf
# Memory Configuration
shared_buffers = 256MB              # 25% of RAM
effective_cache_size = 768MB       # 75% of RAM
work_mem = 4MB                      # Per query operation
maintenance_work_mem = 64MB         # For VACUUM, CREATE INDEX

# Checkpoint Configuration
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100

# Query Planner
random_page_cost = 1.1               # For SSD
effective_io_concurrency = 200       # For SSD

# Background Writer
bgwriter_delay = 200ms
bgwriter_lru_maxpages = 100
bgwriter_lru_multiplier = 2.0

# Logging (for monitoring)
log_min_duration_statement = 1000    # Log queries > 1s
log_checkpoints = on
log_connections = on
log_disconnections = on
log_duration = on
log_line_prefix = '%t [%p]: '
log_lock_waits = on

# Autovacuum
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 1min
```

### Create Indexes

After running migrations, create additional indexes:

```sql
-- Connect to database
sudo -u postgres psql -d musicplayer

-- Create indexes for better performance
CREATE INDEX idx_song_title ON core_song(title);
CREATE INDEX idx_song_file_hash ON core_song(file_hash);
CREATE INDEX idx_song_created_at ON core_song(created_at);
CREATE INDEX idx_album_title ON core_album(title);
CREATE INDEX idx_album_release_date ON core_album(release_date);
CREATE INDEX idx_artist_name ON core_artist(name);
CREATE INDEX idx_change_request_status ON core_changerequest(status, created_at);
CREATE INDEX idx_change_request_user ON core_changerequest(user_id, created_at);

-- Analyze tables
ANALYZE core_song;
ANALYZE core_album;
ANALYZE core_artist;
ANALYZE core_changerequest;
```

## Backup Strategy

### Manual Backup

```bash
# Create backup directory
mkdir -p ~/backups

# Backup database
sudo -u postgres pg_dump musicplayer > ~/backups/musicplayer_$(date +%Y%m%d_%H%M%S).sql

# Compress backup
gzip ~/backups/musicplayer_*.sql
```

### Automated Backup Script

Create `scripts/backup_postgres.sh`:

```bash
#!/bin/bash

# Configuration
BACKUP_DIR="/path/to/backups"
DB_NAME="musicplayer"
DB_USER="musicplayer"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup database
sudo -u postgres pg_dump "$DB_NAME" | gzip > "$BACKUP_FILE"

# Keep only last 7 days
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete

# Log backup
echo "[$(date)] Backup created: $BACKUP_FILE" >> "$BACKUP_DIR/backup.log"
```

Make it executable:

```bash
chmod +x scripts/backup_postgres.sh
```

### Schedule with Cron

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /path/to/scripts/backup_postgres.sh
```

## Restore Database

```bash
# Decompress backup
gunzip ~/backups/musicplayer_20250115_020000.sql.gz

# Restore database
sudo -u postgres psql musicplayer < ~/backups/musicplayer_20250115_020000.sql
```

## Security Best Practices

### 1. Secure Password

Use a strong, unique password for the database user:

```bash
# Generate strong password
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 2. Limit Connections

In `pg_hba.conf`, only allow connections from necessary hosts:

```conf
# Only allow from application server
host    musicplayer     musicplayer     10.0.0.100/32           md5
```

### 3. Encrypt Connections

Enable SSL/TLS:

```bash
# Generate self-signed certificate (development)
openssl req -new -x509 -days 365 -nodes -text -out server.crt -keyout server.key

# Set permissions
chmod 600 server.key
chown postgres.postgres server.key server.crt

# Move to PostgreSQL data directory
sudo mv server.key server.crt /var/lib/pgsql/data/
```

In `postgresql.conf`:

```conf
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
```

### 4. Firewall Configuration

```bash
# Allow PostgreSQL port (if needed)
sudo ufw allow 5432/tcp

# Or restrict to specific IP
sudo ufw allow from 10.0.0.100 to any port 5432
```

### 5. Regular Updates

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get upgrade postgresql postgresql-contrib

# Fedora/RHEL
sudo dnf upgrade postgresql
```

## Monitoring

### Enable PostgreSQL Stats

In `postgresql.conf`:

```conf
track_activities = on
track_counts = on
track_io_timing = on
track_functions = all
```

### Query Monitoring

```sql
-- View active queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';

-- Kill long-running query
SELECT pg_cancel_backend(pid);
```

### Connection Monitoring

```sql
-- View current connections
SELECT count(*) FROM pg_stat_activity;

-- View connections per database
SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;
```

## Troubleshooting

### Connection Issues

```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Check logs
sudo tail -f /var/log/postgresql/postgresql-14-main.log

# Test connection
sudo -u postgres psql -c "SELECT version();"
```

### Permission Issues

```sql
-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE musicplayer TO musicplayer;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO musicplayer;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO musicplayer;

-- For Django migrations
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO musicplayer;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO musicplayer;
```

### Performance Issues

```sql
-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM core_song WHERE title = 'Test';

-- Check for missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public'
ORDER BY abs(correlation) DESC;
```

## Testing Connection

### Python Test

Create `test_postgres.py`:

```python
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

try:
    conn = psycopg2.connect(
        dbname=os.environ.get('DB_NAME'),
        user=os.environ.get('DB_USER'),
        password=os.environ.get('DB_PASSWORD'),
        host=os.environ.get('DB_HOST'),
        port=os.environ.get('DB_PORT')
    )
    print("✅ Successfully connected to PostgreSQL!")
    
    # Test query
    cur = conn.cursor()
    cur.execute("SELECT version();")
    print(f"PostgreSQL version: {cur.fetchone()[0]}")
    
    cur.close()
    conn.close()
except Exception as e:
    print(f"❌ Connection failed: {e}")
```

### Django Test

```bash
# Test database connection
python manage.py dbshell

# Test migrations
python manage.py showmigrations

# Run tests
pytest core/tests/ -v
```

## Production Checklist

- [ ] PostgreSQL installed and running
- [ ] Database and user created
- [ ] Strong password set
- [ ] Firewall configured
- [ ] SSL/TLS enabled (if needed)
- [ ] Backups scheduled
- [ ] Monitoring enabled
- [ ] Performance tuning applied
- [ ] Connection limits set
- [ ] Regular updates scheduled
- [ ] Environment variables configured
- [ ] Django migrations run
- [ ] Superuser created
- [ ] Test connection successful

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Django PostgreSQL Notes](https://docs.djangoproject.com/en/stable/ref/databases/#postgresql-notes)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/security-labels.html)

## Support

If you encounter issues:

1. Check PostgreSQL logs: `sudo tail -f /var/log/postgresql/*.log`
2. Verify service status: `sudo systemctl status postgresql`
3. Test connection: `sudo -u postgres psql -d musicplayer`
4. Check Django settings: `python manage.py check --deploy`
5. Review firewall rules: `sudo ufw status`

For advanced configurations, refer to the PostgreSQL documentation or consult with a database administrator.