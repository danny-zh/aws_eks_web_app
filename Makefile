.PHONY: run_website stop_website get_kind create_kind_cluster delete_kind_cluster

# Variables
docker_image_name = explorecalifornia
docker_container_name = explorecalifornia
kind_url = 'https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64'
cluster_name = explorecalifornia

#Rules
run_website:
	docker build -t $(docker_image_name) -f Dockerfile . && \
	docker run --name $(docker_container_name) -dp 5000:80 $(docker_image_name) 

stop_website:
	docker stop $(docker_container_name) && docker rm $(docker_container_name) || true 

get_kind:
	[ $(shell uname -m) = x86_64 ] && curl -Lo ./kind $(kind_url)

create_kind_cluster:
	kind create cluster --name $(cluster_name)

delete_kind_cluster:
	kind delete cluster --name $(cluster_name)