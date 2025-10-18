set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

kubernetes_dir := justfile_dir()
talos_dir := kubernetes_dir + '/talos'
secrets_file := talos_dir + '/secrets.yaml'
secret_id := 'cluster-staging'
controller := `talosctl config info --output json | jq -e '.endpoints[0]'`

[private]
default:
  just -l talos

[doc('Generate Talos secrets and update 1Password')]
generate-secrets:
  talosctl gen secrets --force -o '{{ secrets_file }}'
  op item edit --vault Kubernetes {{ secret_id }} "MACHINE_TOKEN[text]=$(cat {{ secrets_file }} | yq .trustdinfo.token)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "MACHINE_CA_CRT[text]=$(cat {{ secrets_file }} | yq .certs.os.crt)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "MACHINE_CA_KEY[text]=$(cat {{ secrets_file }} | yq .certs.os.key)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "CLUSTER_ID[text]=$(cat {{ secrets_file }} | yq .cluster.id)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "CLUSTER_SECRET[text]=$(cat {{ secrets_file }} | yq .cluster.secret)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "CLUSTER_TOKEN[text]=$(cat {{ secrets_file }} | yq .secrets.bootstraptoken)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "CLUSTER_SECRETBOXENCRYPTIONSECRET[text]=$(cat {{ secrets_file }} | yq .secrets.secretboxencryptionsecret)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "CLUSTER_ETCD_CA_CRT[text]=$(cat {{ secrets_file }} | yq .certs.etcd.crt)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "CLUSTER_ETCD_CA_KEY[text]=$(cat {{ secrets_file }} | yq .certs.etcd.key)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "CLUSTER_CA_CRT[text]=$(cat {{ secrets_file }} | yq .certs.k8s.crt)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "CLUSTER_CA_KEY[text]=$(cat {{ secrets_file }} | yq .certs.k8s.key)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "CLUSTER_AGGREGATORCA_CRT[text]=$(cat {{ secrets_file }} | yq .certs.k8saggregator.crt)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "CLUSTER_AGGREGATORCA_KEY[text]=$(cat {{ secrets_file }} | yq .certs.k8saggregator.key)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "CLUSTER_SERVICEACCOUNT_KEY[text]=$(cat {{ secrets_file }} | yq .certs.k8sserviceaccount.key)" > /dev/null
  -rm {{ secrets_file }}

[doc('Generate talosconfig for the cluster')]
generate-talosconfig:
  op read op://Kubernetes/cluster-staging/MACHINE_CA_CRT | base64 -d > ca.crt
  op read op://Kubernetes/cluster-staging/MACHINE_CA_KEY | base64 -d > ca.key
  talosctl gen key --name admin
  talosctl gen csr --key admin.key --ip 127.0.0.1
  talosctl gen crt --ca ca --csr admin.csr --name admin --hours 87600
  op item edit --vault Kubernetes {{ secret_id }} "ADMIN_CRT[text]=$(cat admin.crt | base64 -w 0)" > /dev/null
  op item edit --vault Kubernetes {{ secret_id }} "ADMIN_KEY[text]=$(cat admin.key | base64 -w 0)" > /dev/null
  rm ca.crt ca.key admin.crt admin.csr admin.key
  just template "talos/talosconfig.j2" > talosconfig
  mv talosconfig $TALOSCONFIG
  op item edit --vault Kubernetes {{ secret_id }} "talosconfig[text]=$(cat $TALOSCONFIG)" > /dev/null

[doc('Bootstrap the cluster for Kubernetes')]
bootstrap:
  until op=$(talosctl -n "{{ controller }}" bootstrap 2>&1 || true) && [[ "$op" == *"AlreadyExists"* ]]; do \
    just log info "Kubernetes bootstrap in progress. Retrying in 5 seconds..." "stage" "$0"; \
    sleep 5; \
  done

[doc('Fetch kubeconfig')]
fetch-kubeconfig lb="cilium":
  -rm $KUBECONFIG
  if ! talosctl kubeconfig -n "{{ controller }}" -f --force-context-name staging $KUBECONFIG; then \
    just log fatal "Failed to fetch kubeconfig"; \
  fi
  -kubectl config rename-context admin@staging staging
  if [[ "{{ lb }}" != "cilium" ]]; then \
    if ! kubectl config set-cluster staging --server "https://{{ controller }}:6443"; then \
      just log fatal "Failed to set kubectl cluster server address"; \
    fi; \
  fi
  op item edit --vault Kubernetes {{ secret_id }} "kubeconfig[text]=$(cat $KUBECONFIG)" > /dev/null

[doc('Apply Talos config to a node')]
apply-node node *args:
  just talos render-config "{{ node }}" | talosctl -n "{{ node }}" apply-config -f /dev/stdin {{ args }}

[doc('Apply Talos config to all nodes in the cluster')]
apply-cluster *args:
  kubectl get nodes --no-headers | while read -r node _; do \
    just log info "Applying Talos config to node ${node}"; \
    just talos apply-node ${node} {{ args }}; \
  done

[doc('Generate schematic ID from Talos schematic')]
gen-schematic-id:
  curl -sX POST --data-binary "@{{ talos_dir }}/schematic.yaml" "https://factory.talos.dev/schematics" | jq -r '.id'

[doc('Render Talos config for a node')]
render-config node:
  export IS_CONTROLPLANE="$(just talos machine-controller {{ node }})"; \
  talosctl machineconfig patch <(just template "{{ talos_dir }}/machineconfig.yaml.j2") \
    -p @<(just template "{{ talos_dir }}/nodes/{{ node }}.yaml.j2")

[doc('Reboot a node')]
reboot-node node:
  gum confirm "Reboot node {{ node }}?" && \
    talosctl -n {{ node }} reboot -m powercycle || exit 0

[doc('Reset a node')]
reset-node node mode="reboot":
  gum confirm "Reset node {{ node }}?" && \
    talosctl -n "{{ node }}" reset --graceful=false {{ if mode == "reboot" { "--reboot" } else { "" } }} || exit 0

[doc('Reset all nodes in the cluster')]
reset-cluster mode="reboot":
  kubectl get nodes --no-headers | while read -r node _; do \
    just log info "Resetting Talos node ${node}";\
    just talos reset-node ${node} {{ mode }};\
  done

[doc('Upgrade Kubernetes version on the cluster')]
upgrade-k8s version:
  talosctl -n "{{ controller }}" upgrade-k8s --to {{ version }}

[doc('Upgrade Talos version on a node')]
upgrade-node node:
  talosctl -n "{{ node }}" upgrade -i "$(just talos machine-image {{ node }})" -m powercycle --timeout=10m

[doc('Download Talos machine image')]
download-image version schematic:
  gum spin --title "Downloading Talos {{ version }} ..." -- \
  curl -sfL --remove-on-error --retry 5 --retry-delay 5 --retry-all-errors \
      -o "{{ talos_dir }}/talos-{{ version }}-{{ replace_regex(schematic, '^(.{8}).*', '$1') }}.iso" \
      "https://factory.talos.dev/image/{{ schematic }}/{{ version }}/metal-amd64.iso"
  just log info "Downloaded Talos" version "{{ version }}" schematic "{{ schematic }}"

[private]
machine-controller node:
  just template "{{ talos_dir }}/nodes/{{ node }}.yaml.j2" | yq -e 'select(.machine) | (.machine.type == "controlplane") // ""'

[doc('Get the machine image for a given node')]
[private]
machine-image node:
  talosctl --nodes {{ node }} get machineconfig --output=jsonpath='{.spec}' | yq -e 'select(.machine) | .machine.install.image'
