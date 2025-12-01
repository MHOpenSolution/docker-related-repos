<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LAMP Docker Stack</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        h1 { 
            color: #333;
            margin-bottom: 20px;
            text-align: center;
        }
        .status {
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        .status-icon { font-size: 24px; }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #667eea;
            color: white;
        }
        tr:hover { background: #f5f5f5; }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .card {
            padding: 20px;
            background: #f8f9fa;
            border-radius: 5px;
            border-left: 4px solid #667eea;
        }
        .card h3 { margin-bottom: 10px; color: #667eea; }
        .code {
            background: #f4f4f4;
            padding: 10px;
            border-radius: 5px;
            font-family: monospace;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Docker LAMP Stack Status</h1>
        
        <?php
        
        $db_host = getenv('DB_HOST') ?: 'mysql_server';
        $db_name = getenv('DB_NAME') ?: 'myapp_db';
        $db_user = getenv('DB_USER') ?: 'webapp_user';
        $db_pass = getenv('DB_PASSWORD') ?: 'webappSecurePass123!';

	echo $db_host;	
        
        try {
            $dsn = "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4";
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ];
            
            $pdo = new PDO($dsn, $db_user, $db_pass, $options);
            
            echo '<div class="status success">';
            echo '<span class="status-icon">[/]</span>';
            echo '<div><strong>Database Connection:</strong> Successfully connected to MySQL!</div>';
            echo '</div>';
            
         
            $version = $pdo->query('SELECT VERSION()')->fetchColumn();
            $currentDb = $pdo->query('SELECT DATABASE()')->fetchColumn();
            $currentUser = $pdo->query('SELECT USER()')->fetchColumn();
            
            echo '<div class="grid">';
            echo '<div class="card">';
            echo '<h3>MySQL Information</h3>';
            echo '<p><strong>Version:</strong> ' . htmlspecialchars($version) . '</p>';
            echo '<p><strong>Database:</strong> ' . htmlspecialchars($currentDb) . '</p>';
            echo '<p><strong>User:</strong> ' . htmlspecialchars($currentUser) . '</p>';
            echo '</div>';
            
            echo '<div class="card">';
            echo '<h3>PHP Information</h3>';
            echo '<p><strong>Version:</strong> ' . PHP_VERSION . '</p>';
            echo '<p><strong>Server:</strong> ' . $_SERVER['SERVER_SOFTWARE'] . '</p>';
            echo '<p><strong>Host:</strong> ' . gethostname() . '</p>';
            echo '</div>';
            echo '</div>';
            
            //  sample
            $pdo->exec("CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100) NOT NULL UNIQUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
            
           
            $count = $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
            if ($count == 0) {
                $pdo->exec("INSERT INTO users (name, email) VALUES 
                    ('John Doe', 'john@example.com'),
                    ('Jane Smith', 'jane@example.com'),
                    ('Bob Johnson', 'bob@example.com')");
            }
            
            
            echo '<h2>Sample Data (Users Table)</h2>';
            echo '<table>';
            echo '<thead><tr><th>ID</th><th>Name</th><th>Email</th><th>Created At</th></tr></thead>';
            echo '<tbody>';
            
            $stmt = $pdo->query("SELECT * FROM users ORDER BY id");
            while ($row = $stmt->fetch()) {
                echo '<tr>';
                echo '<td>' . htmlspecialchars($row['id']) . '</td>';
                echo '<td>' . htmlspecialchars($row['name']) . '</td>';
                echo '<td>' . htmlspecialchars($row['email']) . '</td>';
                echo '<td>' . htmlspecialchars($row['created_at']) . '</td>';
                echo '</tr>';
            }
            
            echo '</tbody></table>';
            
          
            echo '<h2>Loaded PHP Extensions</h2>';
            echo '<div class="code">';
            $extensions = get_loaded_extensions();
            sort($extensions);
            echo implode(', ', $extensions);
            echo '</div>';
            
        } catch (PDOException $e) {
            echo '<div class="status error">';
            echo '<span class="status-icon">[X]</span>';
            echo '<div><strong>Database Connection Error:</strong> ' . htmlspecialchars($e->getMessage()) . '</div>';
            echo '</div>';
        }
        ?>
        
        <div class="status info">
            <span class="status-icon">[i[</span>
            <div>
                <strong>Access Information:</strong><br>
                Web Server: <a href="http://localhost">http://localhost</a><br>
                PhpMyAdmin: <a href="http://localhost:8080">http://localhost:8080</a>
            </div>
        </div>
    </div>
</body>
</html>
