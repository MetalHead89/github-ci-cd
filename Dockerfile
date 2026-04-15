# =========================
# BASE
# =========================
FROM node:24.14.1-alpine AS base

WORKDIR /app

# включаем corepack (официальный менеджер pnpm/yarn)
RUN corepack enable

# фиксируем pnpm версию
RUN corepack prepare pnpm@10.33.0 --activate

# копируем зависимости
COPY package.json pnpm-lock.yaml* ./

RUN pnpm install


# =========================
# DEV
# =========================
FROM base AS dev

COPY . .

EXPOSE 3000

CMD ["pnpm", "dev"]


# =========================
# BUILD
# =========================
FROM base AS build

COPY . .

RUN pnpm build


# =========================
# PROD
# =========================
FROM node:24.14.1-alpine AS prod

WORKDIR /app

RUN corepack enable
RUN corepack prepare pnpm@10.33.0 --activate

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --prod

COPY --from=build /app/.output ./.output

EXPOSE 3000

CMD ["node", ".output/server/index.mjs"]