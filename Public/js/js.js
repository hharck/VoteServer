function lockButton() {
	var buttons = document.getElementsByName("lockableButton");

	
	buttons.forEach((button) => {
		button.disabled = true;
	});
	
}
