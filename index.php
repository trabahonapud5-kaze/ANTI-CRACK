<?php
header("Content-Type: text/plain");

// Kukunin ang key mula sa POST request ng app
$user_key = $_POST['key'] ?? '';

// Basta hindi empty ang key (kasi validated na ito sa client side bilang "valid")
if (!empty($user_key)) {
    
    $file = 'log1.lua';
    
    if (file_exists($file)) {
        // Ipadala ang buong payload/injector script
        echo file_get_contents($file);
    } else {
        http_response_code(404);
        echo "Error: File log1.lua not found on server.";
    }
    
    exit();
} else {
    // Kapag walang ipinasang key
    http_response_code(403);
    echo "ACCESS DENIED: No key provided";
    exit();
}
?>
