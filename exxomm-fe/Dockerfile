# Build phase (This part was correct)
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Serve with nginx
FROM nginx:alpine

# Copy built files from previous stage
COPY --from=build /app/dist /usr/share/nginx/html

# --- THIS IS THE FIX ---
# Remove the default Nginx config
RUN rm /etc/nginx/conf.d/default.conf
# Copy your new config file
COPY nginx.conf /etc/nginx/conf.d/
# --- END OF FIX ---

# --- THIS IS THE FIX ---
# Expose the default Nginx port
EXPOSE 80

# Start nginx (This part was correct)
CMD ["nginx", "-g", "daemon off;"]