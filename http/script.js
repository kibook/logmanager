const mapUrl = null;

let logs;

function timeToString(date) {
	let year = date.getFullYear().toString();
	let month = (date.getMonth() + 1).toString().padStart(2, '0');
	let day = date.getDate().toString().padStart(2, '0');

	let hour = date.getHours().toString().padStart(2, '0');
	let min = date.getMinutes().toString().padStart(2, '0');
	let sec = date.getSeconds().toString().padStart(2, '0');

	return `${year}-${month}-${day} ${hour}:${min}:${sec}`
}

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
		timeDiv.innerHTML = timeToString(time);

		let resourceDiv = document.createElement('div');
		resourceDiv.innerHTML = entry.resource;

		let endpointDiv = document.createElement('div');
		endpointDiv.innerHTML = entry.endpoint;

		let playerNameDiv = document.createElement('div');
		playerNameDiv.innerHTML = entry.player_name;

		let messageDiv = document.createElement('div');
		messageDiv.innerHTML = entry.message;

		let coordsDiv = document.createElement('div');
		if (entry.coords_x && entry.coords_y && entry.coords_z) {
			let x = parseFloat(entry.coords_x).toFixed(2);
			let y = parseFloat(entry.coords_y).toFixed(2);
			let z = parseFloat(entry.coords_z).toFixed(2);

			if (mapUrl) {
				let a = document.createElement('a');
				a.href = `${mapUrl}?x=${x}&y=${y}&z=${z}`;
				a.target = '_blank';
				a.innerHTML = `(${x}, ${y}, ${z})`;
				coordsDiv.appendChild(a);
			} else {
				coordsDiv.innerHTML += `(${x}, ${y}, ${z})`;
			}
		} else {
			coordsDiv.innerHTML = '-';
		}

		entryDiv.appendChild(timeDiv);
		entryDiv.appendChild(resourceDiv);
		entryDiv.appendChild(endpointDiv);
		entryDiv.appendChild(playerNameDiv);
		entryDiv.appendChild(messageDiv);
		entryDiv.appendChild(coordsDiv);

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
	let date = document.getElementById('date').value;

	fetch('logs.json', {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json'
		},
		body: JSON.stringify({
			date: date
		})
	}).then(resp => resp.json()).then(resp => {
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

	document.getElementById('date').addEventListener('input', function(e) {
		refresh();
	});

	document.querySelectorAll('.update').forEach(e => e.addEventListener('input', function(event) {
		update();
	}));

	document.getElementById('refresh').addEventListener('click', refresh);
});
