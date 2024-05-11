FROM oven/bun:1.1.8

COPY index.ts .
COPY package.json .
COPY bun.lockb .

RUN bun install

CMD ["bun", "run", "index.ts"]
