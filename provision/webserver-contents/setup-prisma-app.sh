#!/bin/bash

# Configuration
APP_ROOT="/home/vagrant/prisma-app"   # Project root directory
SRC_DIR="$APP_ROOT/src"               # Source directory
MYSQL_HOST="192.168.4.50"             # MySQL server IP
MYSQL_USER="root"                     # MySQL root user
MYSQL_PASS="root"                     # MySQL root password
MYSQL_DB="testdb"                     # Database name

echo "[+] Setting up Prisma app at $APP_ROOT..."

# Create project directories
mkdir -p "$SRC_DIR"
cd "$APP_ROOT"

# Initialize npm project if package.json does not exist
if [ ! -f package.json ]; then
  npm init -y
fi

# Install dependencies (not dev dependencies)
npm install prisma @prisma/client typescript ts-node express @types/express

# Making sure that tsfconfig is available
if [ ! -f tsconfig.json ]; then
  npx tsc --init
fi

# Initialize Prisma (creates prisma/schema.prisma if not exists)
if [ ! -d "prisma" ]; then
  npx prisma init
fi

# Write .env at project root (prisma reads env from here)
cat > "$APP_ROOT/.env" <<EOF
DATABASE_URL="mysql://$MYSQL_USER:$MYSQL_PASS@$MYSQL_HOST:3306/$MYSQL_DB"
EOF

# Overwrite prisma/schema.prisma with your schema
cat > "$APP_ROOT/prisma/schema.prisma" <<EOF
datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id        Int      @id @default(autoincrement())
  createdAt DateTime @default(now())
  email     String   @unique
  name      String?
}
EOF

# Create Express server source code
cat > "$SRC_DIR/index.ts" <<EOF
import express, { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const app = express();
const prisma = new PrismaClient();

app.get('/', async (req: Request, res: Response) => {
  try {
    const users = await prisma.user.findMany();
    res.json(users);
  } catch (error) {
    console.error(error);
    res.status(500).send('Internal Server Error');
  }
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Server is running at http://192.168.4.30:3000');
});
EOF

# Generate Prisma client
npx prisma generate

# Apply migrations (creates migration files and updates DB)
npx prisma migrate dev --name init --preview-feature

echo "###################################"
echo "~* Prisma app has been installed *~"
echo "###################################"