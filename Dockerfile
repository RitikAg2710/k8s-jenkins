# Stage 1 — Builder
FROM node:20 as builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Stage 2 — Final
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app .
EXPOSE 5000
CMD ["npm", "start"]


# ------------------------------------------
# Step 1: COPY package*.json ./
# ------------------------------------------
# ⬇
# Agar tumne package.json ya package-lock.json
# me kuch change kiya, to ye step re-run hoga.
# Nahi to ye cache se milega.

# ------------------------------------------
# Step 2: RUN npm ci --only=production
# ------------------------------------------
# ⬇
# Ye step tabhi re-run hoga jab Step 1 me 
# dependency files change hui hongi.
# Nahi to cache ka npm install reuse hoga.

# ------------------------------------------
# Step 3: COPY . .
# ------------------------------------------
# ⬇
# Ye step har code change pe re-run hoga,
# lekin dependencies wapas install nahi hongi
# kyunki Step 2 cache ho chuka hai.
