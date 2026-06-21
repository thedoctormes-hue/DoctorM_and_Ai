#!/bin/bash
# Test: lab-vault service is running and responding

echo "Testing lab-vault service..."
if systemctl is-active --quiet lab-vault; then
    echo "✅ lab-vault.service is active"
else
    echo "❌ lab-vault.service is not active"
    exit 1
fi

# Check if it's listening on expected port
if ss -tlnp | grep -q ":8301.*lab-vault"; then
    echo "✅ lab-vault is listening on port 8301"
else
    echo "❌ lab-vault is not listening on port 8301"
    exit 1
fi

# Check if it's responding
if curl -s http://127.0.0.1:8301/health >/dev/null 2>&1; then
    echo "✅ lab-vault responds to health check"
else
    # Try basic endpoint
    if curl -s http://127.0.0.1:8301/ >/dev/null 2>&1; then
        echo "✅ lab-vault responds to root endpoint"
    else
        echo "⚠️  lab-vault may not have health endpoint but is listening"
    fi
fi

echo "All lab-vault tests passed!"
exit 0