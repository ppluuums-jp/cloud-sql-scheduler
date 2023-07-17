#!/bin/bash

######################################################################
# Script for pipeilnes to start/stop Cloud SQL instances on schedule.
######################################################################

# === Initialize shell environment ===================================
readonly PROJECT_ID="${PROJECT_ID}"
readonly REGION="asia-northeast1"
readonly TIMEZONE='Asia/Tokyo'
readonly INSTANCES="${CLOUD_SQL_INSTANCES}"
readonly START_SCHEDULE='0 9 * * 1-5' # Mon-Fri 09:00 ${TIMEZONE}
readonly STOP_SCHEDULE='0 18 * * 1-5' # Mon-Fri 18:00 ${TIMEZONE}

# === Validate environment variables ==================================
if [[ -z "${PROJECT_ID}" ]]; then
  echo "error: PROJECT_ID is not set."
  exit 1
fi

if [[ -z "${INSTANCES}" ]]; then
  echo "error: CLOUD_SQL_INSTANCES is not set."
  exit 1
fi

# === Validate CLOUD_SQL_INSTANCES ===================================
validate_instances() {
  local instances="$1"
  local regex="^[a-zA-Z0-9_-]+(,[a-zA-Z0-9_-]+)*$"
  if [[ ! "$instances" =~ $regex ]]; then
    echo "error: Invalid CLOUD_SQL_INSTANCES format. Specify instances as comma-separated values."
    exit 1
  fi
}

validate_instances "${INSTANCES}"

# === Deploy/Delete functions, topic, scheduler ========================================
deploy_topics() {
  echo "info: Creating cloud-sql-topic topic..."
  gcloud pubsub topics create "cloud-sql-topic" \
    --project="${PROJECT_ID}" || echo "error: Failed to create cloud-sql-topic topic."
}

deploy_functions() {
  echo "info: Deploying cloud-sql-functions function..."
  gcloud functions deploy "cloud-sql-functions" \
    --project="${PROJECT_ID}" \
    --runtime=go120 \
    --gen2 \
    --trigger-topic="cloud-sql-topic" \
    --region="${REGION}" \
    --entry-point="Fn" \
    --set-env-vars="TIMEZONE=${TIMEZONE}" || echo "error: Failed to deploy cloud-sql-functions function."
}

deploy_scheduler() {
  local action="$1"
  local schedule=""
  if [ "$action" = "start" ]; then
    schedule="${START_SCHEDULE}"
  elif [ "$action" = "stop" ]; then
    schedule="${STOP_SCHEDULE}"
  fi
  echo "info: Creating ${action}-cloud-sql scheduler job..."
  gcloud scheduler jobs create pubsub "${action}-cloud-sql" \
    --project="${PROJECT_ID}" \
    --schedule="${schedule}" \
    --topic="cloud-sql-topic" \
    --time-zone="${TIMEZONE}" \
    --location="${REGION}" \
    --message-body="{
        \"Instance\": \"${INSTANCES}\",
        \"Project\": \"${PROJECT_ID}\",
        \"Action\": \"${action}\"
        }" || echo "error: Failed to create ${action}-cloud-sql scheduler job."
}

delete_topics() {
  echo "info: Deleting cloud-sql-topic topic..."
  gcloud pubsub topics delete "cloud-sql-topic" \
    --project="${PROJECT_ID}" \
    --quiet || echo "error: Failed to delete cloud-sql-topic topic."
}

delete_functions() {
  echo "info: Deleting cloud-sql-functions function..."
  gcloud functions delete "cloud-sql-functions" \
    --project="${PROJECT_ID}" \
    --region="${REGION}" \
    --quiet || echo "error: Failed to delete cloud-sql-functions function."
}

delete_scheduler() {
  local action="$1"
  echo "info: Deleting ${action}-cloud-sql scheduler job..."
  gcloud scheduler jobs delete "${action}-cloud-sql" \
    --project="${PROJECT_ID}" \
    --location="${REGION}" \
    --quiet || echo "error: Failed to delete ${action}-cloud-sql scheduler job."
}

deploy_start() {
  deploy_topics
  deploy_functions
  deploy_scheduler "start"
}

deploy_stop() {
  deploy_topics
  deploy_functions
  deploy_scheduler "stop"
}

deploy() {
  deploy_topics
  deploy_functions
  deploy_scheduler "start"
  deploy_scheduler "stop"
}

delete() {
  delete_topics
  delete_functions
  delete_scheduler "start"
  delete_scheduler "stop"
}

# === Main ===========================================================
case "${1:-}" in
  "deploy:start")
    deploy_start
    ;;
  "deploy:stop")
    deploy_stop
    ;;
  "deploy")
    deploy
    ;;
  "delete")
    delete
    ;;
  *)
    echo "error: Invalid command: ${1:-}"
    exit 1
    ;;
esac
