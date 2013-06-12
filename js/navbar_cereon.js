var imagePath = "/images";

if (document.images) {
  lownav1on = new Image();
  lownav1on.src = imagePath+"/navbar/tairdb_y.gif";

  lownav2on = new Image();
  lownav2on.src = imagePath+"/navbar/tools_y.gif";

  lownav3on = new Image();
  lownav3on.src = imagePath+"/navbar/info_y.gif";

  lownav4on = new Image();
  lownav4on.src = imagePath+"/navbar/news_y.gif";

  lownav5on = new Image();
  lownav5on.src = imagePath+"/navbar/links_y.gif";
  
  lownav6on = new Image();
  lownav6on.src = imagePath+"/navbar/ftp_y.gif";

  lownav7on = new Image();
  lownav7on.src = imagePath+"/navbar/stocks_y.gif";

// --------------------------------

  lownav1off = new Image();
  lownav1off.src = imagePath+"/navbar/tairdb_g.gif";

  lownav2off = new Image();
  lownav2off.src = imagePath+"/navbar/tools_g.gif";

  lownav3off = new Image();
  lownav3off.src = imagePath+"/navbar/info_g.gif";

  lownav4off = new Image();
  lownav4off.src = imagePath+"/navbar/news_g.gif";

  lownav5off = new Image();
  lownav5off.src = imagePath+"/navbar/links_g.gif";

  lownav6off = new Image();
  lownav6off.src = imagePath+"/navbar/ftp_g.gif";

  lownav7off = new Image();
  lownav7off.src = imagePath+"/navbar/stocks_g.gif";
}

function turnOnR(imageName) {
  if (document.images) {
    document[imageName].src = eval(imageName + "on.src");
  }
}

function turnOffR(imageName) {
  if (document.images) {
    document[imageName].src = eval(imageName + "off.src");
  }
}
