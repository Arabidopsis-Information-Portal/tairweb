if (document.images) {
  lownav1on = new Image();
  lownav1on.src = "/images/navbar/tairdb_y.gif";

  lownav2on = new Image();
  lownav2on.src = "/images/navbar/tools_y.gif";

  lownav3on = new Image();
  lownav3on.src = "/images/navbar/browse_y.gif";

  lownav4on = new Image();
  lownav4on.src = "/images/navbar/news_y.gif";

  lownav5on = new Image();
  lownav5on.src = "/images/navbar/portals_y.gif";
  
  lownav6on = new Image();
  lownav6on.src = "/images/navbar/ftp_y.gif";

  lownav7on = new Image();
  lownav7on.src = "/images/navbar/stocks_y.gif";

  lownav8on = new Image();
  lownav8on.src = "/images/navbar/submit_y.gif";

// --------------------------------

  lownav1off = new Image();
  lownav1off.src = "/images/navbar/tairdb_g.gif";

  lownav2off = new Image();
  lownav2off.src = "/images/navbar/tools_g.gif";

  lownav3off = new Image();
  lownav3off.src = "/images/navbar/browse_g.gif";

  lownav4off = new Image();
  lownav4off.src = "/images/navbar/news_g.gif";

  lownav5off = new Image();
  lownav5off.src = "/images/navbar/portals_g.gif";

  lownav6off = new Image();
  lownav6off.src = "/images/navbar/ftp_g.gif";

  lownav7off = new Image();
  lownav7off.src = "/images/navbar/stocks_g.gif";

  lownav8off = new Image();
  lownav8off.src = "/images/navbar/submit_g.gif";
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
