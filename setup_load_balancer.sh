
#!/bin/bash

# Update package list
echo "Updating package list..."
sudo apt update -y

# Install Nginx
echo "Installing Nginx..."
sudo apt install nginx -y

# Start and enable Nginx
echo "Starting Nginx service..."
sudo systemctl start nginx
sudo systemctl enable nginx

# Create Dockerfiles for Containers A and B
echo "Creating Dockerfiles and index.html files..."
cat <<EOL > Dockerfile
FROM nginx:1.23.3
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOL

cat <<EOL > Dockerfile.b
FROM nginx:1.23.3
COPY index_b.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOL

# Create custom index.html files
echo "Creating custom index.html files..."
cat <<EOL > index.html
Welcome to My Custom Nginx Page!
EOL

cat <<EOL > index_b.html
Welcome to My Custom Nginx Page B!
EOL

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat <<EOL > docker-compose.yml
version: '3.8'

services:
  nginx_a:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:80"
    volumes:
      - ./index.html:/usr/share/nginx/html/index.html

  nginx_b:
    build:
      context: .
      dockerfile: Dockerfile.b
    ports:
      - "9090:80"
    volumes:
      - ./index_b.html:/usr/share/nginx/html/index.html
EOL

# Start the Docker containers
echo "Starting Docker containers..."
docker-compose up --build -d

# Configure Nginx as a Load Balancer
echo "Configuring Nginx as a Load Balancer..."
cat <<EOL > /etc/nginx/sites-available/load_balancer
upstream my_app {
    server localhost:8080;  # Container A
    server localhost:9090;  # Container B
}

server {
    listen 80;

    location / {
        proxy_pass http://my_app;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Link the configuration and restart Nginx
sudo ln -s /etc/nginx/sites-available/load_balancer /etc/nginx/sites-enabled/
sudo nginx -t  # Test Nginx configuration
sudo systemctl restart nginx  # Restart Nginx

echo "Setup completed! Access your load balancer at http://localhost"
