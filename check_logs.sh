echo "Checking daoob_api container logs..."
docker logs daoob_api

echo -e "\n\nChecking if the application files exist in the container..."
docker exec daoob_api ls -la /app/

echo -e "\n\nChecking if dist directory exists..."
docker exec daoob_api ls -la /app/dist/

echo -e "\n\nChecking Node.js and application entry point..."
docker exec daoob_api node --version
docker exec daoob_api ls -la /app/dist/index.js
