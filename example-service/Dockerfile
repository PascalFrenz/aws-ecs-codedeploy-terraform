FROM oven/bun as builder

WORKDIR /app

COPY package.json .
COPY bun.lockb .

RUN bun install

FROM oven/bun:1.1.8-alpine

COPY --from=builder /app/node_modules /app/node_modules
COPY index.ts /app/index.ts

RUN apk add --no-cache curl

HEALTHCHECK --interval=5s --timeout=3s CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
CMD ["bun", "run", "/app/index.ts"]
