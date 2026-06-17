#!/bin/sh
set -e

# Write runtime config so the React app knows the API URL without a rebuild
cat > /usr/share/nginx/html/config.js <<EOF
window.ENV = { apiUrl: '${API_URL}' };
EOF

exec nginx -g 'daemon off;'
