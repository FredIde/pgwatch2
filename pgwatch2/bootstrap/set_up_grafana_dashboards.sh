#! /bin/bash

# Used with the default Docker image to load Grafana datasource (local Influxdb) and default Dashboard

export PGUSER=postgres

while true ; do

  # It will take some time for Postgres to start and Grafana to do schema initialization
  sleep 3

  DB_OK=$(psql -qAt -c "select count(1) from dashboard" pgwatch2_grafana)

  if [[ -z DB_OK ]] ; then
    continue
  elif [[ $DB_OK -gt 0 ]] ; then
    exit 0
  elif [[ $DB_OK == 0 ]] ; then
    break
  fi

done

psql -h /var/run/postgresql -f /pgwatch2/bootstrap/grafana_datasource.sql pgwatch2_grafana

for slug in $(ls --hide='*.md' /pgwatch2/grafana_dashboards) ; do

echo "inserting dashboard: $slug"
TITLE=$(cat /pgwatch2/grafana_dashboards/${slug}/title.txt)
JSON=$(cat /pgwatch2/grafana_dashboards/${slug}/dashboard.json)
SQL='insert into dashboard (version, org_id, created, updated, updated_by, created_by, gnet_id, slug, title, data) values (0, 1, now(), now(), 1, 1, 0'
for d in "$slug" "$TITLE" "$JSON" ; do
  SQL+=",'${d}'"
done
SQL+=")"

echo "$SQL" | psql -h /var/run/postgresql pgwatch2_grafana

done

exit 0
