FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run codegen
RUN npm run build

FROM node:20-alpine AS runner

WORKDIR /app
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/build ./build
COPY --from=builder /app/subgraph.yaml ./subgraph.yaml

EXPOSE 8000

CMD ["npx", "graph", "deploy", "--node", "http://host.docker.internal:8020", "covenant-protocol/covenants"]
