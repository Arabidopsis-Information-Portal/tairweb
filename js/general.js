var path = "/graphics/";
var color = "";

function init(type) {
	color = type;
}

function hl(nom) {
	newImage = path + nom + "_black.gif";
	document[nom].src = newImage;
}

function re(nom) {
	newImage = path + nom + "_" + color + ".gif";
	document[nom].src = newImage;
}
