#!/bin/bash

# Output file
output_file="penetration_test_results.txt"

# Clear previous results file
echo "" > "$output_file"

# Function to check if a port is open
check_port() {
    nc -z -w 1 "$1" "$2" >/dev/null 2>&1
    return $?
}

# Function to save important information to the results file
save_info() {
    echo "$1" >> "$output_file"
}

# Check if HTTP port is open
http_ports=("80" "8080")  # Add additional HTTP ports if needed
http_service="Apache HTTP Server"  # Specify the HTTP service name
http_found=false

for port in "${http_ports[@]}"; do
    if check_port "$1" "$port"; then
        http_found=true
        # Run Nikto scan
        echo "Running Nikto scan for $http_service on port $port..."
        nikto_scan=$(nikto -h "$1:$port" -output "$output_file" 2>/dev/null)
        save_info "Nikto scan results for $http_service on port $port:"
        save_info "$nikto_scan"
    fi
done

if ! "$http_found"; then
    echo "No HTTP service found on specified ports."
fi

# Check if Telnet port is open
telnet_port="23"
if check_port "$1" "$telnet_port"; then
    # Save Telnet banner
    echo "Saving Telnet banner..."
    telnet_banner=$(echo "open $1 $telnet_port" | telnet 2>/dev/null | grep -v "Escape character is")
    save_info "Telnet banner:"
    save_info "$telnet_banner"
else
    echo "Telnet port ($telnet_port) is closed."
fi

# Check if FTP port is open
ftp_port="21"
if check_port "$1" "$ftp_port"; then
    # Check if anonymous FTP is open
    echo "Checking for anonymous FTP..."
    if echo -e "open $1 $ftp_port\nanonymous\nquit" | ftp -n -v "$1" 2>/dev/null | grep -q "230 Login successful"; then
        save_info "Anonymous FTP is open."
    else
        save_info "Anonymous FTP is not open."
    fi
else
    echo "FTP port ($ftp_port) is closed."
fi

echo "Penetration testing completed. Results saved in $output_file."
