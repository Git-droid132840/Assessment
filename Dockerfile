# ---- build the React client ----
FROM node:20-bookworm-slim AS client
WORKDIR /app/client
COPY client/package*.json ./
RUN npm ci
COPY client/ ./
RUN npm run build

# ---- API server with the built client ----
FROM node:20-bookworm-slim
ENV NODE_ENV=production PORT=4000 DATA_DIR=/data
WORKDIR /app/server
COPY server/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY server/src ./src
COPY --from=client /app/client/dist /app/client/dist
RUN mkdir -p /data && chown -R node:node /data
USER node
VOLUME /data
EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s CMD node -e "fetch('http://localhost:4000/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "src/index.js"]
