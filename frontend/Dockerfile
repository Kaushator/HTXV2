FROM node:20-slim

WORKDIR /app

COPY package*.json /app/
RUN npm ci

COPY . /app

EXPOSE 3000
CMD ["npm","run","dev"]

