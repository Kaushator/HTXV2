#!/usr/bin/env node

// Автозагрузка .env файла
import dotenv from 'dotenv';
dotenv.config();

// Импорт основного модуля
import './dist/index.js';
