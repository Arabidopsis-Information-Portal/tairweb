// Library of functions used across all search forms that
// do dynamic population of map type & units
//
// To use this library:
// search form must be named "searchForm"
// units menus must be named "low_unit" and "high_unit"
// map type menu must be named "map_type"
// order by menu must be named "order" 
// range menu must be named "range_type"
//
// range menu should have onChange="checkRange()" event handler
// order by menu should have onChange="checkPosition()" event handler
// each map_type button should have onClick="updateMenu( 'MAP_TYPE' )" event handler


// all purpose menu populator
function updateMenu( selectMenu, optionsList, valuesList ) {
      selectMenu.options.length = 0;
      for ( i = 0; i < optionsList.length; i++ ) {
         selectMenu.options[ i ] = new Option( optionsList[ i ], valuesList[ i ] );
      }
}

// set units contents for each map type
function updateUnits( map_type ) {
      var unitsValues;
      var unitsDisplay;
      
      if ( map_type =="" ) {
          return;
      }

      if ( map_type == "RI" ) {
         unitsDisplay = new Array( 2 )
         unitsDisplay[ 0 ] = "cM";
         unitsDisplay[ 1 ] = "marker";

         unitsValues = new Array( 2 )
         unitsValues[ 0 ] = "cM";
         unitsValues[ 1 ] = "marker";

      } else if ( map_type == "classical" ) {
         unitsDisplay = new Array( 2 );
         unitsDisplay[ 0 ] = "cM";
         unitsDisplay[ 1 ] = "marker";

         unitsValues = new Array( 2 );
         unitsValues[ 0 ] = "cM";
         unitsValues[ 1 ] = "marker";

      } else if ( map_type == "physical" ) {
         unitsDisplay = new Array( 3 );
         unitsDisplay[ 0 ] = "kb"; 
         unitsDisplay[ 1 ] = "gene";
         unitsDisplay[ 2 ] = "clone";

         unitsValues = new Array( 3 );
         unitsValues[ 0 ] = "kb"; 
         unitsValues[ 1 ] = "gene";
         unitsValues[ 2 ] = "clone";

      } else if ( map_type == "AGI" ) {
         unitsDisplay = new Array( 5 );
         unitsDisplay[ 0 ] = "kb";
         unitsDisplay[ 1 ] = "marker";
	 unitsDisplay[ 2 ] = "locus";
	 unitsDisplay[ 3 ] = "AGI clone";
	 unitsDisplay[ 4 ] = "other clone"

	// AGI clone will map to AssemblyUnit table
	// locus will search gene w/special logic (see src.search.Units)
         unitsValues = new Array( 5 );
         unitsValues[ 0 ] = "kb";
         unitsValues[ 1 ] = "marker";
         unitsValues[ 2 ] = "locus";
	 unitsValues[ 3 ] = "AGI clone";
	 unitsValues[ 4 ] = "clone"
      } 


      updateMenu( document.searchForm.low_unit, unitsDisplay, unitsValues );
      updateMenu( document.searchForm.high_unit, unitsDisplay, unitsValues );
      document.searchForm.low_unit.selectedIndex = 0;
      document.searchForm.high_unit.selectedIndex = 0;

      // if sort by not yet explicitly selected, default to position
      if ( sortSelected == false ) {
	for ( i = 0; i < document.searchForm.order.options.length; i++ ) {
           if ( document.searchForm.order.options[ i ].value == "position" ) {
              document.searchForm.order.options[ i ].selected = true;
	   } else {
              document.searchForm.order.options[ i ].selected = false;
	   }		
	}	
      }
}     


// keep track if sort by explicitly selected - use flag to make choice
// of whether to default to position when map type selected
var sortSelected = false;

// select AGI map by default if sort by position is chosen
function checkPosition() {
	var sortBy = document.searchForm.order.options[ document.searchForm.order.selectedIndex ].value;

	// set flag 
	sortSelected = true;

      	if ( sortBy == "position" ) {
 	   var mapChecked = false;
	   if ( document.searchForm.map_type.length > 0 ) {
	       for ( i = 0; i < document.searchForm.map_type.length; i++ ) {
	       	 if ( document.searchForm.map_type[ i ].checked == true ) {
                    mapChecked = true;
                    break;
                 }
	       }
           } else {
	      if ( document.searchForm.map_type.checked == true ) {
	  	    mapChecked = true;
	      }	
	   }
	}

        if ( mapChecked == false ) {
	    if ( document.searchForm.map_type.length > 0 ) {
	         for ( i = 0; i < document.searchForm.map_type.length; i++ ) {
                   if ( document.searchForm.map_type[ i ].value == "AGI" ) {
		       document.searchForm.map_type[ i ].checked = true;
	           }
		 }	
	    } else {
	      if ( document.searchForm.map_type.value == "AGI" ) {
  		       document.searchForm.map_type.checked = true;
	      }	
            }

	    updateUnits( "AGI" );
        }
}


// if "around" range is selected, populate high_range field with "--unused--" since it's not used
function checkRange() {
	var selectedRange = document.searchForm.range_type.options[ document.searchForm.range_type.selectedIndex ].value;

	if ( selectedRange == "around" ) {
		document.searchForm.high_range.value = "--unused--";
	} else if ( selectedRange == "between" ) {
	      	if ( document.searchForm.high_range.value == "--unused--" ) {
			document.searchForm.high_range.value = "";
		}
	}	

}
