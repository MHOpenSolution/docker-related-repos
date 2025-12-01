<?php
/**
 * Database Configuration and Connection Handler
 */

class Database {
    private static $instance = null;
    private $connection;
    

    private $host;
    private $database;
    private $username;
    private $password;
    
    private function __construct() {
        $this->host = getenv('DB_HOST') ?: 'mysql';
        $this->database = getenv('DB_NAME') ?: 'myapp_db';
        $this->username = getenv('DB_USER') ?: 'webapp_user';
        $this->password = getenv('DB_PASSWORD') ?: 'webappSecurePass123!';
        
        $this->connect();
    }

    private function connect() {
        try {
            $dsn = "mysql:host={$this->host};dbname={$this->database};charset=utf8mb4";
            
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
                PDO::ATTR_PERSISTENT => false,
            ];
            
            $this->connection = new PDO($dsn, $this->username, $this->password, $options);
            
        } catch (PDOException $e) {
            die("Connection failed: " . $e->getMessage());
        }
    }
    

    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    

    public function getConnection() {
        return $this->connection;
    }
    

    private function __clone() {}
    

    public function __wakeup() {
        throw new Exception("Cannot unserialize singleton");
    }
}

// Usage example:
// $db = Database::getInstance();
// $conn = $db->getConnection();
// $stmt = $conn->prepare("SELECT * FROM users WHERE id = ?");
// $stmt->execute([1]);
// $user = $stmt->fetch();
