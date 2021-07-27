<html>
<head>
<title>logmanager</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
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

if (!empty($_GET['after'])) {
	$after = $_GET['after'];
}
if (!empty($_GET['before'])) {
	$before = $_GET['before'];
}
if (!empty($_GET['resource'])) {
	$resource = $_GET['resource'];
}
if (!empty($_GET['endpoint'])) {
	$endpoint = $_GET['endpoint'];
}
if (!empty($_GET['player_name'])) {
	$player_name = $_GET['player_name'];
}

$sql = <<<SQL
SELECT
	time,
	resource,
	endpoint,
	player_name,
	message
FROM
	logmanager_log
WHERE
	(? IS NULL OR time < ?) AND
	(? IS NULL OR time > ?) AND
	(? IS NULL OR resource = ?) AND
	(? IS NULL OR endpoint = ?) AND
	(? IS NULL OR player_name = ?)
ORDER BY
	time
SQL;

$stmt = $conn->prepare($sql);
$stmt->bind_param("ssssssssss", $after, $after, $before, $before, $resource, $resource, $endpoint, $endpoint, $player_name, $player_name);
$stmt->execute();

$result = $stmt->get_result();

$rows = array();

$resources = array();
$endpoints = array();
$player_names = array();

while ($row = $result->fetch_assoc()) {
	array_push($rows, $row);

	if (!empty($row['resource'])) {
		array_push($resources, $row['resource']);
	}

	if (!empty($row['endpoint'])) {
		array_push($endpoints, $row['endpoint']);
	}

	if (!empty($row['player_name'])) {
		array_push($player_names, $row['player_name']);
	}
}
?>
<form>
<select name="resource">
<option></option>
<?php

$resources = array_unique($resources);
sort($resources);

foreach ($resources as $r) {
	if (isset($resource) && $r == $resource) {
		echo '<option value="' . $r . '" selected>' . $r . '</option>';
	} else {
		echo '<option value="' . $r . '">' . $r . '</option>';
	}
}

?>
</select>
<select name="endpoint">
<option></option>
<?php

$endpoints = array_unique($endpoints);
sort($endpoints);

foreach ($endpoints as $e) {
	if (isset($endpoint) && $e == $endpoint) {
		echo '<option value="' . $e . '" selected>' . $e . '</option>';
	} else {
		echo '<option value="' . $e . '">' . $e . '</option>';
	}
}

?>
</select>
<select name="player_name">
<option></option>
<?php

$player_names = array_unique($player_names);
sort($player_names);

foreach ($player_names as $p) {
	if (isset($player_name) && $p == $player_name) {
		echo '<option value="' . $p . '" selected>' . $p . '</option>';
	} else {
		echo '<option value="' . $p . '">' . $p . '</option>';
	}
}

?>
</select>
<input type="submit" value="Filter">
</form>
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

foreach ($rows as $row) {
	echo '<div class="log-entry">';
	echo '<div>' . $row['time'] . '</div>';
	echo '<div>' . $row['resource'] . '</div>';
	echo '<div>' . $row['endpoint'] . '</div>';
	echo '<div>' . $row['player_name'] . '</div>';
	echo '<div>' . $row['message'] . '</div>';
	echo '</div>';
}

$conn->close();

?>
</div>
</div>
</body>
</html>
