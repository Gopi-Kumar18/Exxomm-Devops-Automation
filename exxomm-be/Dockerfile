# ---- Base Stage ----
# Use a specific Node.js version
FROM node:18-alpine AS base
WORKDIR /usr/src/app

# ---- Dependencies Stage ----
# Install dependencies first to leverage Docker cache
FROM base AS dependencies
COPY package.json package-lock.json* ./
RUN npm install --production

# ---- Production Stage ----
# Copy dependencies and only your application code
FROM base AS production
COPY --from=dependencies /usr/src/app/node_modules ./node_modules
COPY ./backend ./backend

# Expose the port your app *actually* listens on
# Your Dockerfile said 3000, so I'll use that.
EXPOSE 3000

# The CMD is fixed to point to the correct path
CMD [ "node", "backend/server.js" ]