set lazy
set default-list
set default-script
set positional-arguments
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
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
  until op=$(talosctl -n "{{ controller }}" bootstrap 2>&1 || true) && [[ "$op" == *"AlreadyExists"* ]]; do
    just log info "Kubernetes bootstrap in progress. Retrying in 5 seconds..." "stage" "$0"
    sleep 5
  done

[doc('Fetch kubeconfig')]
fetch-kubeconfig lb="cilium":
  if test -e $KUBECONFIG; then
    rm $KUBECONFIG
  fi
  if ! talosctl kubeconfig -n "{{ controller }}" -f --force-context-name staging $KUBECONFIG; then
    just log fatal "Failed to fetch kubeconfig"
  fi
  kubectl config rename-context admin@staging staging
  if [[ "{{ lb }}" != "cilium" ]]; then
    if ! kubectl config set-cluster staging --server "https://{{ controller }}:6443"; then
      just log fatal "Failed to set kubectl cluster server address"
    fi
  fi
  op item edit --vault Kubernetes {{ secret_id }} "kubeconfig[text]=$(cat $KUBECONFIG)" > /dev/null

[doc('Apply Talos config to a node')]
apply-node node *args:
  just talos render-config "{{ node }}" | talosctl -n "{{ node }}" apply-config -f /dev/stdin {{ args }}

[doc('Apply Talos config to all nodes in the cluster')]
apply-cluster *args:
  kubectl get nodes --no-headers | while read -r node _; do
    just log info "Applying Talos config to node ${node}"
    just talos apply-node ${node} {{ args }}
  done

[doc('Download Talos machine image')]
download-image version schematic:
  export SCHEMATIC="$(just talos schematic-id "{{ node }}")"
  curl -fL --remove-on-error --retry 5 --retry-delay 5 --retry-all-errors --progress-bar \
      -o "{{ talos_dir }}/talos-{{ version }}-${SCHEMATIC:0:8}.iso" \
      "https://factory.talos.dev/image/${SCHEMATIC}/{{ version }}/metal-amd64.iso"
  just log info "Downloaded Talos" version "{{ version }}" schematic "${SCHEMATIC}"

[confirm('Reboot node ' + node + ' [y|N] ?')]
[doc('Reboot a node')]
reboot-node node:
  talosctl -n {{ node }} reboot -m powercycle

[doc('Render Talos config for a node')]
render-config node:
    schematic="$(just talos schematic-id "{{ node }}")"
    role="controlplane"
    if "$(just talos machine-controller {{ node }})"; then
        role="worker"
    fi
    talosctl machineconfig patch <(just template "{{ talos_dir }}/cluster.yaml.j2" -D "schematic=${schematic}") \
        -p @<(just template "{{ talos_dir }}/${role}.yaml.j2")

[confirm('Reset node ' + node + ' [y|N] ?')]
[doc('Reset a node')]
reset-node node *args:
    talosctl -n "{{ node }}" reset --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL --system-labels-to-wipe u-local-hostpath --graceful=false {{ args }}

[confirm('Reset nodes [y|N] ?')]
[doc('Reset all nodes in the cluster')]
reset-cluster mode="reboot":
  kubectl get nodes --no-headers | while read -r node _; do
    just log info "Resetting Talos node ${node}"
    just talos reset-node ${node} {{ mode }}
  done

[confirm('Shutdown node ' + node + ' [y|N] ?')]
[doc('Shutdown a node')]
shutdown-node node *args:
    talosctl -n "{{ node }}" shutdown --force {{ args }}

[confirm('Upgrade Kubernetes to ' + version + ' [y|N] ?')]
[doc('Upgrade Kubernetes version on the cluster')]
upgrade-k8s version:
    talosctl -n "$(talosctl config info -o yaml | yq -r -e '.endpoints[0]')" upgrade-k8s --to {{ version }}

[confirm('Upgrade node ' + node + ' [y|N] ?')]
[doc('Upgrade Talos version on a node')]
upgrade-node node *args:
    talosctl -n "{{ node }}" upgrade -i "$(just talos machine-image "{{ node }}")" -m powercycle --timeout=10m {{ args }}

[private]
schematic-file node="":
    file="{{ talos_dir }}/schematic.yaml.j2"
    if [[ -n "{{ node }}" ]]; then
        for f in "{{ talos_dir }}"/nodes/*/"{{ node }}".schematic.yaml.j2; do
            [[ -f "$f" ]] && file="$f"
        done
    fi
    echo "$file"

[private]
schematic-id node="":
    curl -sX POST --data-binary @<(just template "$(just talos schematic-file "{{ node }}")") "https://factory.talos.dev/schematics" | jq -r '.id'

[private]
machine-controller node:
  just template "{{ talos_dir }}/nodes/{{ node }}.yaml.j2" | yq -e 'select(.machine) | (.machine.type == "controlplane") // ""'

[private]
machine-image node="":
    just template "{{ talos_dir }}/cluster.yaml.j2" -D "schematic=$(just talos schematic-id "{{ node }}")" | yq -r -e 'select(.kind == "UnattendedInstallConfig") | .installer.image'
