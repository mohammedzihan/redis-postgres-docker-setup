# ,ulti stage build
FROM node:18-alpine AS build_stage

# required for ssh and git clone inside npm. dumb-init for process management.
RUN apk add --update --no-cache openssh git dumb-init

RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan git.bitbucket.org >> ~/.ssh/known_hosts

RUN mkdir -p /app

WORKDIR /app

COPY package.json package.json

# npm install the dependencies (from npm and git)
RUN --mount=type=ssh npm clean-install



FROM node:18-alpine

# Set the timezone
RUN apk add --no-cache tzdata
ENV TZ=Asia/Kolkata

RUN apk add --update --no-cache chromium
# Copy dumb-init from build stage
COPY --from=build_stage /usr/bin/dumb-init /usr/bin/dumb-init

RUN mkdir -p /app

RUN chown node:node /app

# Use the built in 'node' user with lesser previliges.
USER node

WORKDIR /app

# Copy the /app from build stage
COPY --chown=node:node --from=build_stage /app /app

COPY --chown=node:node . .

EXPOSE 8000

CMD ["dumb-init", "node", "index.js"]