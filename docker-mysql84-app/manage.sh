#!/bin/bash


show_help() {
    cat << EOF
Docker LAMP Stack Management

Usage: ./manage.sh [COMMAND]

Commands:
    start           Start all containers
    stop            Stop all containers
    restart         Restart all containers
    build           Build and start containers
    logs            Show logs (all containers)
    logs-web        Show web server logs
    logs-mysql      Show MySQL logs
    status          Show container status
    mysql           Connect to MySQL CLI
    bash-web        Enter web container bash
    bash-mysql      Enter MySQL container bash
    backup          Backup MySQL database
    restore         Restore MySQL database (requires backup file)
    clean           Stop and remove all containers, networks, volumes
    update          Pull latest images and rebuild
    phpinfo         Create phpinfo page

Examples:
    ./manage.sh start
    ./manage.sh logs-web
    ./manage.sh mysql
    ./manage.sh backup

EOF
}

case "$1" in
    start)
        echo "Starting Docker LAMP stack..."
        docker-compose up -d
        echo "Services started. Access:"
        echo "  Web: http://localhost"
        echo "  PhpMyAdmin: http://localhost:8080"
        ;;
    
    stop)
        echo "Stopping Docker LAMP stack..."
        docker-compose down
        ;;
    
    restart)
        echo "Restarting Docker LAMP stack..."
        docker-compose restart
        ;;
    
    build)
        echo "Building and starting Docker LAMP stack..."
        docker-compose up -d --build
        ;;
    
    logs)
        docker-compose logs -f
        ;;
    
    logs-web)
        docker-compose logs -f web
        ;;
    
    logs-mysql)
        docker-compose logs -f mysql
        ;;
    
    status)
        docker-compose ps
        echo ""
        echo "Resource usage:"
        docker stats --no-stream mysql_server php_apache_server phpmyadmin
        ;;
    
    mysql)
        echo "Connecting to MySQL CLI..."
        docker exec -it mysql_server mysql -u root -prootSecurePass123!
        ;;
    
    bash-web)
        echo "Entering web container..."
        docker exec -it php_apache_server bash
        ;;
    
    bash-mysql)
        echo "Entering MySQL container..."
        docker exec -it mysql_server bash
        ;;
    
    backup)
        echo "Creating MySQL backup..."
        ./backup_mysql.sh
        ;;
    
    restore)
        if [ -z "$2" ]; then
            echo "Usage: ./manage.sh restore <backup_file.tar.gz>"
            echo "Available backups:"
            ls -lh backups/*.tar.gz 2>/dev/null || echo "No backups found"
            exit 1
        fi
        
        if [ ! -f "$2" ]; then
            echo "Backup file not found: $2"
            exit 1
        fi
        
        echo "Extracting backup..."
        BACKUP_FILE=$(basename "$2")
        tar -xzf "$2" -C backups/
        
        DATE_SUFFIX="${BACKUP_FILE#mysql_backup_}"
        DATE_SUFFIX="${DATE_SUFFIX%.tar.gz}"
        
        echo "Running restore script..."
        bash backups/restore_${DATE_SUFFIX}.sh
        ;;
    
    clean)
        read -p "This will remove all containers, networks, and volumes. Continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Cleaning up Docker LAMP stack..."
            docker-compose down -v
            echo "Cleanup completed"
        else
            echo "Cancelled"
        fi
        ;;
    
    update)
        echo "Updating Docker LAMP stack..."
        docker-compose pull
        docker-compose up -d --build
        ;;
    
    phpinfo)
        echo "Creating phpinfo.php..."
        echo "<?php phpinfo(); ?>" > www/phpinfo.php
        echo "Created: http://localhost/phpinfo.php"
        echo "Remember to delete this file in production!"
        ;;
    
    *)
        show_help
        ;;
esac
