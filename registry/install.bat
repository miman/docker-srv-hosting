echo off

echo "installing registry on port 5000"

mkdir -p ~/docker/registry/data

docker run -d \
  -p 5000:5000 \
  --restart=always \
  --name registry \
  -v ~/docker/registry/data:/var/lib/registry \
  registry:2


echo "installing joxit/docker-registry-ui on port 6001"
docker run -d \
  -p 6001:80 \
  --name registry-ui \
  --restart=always \
  -e NGINX_PROXY_PASS_URL=http://192.168.68.118:5000/v2 \
  -e SINGLE_REGISTRY=true \
  -e DELETE_IMAGES=true \
  -e CATALOG_MIN_BRANCHES=1 \
  joxit/docker-registry-ui:latest
