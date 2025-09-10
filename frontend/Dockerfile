FROM node:20-slim

WORKDIR /app

COPY package*.json /app/
RUN npm install

COPY . /app
# Выполняем только сборку Next.js без линтинга и проверки типов
RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]

