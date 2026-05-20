FROM php:8.4-cli

# System deps
RUN apt-get update && apt-get install -y \
    git curl zip unzip libpq-dev libzip-dev libicu-dev libonig-dev \
    libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install pdo pdo_pgsql pgsql zip intl mbstring gd bcmath pcntl sockets \
    && pecl install swoole redis \
    && docker-php-ext-enable swoole redis \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
