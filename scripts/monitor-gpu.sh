#!/bin/bash

# GPU monitoring script for RTX 4060
# Shows real-time GPU usage, memory, temperature, and ML service status

echo "🎮 RTX 4060 Monitoring Dashboard"
echo "================================"

# Function to get ML service status
get_ml_status() {
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "🟢 ML Service: Online"
        
        # Get GPU status from ML service
        gpu_status=$(curl -s http://localhost:8080/gpu/status 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "   $(echo $gpu_status | jq -r '.device_name // "Unknown GPU"')"
            memory_used=$(echo $gpu_status | jq -r '.memory_allocated // 0')
            memory_total=$(echo $gpu_status | jq -r '.memory_total // 0')
            if [ "$memory_total" -gt 0 ]; then
                memory_percent=$((memory_used * 100 / memory_total))
                echo "   GPU Memory: ${memory_percent}% ($(($memory_used / 1024 / 1024))MB / $(($memory_total / 1024 / 1024))MB)"
            fi
        fi
    else
        echo "🔴 ML Service: Offline"
    fi
}

# Function to show Docker container status
get_container_status() {
    echo ""
    echo "🐳 Container Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep htxv2 || echo "   No HTXV2 containers running"
}

# Main monitoring loop
while true; do
    clear
    
    echo "🎮 RTX 4060 Monitoring Dashboard"
    echo "================================"
    echo "$(date)"
    echo ""
    
    # GPU hardware info
    if command -v nvidia-smi &> /dev/null; then
        echo "🔋 GPU Hardware:"
        nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader,nounits | \
        awk -F', ' '{printf "   %s (Driver: %s, Memory: %s MB)\n", $1, $2, $3}'
        echo ""
        
        echo "📊 Real-time GPU Stats:"
        nvidia-smi --query-gpu=memory.used,memory.total,temperature.gpu,utilization.gpu,power.draw --format=csv,noheader,nounits | \
        awk -F', ' '{
            mem_percent = ($1 * 100) / $2
            printf "   Memory: %s/%s MB (%.1f%%) | Temp: %s°C | Usage: %s%% | Power: %sW\n", $1, $2, mem_percent, $3, $4, $5
        }'
        echo ""
        
        # GPU processes
        processes=$(nvidia-smi --query-compute-apps=pid,name,used_memory --format=csv,noheader,nounits)
        if [ ! -z "$processes" ]; then
            echo "🔄 GPU Processes:"
            echo "$processes" | awk -F', ' '{printf "   PID %s: %s (%s MB)\n", $1, $2, $3}'
            echo ""
        fi
    else
        echo "❌ nvidia-smi not available"
        echo ""
    fi
    
    # ML Service status
    get_ml_status
    
    # Container status
    get_container_status
    
    # System memory
    echo ""
    echo "🧠 System Memory:"
    free -h | grep Mem | awk '{printf "   Used: %s/%s (%.1f%%)\n", $3, $2, ($3/$2)*100}'
    
    echo ""
    echo "⏱️  Press Ctrl+C to exit | Refreshing every 5 seconds..."
    
    # Wait 5 seconds or exit on Ctrl+C
    sleep 5
done