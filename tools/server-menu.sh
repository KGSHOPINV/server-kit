#!/bin/bash
# ============================================================
# SERVER COMMAND CENTER
# Main TUI menu for server management
# ============================================================

IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "unknown")
HOSTNAME=$(hostname 2>/dev/null || echo "server")
UPTIME=$(uptime -p 2>/dev/null || echo "unknown")
DOCKER_COUNT=$(docker ps -q 2>/dev/null | wc -l || echo "0")
MEM_USAGE=$(free -h 2>/dev/null | awk '/Mem:/ {printf "%s / %s", $3, $2}' || echo "unknown")
DISK_USAGE=$(df -h / 2>/dev/null | awk 'NR==2 {printf "%s / %s (%s)", $3, $2, $5}' || echo "unknown")

show_menu() {
  clear
  echo ""
  echo "  =================================================="
  echo "    SERVER COMMAND CENTER"
  echo "  =================================================="
  echo ""
  echo "    Host: $HOSTNAME    IP: $IP"
  echo "    Up:   $UPTIME"
  echo "    Mem:  $MEM_USAGE    Disk: $DISK_USAGE"
  echo "    Containers running: $DOCKER_COUNT"
  echo ""
  echo "  =================================================="
  echo ""
  echo "    1)  View running services"
  echo "    2)  Scan ports"
  echo "    3)  Add new project"
  echo "    4)  Health check"
  echo "    5)  View logs (Dozzle)"
  echo "    6)  Container management (Portainer)"
  echo "    7)  System stats (Netdata)"
  echo "    8)  Backup now"
  echo "    9)  Linux cheat sheet"
  echo "   10)  Open Claude CLI"
  echo "   11)  Docker shortcuts"
  echo "   12)  Hardware monitor (temps, disks, power)"
  echo "    0)  Exit"
  echo ""
  echo "  =================================================="
  echo ""
}

docker_shortcuts() {
  echo ""
  echo "  DOCKER SHORTCUTS"
  echo "  ─────────────────────────────────────"
  echo "  dps         - Container status table"
  echo "  dlogs NAME  - Follow container logs"
  echo "  dcu         - docker compose up -d"
  echo "  dcd         - docker compose down"
  echo "  dcr         - docker compose restart"
  echo "  dcp         - pull + restart"
  echo ""
  echo "  docker exec -it NAME bash  - Shell into container"
  echo "  docker system prune -a     - Clean unused images"
  echo "  docker volume ls           - List volumes"
  echo ""
  read -p "  Press Enter to continue..."
}

while true; do
  show_menu
  read -p "  Pick an option: " choice

  case $choice in
    1)
      echo ""
      docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Docker not running."
      echo ""
      read -p "  Press Enter to continue..."
      ;;
    2)
      port-scan
      read -p "  Press Enter to continue..."
      ;;
    3)
      add-project
      ;;
    4)
      health-check
      read -p "  Press Enter to continue..."
      ;;
    5)
      echo ""
      echo "  Opening Dozzle in browser..."
      echo "  URL: http://$IP:8080"
      xdg-open "http://$IP:8080" 2>/dev/null || echo "  Open http://$IP:8080 in your browser."
      read -p "  Press Enter to continue..."
      ;;
    6)
      echo ""
      echo "  Opening Portainer..."
      echo "  URL: https://$IP:9443"
      xdg-open "https://$IP:9443" 2>/dev/null || echo "  Open https://$IP:9443 in your browser."
      read -p "  Press Enter to continue..."
      ;;
    7)
      echo ""
      echo "  Opening Netdata..."
      echo "  URL: http://$IP:19999"
      xdg-open "http://$IP:19999" 2>/dev/null || echo "  Open http://$IP:19999 in your browser."
      read -p "  Press Enter to continue..."
      ;;
    8)
      echo ""
      server-backup
      read -p "  Press Enter to continue..."
      ;;
    9)
      cheatsheet
      ;;
    10)
      echo ""
      echo "  Launching Claude CLI..."
      claude
      ;;
    11)
      docker_shortcuts
      ;;
    12)
      hw-monitor
      read -p "  Press Enter to continue..."
      ;;
    0)
      echo ""
      echo "  Bye."
      echo ""
      exit 0
      ;;
    *)
      echo "  Invalid option."
      sleep 1
      ;;
  esac
done
