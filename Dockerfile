FROM node:20-alpine AS build

WORKDIR /app

COPY package.json package-lock.json ./
COPY server/package.json server/package-lock.json ./server/
COPY widgets/package.json widgets/package-lock.json ./widgets/

RUN npm ci \
  && cd server && npm ci \
  && cd ../widgets && npm ci

COPY . .

RUN npm run build:widgets \
  && cd server && npm run build

FROM node:20-alpine AS runtime

WORKDIR /app

COPY --from=build /app/server/package.json /app/server/package.json
COPY --from=build /app/server/package-lock.json /app/server/package-lock.json
COPY --from=build /app/server/node_modules /app/server/node_modules
COPY --from=build /app/server/dist /app/server/dist
COPY --from=build /app/assets /app/assets
COPY --from=build /app/db /app/db

ENV NODE_ENV=production
ENV PORT=3001

EXPOSE 3001

WORKDIR /app/server
CMD ["node", "dist/index.js"]