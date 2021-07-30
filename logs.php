<?php
$server = 'localhost';
$port = 3306;
$username = 'changeme';
$password = 'changeme';
$database = 'changeme';

$conn = new mysqli($server, $username, $password, $database, $port);

if ($conn->connect_error) {
	die('Connection failed: ' . $conn->connect_error);
}

$sql = <<<SQL
SELECT
	time,
	resource,
	endpoint,
	player_name,
	message,
	coords_x,
	coords_y,
	coords_z
FROM
	logmanager_log
ORDER BY
	time
SQL;

$result = $conn->query($sql);

$log = array();

while ($row = $result->fetch_assoc()) {
	array_push($log, $row);
}

$conn->close();

header('Content-type: application/json');
echo json_encode($log);
?>
