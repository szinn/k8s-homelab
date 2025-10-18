set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

kubernetes_dir := justfile_dir()
bootstrap_dir := kubernetes_dir + '/bootstrap'

[private]
default: talos-secrets talos kubernetes (kubeconfig "node") wait namespaces resources crds apps kubeconfig

[doc('Rebuild Talos secrets')]
talos-secrets:
  just log info "Generating Talos secrets..."
  just talos generate-secrets
  just talos generate-talosconfig

[doc('Install Talos')]
talos:
  just log info "Installing Talos on all nodes..."
  for n in $(ls {{ kubernetes_dir }}/talos/nodes | sed -e 's/.yaml.j2//'); do \
    if ! op=$(just talos apply-node "$n" --insecure 2>&1); then \
      if [[ "$op" == *"certificate required"* ]]; then \
        just log info "Talos already configured, skipping apply of config" "node" "$n"; \
        continue; \
      fi; \
      just log fatal "Failed to apply Talos configuration" "node" "$n" "output" "$op"; \
    fi; \
  done
  just proxmox unmount-cdrom

[doc('Install Kubernetes')]
kubernetes:
  just log info "Bootstrapping Talos Kubernetes..."
  just talos bootstrap

[doc('Fetch kubeconfig')]
kubeconfig lb="cilium":
  just log info "Fetching kubeconfig..."
  just talos fetch-kubeconfig {{ lb }}

[doc('Wait for nodes to be not-ready')]
wait:
  just log info "Waiting for all nodes to be not-ready..."
  if ! kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then \
    until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do \
      just log info "Nodes not available, waiting for nodes to be available. Retrying in 5 seconds..."; \
      sleep 5; \
    done \
  fi

[doc('Apply Kubernetes namespaces')]
namespaces:
  just log info "Creating namespaces..."
  find "{{ kubernetes_dir }}/apps" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | while IFS= read -r ns; do \
    if ! kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply --server-side -f -; then \
      just log fatal "Failed to apply namespace" "namespace" "$ns"; \
    fi; \
  done

[doc('Apply Kubernetes resources')]
resources:
  just log info "Applying resources..."
  if ! just template "{{ bootstrap_dir }}/resources.yaml.j2" | kubectl apply --server-side -f -; then \
    just log fatal "Failed to apply resources"; \
  fi;

[doc('Apply Helmfile CRDs')]
crds:
  just log info "Installing CRDs..."
  if ! helmfile -f "{{ bootstrap_dir }}/helmfile.d/00-crds.yaml" template -q | kubectl apply --server-side -f -; then \
    just log fatal "Failed to apply crds"; \
  fi;

[doc('Apply Helmfile Apps')]
apps:
  just log info "Installing applications..."
  if ! helmfile -f "{{ bootstrap_dir }}/helmfile.d/01-apps.yaml" sync --hide-notes; then \
    just log fatal "Failed to sync helmfile"; \
  fi
