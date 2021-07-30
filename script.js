let logs;

function update() {
	let resources = [];
	let endpoints = [];
	let playerNames = [];

	let dateInput = document.getElementById('date');
	let resourceSelect = document.getElementById('resource');
	let endpointSelect = document.getElementById('endpoint');
	let playerNameSelect = document.getElementById('playerName');
	let logBody = document.getElementById('log-body');

	let after = new Date(dateInput.value + ' 00:00:00');
	let before = new Date(dateInput.value + ' 00:00:00');
	before.setDate(before.getDate() + 1);

	logBody.innerHTML = '';

	logs.forEach(entry => {
		let time = new Date(entry.time);

		let afterMatched = isNaN(after) || time > after;
		let beforeMatched = isNaN(before) || time < before;
		let resourceMatched = resourceSelect.value == '' || resourceSelect.value == entry.resource;
		let endpointMatched = endpointSelect.value == '' || endpointSelect.value == entry.endpoint;
		let playerNameMatched = playerNameSelect.value == '' || playerNameSelect.value == entry.player_name;

		if (entry.resource && afterMatched && beforeMatched && endpointMatched && playerNameMatched) {
			resources.push(entry.resource);
		}

		if (entry.endpoint && afterMatched && beforeMatched && resourceMatched && playerNameMatched) {
			endpoints.push(entry.endpoint);
		}

		if (entry.player_name && afterMatched && beforeMatched && resourceMatched && endpointMatched) {
			playerNames.push(entry.player_name);
		}

		if (!(afterMatched && beforeMatched && resourceMatched && endpointMatched && playerNameMatched)) {
			return;
		}

		let entryDiv = document.createElement('div');
		entryDiv.className = 'log-entry';

		let timeDiv = document.createElement('div');
		timeDiv.innerHTML = entry.time;

		let resourceDiv = document.createElement('div');
		resourceDiv.innerHTML = entry.resource;

		let endpointDiv = document.createElement('div');
		endpointDiv.innerHTML = entry.endpoint;

		let playerNameDiv = document.createElement('div');
		playerNameDiv.innerHTML = entry.player_name;

		let messageDiv = document.createElement('div');
		messageDiv.innerHTML = entry.message;

		entryDiv.appendChild(timeDiv);
		entryDiv.appendChild(resourceDiv);
		entryDiv.appendChild(endpointDiv);
		entryDiv.appendChild(playerNameDiv);
		entryDiv.appendChild(messageDiv);

		logBody.appendChild(entryDiv);
	});

	resources = new Set(resources);
	resources = Array.from(resources);
	resources.sort();

	let currentResource = resourceSelect.value;
	resourceSelect.innerHTML = '<option></option>';

	resources.forEach(resource => {
		let option = document.createElement('option');
		option.value = resource;
		option.innerHTML = resource;
		option.selected = resource == currentResource;

		resourceSelect.appendChild(option);
	});

	endpoints = new Set(endpoints);
	endpoints = Array.from(endpoints);
	endpoints.sort();

	let currentEndpoint = endpointSelect.value;
	endpointSelect.innerHTML = '<option></option>';

	endpoints.forEach(endpoint => {
		let option = document.createElement('option');
		option.value = endpoint;
		option.innerHTML = endpoint;
		option.selected = endpoint == currentEndpoint;

		endpointSelect.appendChild(option);
	});

	playerNames = new Set(playerNames);
	playerNames = Array.from(playerNames);
	playerNames.sort();

	let currentPlayerName = playerNameSelect.value;
	playerNameSelect.innerHTML = '<option></option>';

	playerNames.forEach(playerName => {
		let option = document.createElement('option');
		option.value = playerName;
		option.innerHTML = playerName;
		option.selected = playerName == currentPlayerName;

		playerNameSelect.appendChild(option);
	});
}

function refresh() {
	fetch('logs.php').then(resp => resp.json()).then(resp => {
		logs = resp;
		update();
	});
}

window.addEventListener('load', function(event) {
	let now = new Date();
	let year = now.getFullYear();
	let month = (now.getMonth() + 1).toString().padStart(2, '0');
	let day = now.getDate().toString().padStart(2, '0');

	document.getElementById('date').value = `${year}-${month}-${day}`;

	refresh();

	document.querySelectorAll('.update').forEach(e => e.addEventListener('input', function(event) {
		update();
	}));

	document.getElementById('refresh').addEventListener('click', refresh);
});
