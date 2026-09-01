#!/bin/sh
set -eu

REMOTE="${REMOTE:-openlmisdev}"
BASE_IMAGE="${BASE_IMAGE:-ghcr.io/ghscpsm-cam/openlmis-gtm-stockmanagement:5.3.0-gtm.3}"
TARGET_IMAGE="${TARGET_IMAGE:-ghcr.io/ghscpsm-cam/openlmis-gtm-stockmanagement:5.3.0-gtm.4}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REMOTE_WORK_DIR="/tmp/openlmis-stock-card-$$"
JRXML_PATH="$SCRIPT_DIR/src/main/resources/jasperTemplates/stockCard.jrxml"

cleanup() {
    ssh "$REMOTE" "rm -rf '$REMOTE_WORK_DIR'" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

ssh "$REMOTE" "docker pull '$BASE_IMAGE' >/dev/null && mkdir -p '$REMOTE_WORK_DIR/BOOT-INF/classes/jasperTemplates' && container_id=\$(docker create '$BASE_IMAGE') && docker cp \"\$container_id:/service.jar\" '$REMOTE_WORK_DIR/service.jar' && docker rm \"\$container_id\" >/dev/null"
scp "$JRXML_PATH" "$REMOTE:$REMOTE_WORK_DIR/BOOT-INF/classes/jasperTemplates/stockCard.jrxml"
scp "$SCRIPT_DIR/Dockerfile.stock-card-report" "$REMOTE:$REMOTE_WORK_DIR/Dockerfile"
scp "$SCRIPT_DIR/scripts/replace_zip_entry.py" "$REMOTE:$REMOTE_WORK_DIR/replace_zip_entry.py"

ssh "$REMOTE" "cd '$REMOTE_WORK_DIR' && python3 replace_zip_entry.py service.jar BOOT-INF/classes/jasperTemplates/stockCard.jrxml BOOT-INF/classes/jasperTemplates/stockCard.jrxml && docker build --build-arg BASE_IMAGE='$BASE_IMAGE' -t '$TARGET_IMAGE' . >/dev/null && docker run --rm --entrypoint sh '$TARGET_IMAGE' -lc 'unzip -p /service.jar BOOT-INF/classes/jasperTemplates/stockCard.jrxml | grep -q \"Entrada a Inventario\"' && docker push '$TARGET_IMAGE'"

echo "Published and verified $TARGET_IMAGE"
