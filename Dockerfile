FROM n8nio/n8n

# Copy your workflows directory into the container
COPY workflows /home/node/.n8n/workflows

# Set the user to the non-root n8n user
USER node