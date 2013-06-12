/* Function to rotate the banner image on the home page*/
function loadpage(image1, image2, image3, image4) {
    index1 = 0;
    listofimages = new Array(4);
    listofimages[0] = new Image(500,299)
    listofimages[0].src = image1
    listofimages[1] = new Image(500,299)
    listofimages[1].src = image2
    listofimages[2] = new Image(500,299)
    listofimages[2].src = image3
    listofimages[3] = new Image(500,299)
    listofimages[3].src = image4
   
  
    
    thetimer = setTimeout("changeimage()", 5000);

}

function changeimage(){

    index1 = index1 + 1
    if (index1 == "4") {

        index1 = 0 

    }
    imagesource = listofimages[index1].src
    window.document.banner1.src = imagesource

    thetimer = setTimeout("changeimage()", 7000);

}

function changepage() {

    if (index1 == 0) {

        newlocation = "/submit/abrc_submission.jsp" 

    }
    else if (index1 == 1) {

        newlocation = "/submit/abrc_submission.jsp" 

    }
    else if (index1 == 2) {

        newlocation = "/submit/abrc_submission.jsp" 

    }
    
    else if (index1 == 3) {

        newlocation = "/submit/abrc_submission.jsp" 

    }
    

    
    location = newlocation 

} 
