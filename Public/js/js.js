function lockButton() {
	var buttons = document.getElementsByName("lockableButton");

	
	buttons.forEach((button) => {
		button.disabled = true;
	});
	
}

function uncheckRadioButtons(name) {
    var buttons = document.getElementsByName(name);
    buttons.forEach((button) => {
        button.checked = false;
    });
}
