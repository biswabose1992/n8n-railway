#!/bin/sh
# We'll manage exit explicitly for tar, so `set -e` can be tricky here.
# If you re-enable `set -e`, be very careful about commands that might non-fatally error.

N8N_DATA_DIR="/home/node/.n8n"
# This path is where the Dockerfile's ADD command places the backup.
# Docker copies image content to a new volume on its first creation.
BACKUP_FILE_PATH="${N8N_DATA_DIR}/n8n_backup.tar.gz"
DATABASE_FILE_PATH="${N8N_DATA_DIR}/database.sqlite"
# Use a unique flag name to ensure this new logic runs if old flags exist
RESTORE_DONE_FLAG="${N8N_DATA_DIR}/.railway_restore_v3_done"

echo "INFO: --- n8n Entrypoint Script Start ---"
echo "INFO: Data Directory: ${N8N_DATA_DIR}"
echo "INFO: Backup File: ${BACKUP_FILE_PATH}"
echo "INFO: Restore Flag: ${RESTORE_DONE_FLAG}"

# Download backup from URL if N8N_BACKUP_URL is set
if [ -n "$N8N_BACKUP_URL" ]; then
  echo "INFO: Attempting to download backup from $N8N_BACKUP_URL to ${BACKUP_FILE_PATH}"
  if curl -L -o "${BACKUP_FILE_PATH}" "$N8N_BACKUP_URL"; then
    echo "INFO: Successfully downloaded backup."
  else
    echo "ERROR: Failed to download backup from $N8N_BACKUP_URL."
  fi
fi

if [ ! -f "${RESTORE_DONE_FLAG}" ]; then
  echo "INFO: Restore flag '${RESTORE_DONE_FLAG}' not found."
  if [ -f "${BACKUP_FILE_PATH}" ]; then
    echo "INFO: Backup file '${BACKUP_FILE_PATH}' found. Attempting restoration..."
    # Ensure the target directory exists (it should be the volume mount point)
    mkdir -p "${N8N_DATA_DIR}"

    echo "INFO: Extracting '${BACKUP_FILE_PATH}' into '${N8N_DATA_DIR}' using --strip-components=1..."
    tar_output_and_errors=$(tar -xzvf "${BACKUP_FILE_PATH}" -C "${N8N_DATA_DIR}" --strip-components=1 2>&1)
    tar_exit_code=$?

    echo "INFO: tar command finished with exit code: ${tar_exit_code}"
    if [ -n "${tar_output_and_errors}" ]; then
        echo "INFO: tar output/errors:"
        echo "${tar_output_and_errors}"
    fi

    # Check if tar succeeded or had non-fatal errors (like utime on '.')
    if [ ${tar_exit_code} -eq 0 ] || [ ${tar_exit_code} -eq 1 ]; then
      if [ ${tar_exit_code} -eq 1 ]; then
        echo "WARNING: tar exited with code 1, often due to non-fatal errors like 'utime'. Proceeding with checks."
      else
        echo "INFO: tar extraction reported success."
      fi

      # Verify key file (database) exists after extraction attempt
      if [ -f "${DATABASE_FILE_PATH}" ]; then
        echo "INFO: Database file '${DATABASE_FILE_PATH}' found post-extraction."
        echo "INFO: Applying recursive read/write permissions for the current user (node) to '${N8N_DATA_DIR}'..."
        chmod -R u+rwX "${N8N_DATA_DIR}"
        chmod_exit_code=$?
        if [ ${chmod_exit_code} -ne 0 ]; then
            echo "ERROR: Failed to set permissions on '${N8N_DATA_DIR}'. chmod exit code: ${chmod_exit_code}. n8n might fail."
            exit 1 # This is critical
        fi
        echo "INFO: Permissions updated successfully."

        echo "INFO: Backup restoration process deemed complete. Creating flag: ${RESTORE_DONE_FLAG}"
        touch "${RESTORE_DONE_FLAG}"

        # Optional: Remove the backup file
        # echo "INFO: Removing backup file '${BACKUP_FILE_PATH}'."
        # rm "${BACKUP_FILE_PATH}"
      else
        echo "ERROR: CRITICAL - Database file '${DATABASE_FILE_PATH}' NOT found after extraction. Backup may have failed or archive is problematic."
        echo "ERROR: n8n will likely not start correctly with existing data. Halting."
        exit 1 # Fail fast
      fi
    else
      echo "ERROR: CRITICAL - tar extraction failed with unrecoverable exit code: ${tar_exit_code}."
      echo "ERROR: Please check tar output above. Halting."
      exit 1 # Fail fast
    fi
  else
    echo "INFO: Backup file '${BACKUP_FILE_PATH}' not found. Skipping restoration."
    echo "INFO: Assuming fresh start or data already present. Creating flag: ${RESTORE_DONE_FLAG}"
    mkdir -p "${N8N_DATA_DIR}" # Ensure dir exists for flag
    touch "${RESTORE_DONE_FLAG}"
  fi
else
  echo "INFO: Restore flag '${RESTORE_DONE_FLAG}' found. Skipping backup restoration."
fi

echo "INFO: --- n8n Entrypoint Script End ---"
echo "INFO: Starting n8n..."
exec n8n