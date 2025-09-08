FROM node:20-slim
WORKDIR /srv
COPY package.json tsconfig.json .env.example /srv/
RUN npm i
COPY src /srv/src
RUN npm run build
CMD ["node","dist/index.js"]
