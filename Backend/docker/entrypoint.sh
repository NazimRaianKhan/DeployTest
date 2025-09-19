#!/bin/bash

echo "🚀 Starting AUST Library Laravel Application..."

# Wait for database connection (with timeout)
echo "⏳ Waiting for database connection..."
timeout=60
while ! mysqladmin ping -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" --silent; do
    timeout=$((timeout - 1))
    if [ $timeout -eq 0 ]; then
        echo "❌ Database connection timeout. Continuing anyway..."
        break
    fi
    echo "Database not ready, waiting... ($timeout seconds left)"
    sleep 2
done

# Generate application key if not exists
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:" ]; then
    echo "🔑 Generating application key..."
    php artisan key:generate --no-interaction --force
fi

# Clear all caches first
echo "🧹 Clearing caches..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

# Cache configurations for production
echo "⚡ Caching configurations..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Run database migrations
echo "🗄️ Running database migrations..."
php artisan migrate --force --no-interaction

# Seed database if SEED_DATABASE is true
if [ "$SEED_DATABASE" = "true" ]; then
    echo "🌱 Seeding database..."
    php artisan db:seed --class=PublicationSeeder --force --no-interaction
fi

# Create storage link
echo "🔗 Creating storage link..."
php artisan storage:link --force

# Set final permissions
echo "🔐 Setting permissions..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

echo "✅ Application setup complete!"
echo "🌐 Starting Apache server..."

# Start Apache in foreground
exec apache2-foreground