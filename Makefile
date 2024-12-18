.PHONY: run_website stop_website install_kind create_kind_cluster \
delete_kind_cluster create_docker_registry \
connect_kind_network_with_local_registry connect_registry_to_kind \
create_kind_cluster_with_registry delete_kind_cluster_with_registry \
push_image_to_registry start_deployment

# Variables
docker_image_name = explorecalifornia
docker_container_name = explorecalifornia
kind_url = 'https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64'
cluster_name = explorecalifornia
registry_name = local-registry
kind_config = './kind_config.yml'
kind_configmap = './kind_configmap.yml'
server_name = localhost:5000

#Rules
run_website:
	docker build -t $(docker_image_name) -f Dockerfile . && \
	docker run --name $(docker_container_name) -dp 5000:80 $(docker_image_name)

stop_website:
	docker stop $(docker_container_name) && docker rm $(docker_container_name) || true

install_kind:
	[ $(shell uname -m) = x86_64 ] && curl -Lo ./kind $(kind_url)

create_kind_cluster: install_kind create_docker_registry
	kind create cluster --config $(kind_config) --name $(cluster_name) || true && \
	kubectl get nodes

delete_kind_cluster:
	kind delete cluster --name $(cluster_name)

create_docker_registry:
	if docker ps | grep -q $(registry_name) ;\
	then echo "Already running $(registry_name)"; \
	else docker run --name $(registry_name) --restart=always -dp 5000:5000 registry:2; \
	fi

delete_docker_registry:
	if docker ps | grep -q $(registry_name) ;\
	then docker rm -f $(registry_name); \
	fi

connect_kind_network_with_local_registry:
	docker network connect kind $(registry_name) || true

connect_registry_to_kind: connect_kind_network_with_local_registry
	kubectl apply -f $(kind_configmap)

create_kind_cluster_with_registry:
	$(MAKE) create_kind_cluster && $(MAKE) connect_registry_to_kind && $(MAKE) push_image_to_registry

delete_kind_cluster_with_registry:
	$(MAKE) delete_kind_cluster && $(MAKE) delete_docker_registry

push_image_to_registry: 
	docker push $(server_name)/$(docker_image_name)

start_deployment:
	kubectl apply -f deployment.yml && \
	kubectl apply -f service.yml && \
	kubectl apply -f ingress.yml && \
	kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
