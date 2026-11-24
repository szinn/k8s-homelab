#!/usr/bin/env bash
# Dump each database in POSTGRES_DB, keeping last/daily/weekly/monthly copies.
# File layout matches prodrigestivill/postgres-backup-local.
set -euo pipefail

export PGHOST="${POSTGRES_HOST}" PGUSER="${POSTGRES_USER}" PGPASSWORD="${POSTGRES_PASSWORD}"

root="${BACKUP_DIR:-/backups}"
mkdir -p "${root}"/{last,daily,weekly,monthly}

stamp="$(date +%Y%m%d-%H%M%S)"
day="$(date +%Y%m%d)"
week="$(date +%G%V)"
month="$(date +%Y%m)"

tmp=""
trap '[[ -z "${tmp}" ]] || rm -f "${tmp}"' EXIT

backup() {
  local db="$1" last="${root}/last/$1-${stamp}.sql.gz" period key target
  tmp="${root}/last/.${db}-${stamp}.partial"

  echo "Dumping ${db} from ${PGHOST}"
  # shellcheck disable=SC2086
  pg_dump --dbname="${db}" --file="${tmp}" ${POSTGRES_EXTRA_OPTS:-} || return 1
  gzip -t "${tmp}" || return 1
  mv "${tmp}" "${last}" || return 1
  tmp=""
  ln -sfn "${last##*/}" "${root}/last/${db}-latest.sql.gz" || return 1

  for period in daily:"${day}" weekly:"${week}" monthly:"${month}"; do
    key="${period#*:}"
    period="${period%%:*}"
    target="${root}/${period}/${db}-${key}.sql.gz"
    ln -f "${last}" "${target}" || return 1
    ln -sfn "${target##*/}" "${root}/${period}/${db}-latest.sql.gz" || return 1
  done

  # Only prune once this database has a good dump
  prune "${db}" last -mmin "+${BACKUP_KEEP_MINS}" || return 1
  prune "${db}" daily -mtime "+${BACKUP_KEEP_DAYS}" || return 1
  prune "${db}" weekly -mtime "+$((BACKUP_KEEP_WEEKS * 7 + 1))" || return 1
  prune "${db}" monthly -mtime "+$((BACKUP_KEEP_MONTHS * 31 + 1))" || return 1
}

prune() {
  local db="$1" period="$2"
  shift 2
  find "${root}/${period}" -maxdepth 1 -type f -name "${db}-[0-9]*.sql.gz" "$@" -print -delete
}

failed=()
for db in ${POSTGRES_DB}; do
  if ! backup "${db}"; then
    failed+=("${db}")
    [[ -z "${tmp}" ]] || rm -f "${tmp}"
    tmp=""
  fi
done

if ((${#failed[@]})); then
  echo "Backup failed for: ${failed[*]}" >&2
  exit 1
fi
echo "Backups completed"
