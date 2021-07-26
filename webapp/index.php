<html>
<head>
<title>logmanager</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<div class="log">
<div class="log-headers">
<div>Time</div>
<div>Resource</div>
<div>Endpoint</div>
<div>Player name</div>
<div>Message</div>
</div>
<div class="log-body">
<?php

$server = "localhost";
$port = 3306;
$username = "changeme";
$password = "changeme";
$database = "changeme";

$conn = new mysqli($server, $username, $password, $database, $port);

if ($conn->connect_error) {
	die("Connection failed: " . $conn->connect_error);
}

$result = $conn->query("SELECT time, resource, endpoint, player_name, message FROM logmanager_log ORDER BY time");

while ($row = $result->fetch_assoc()) {
	echo '<div class="log-entry">';
	echo '<div>' . $row["time"] . '</div>';
	echo '<div>' . $row["resource"] . '</div>';
	echo '<div>' . $row["endpoint"] . '</div>';
	echo '<div>' . $row["player_name"] . '</div>';
	echo '<div>' . $row["message"] . '</div>';
	echo '</div>';
}

$conn->close();

?>
</div>
</body>
</html>
