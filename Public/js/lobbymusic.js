var audio = null;
var isPlaying = false;
function playLobbyMusic(){
	if (audio){
		if (isPlaying){
			audio.pause();
			isPlaying = false;
		} else {
			audio.play();
			isPlaying = true;
		}
	} else {
		audio = new Audio('/lobbymusic.wav');
		audio.loop=true;
		audio.play();
		isPlaying = true;
	}
	
	var playButton = document.getElementById("playButton");
	if (isPlaying){
		playButton.innerHTML = "Pause";
	} else {
		playButton.innerHTML = "Play";
	}
}
