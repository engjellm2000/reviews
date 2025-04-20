FROM node:22-alpine AS builder

WORKDIR /app
COPY package*.json ./
COPY tsconfig.json ./
COPY .npmrc ./
COPY src ./src
RUN npm install -g --force npm@latest
RUN npm ci && npm run build

FROM node:22-alpine

WORKDIR /app
RUN apk add --no-cache curl
COPY package*.json ./
COPY tsconfig.json ./
COPY .npmrc ./
RUN npm install -g pm2 --force npm@latest
RUN npm ci --production
COPY --from=builder /app/build ./build

EXPOSE 4007

CMD [ "npm", "run", "start" ]
