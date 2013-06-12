// Helper function that populates type-specific form fields for each search and
// submits form. The form types include the TAIR search, Google search, or
// Aracyc/Plantcyc search. Call this as the action on the search field.
function doSearch(form, selectedType, google_form, aracyc_form, name_value, contains, exact) {
    // Set up type-specific fields.
    if ( selectedType == "google" ) {
        form = google_form;
        form.q.value = name_value;

    //else check if it is plantcyc or aracyc website
    } else if (selectedType == "aracyc") {
        form = aracyc_form;        
        form.object.value = name_value;    
    
    // else populate form for searching TAIR db
    } else {

        // if selectedType is "any", set action to "search" to search
        // all datatypes using "exact" match. Else set action to "detail"
        // to search selected type using "contains"
        // will always show a show_obsolete == F, whether the page does something with it
        // depends on the particular Searcher (ie: GeneSearcher, GeneralSearcher)
        if ( selectedType == "any" ) {
            form.search_action.value = "search";
            form.method.value = exact;
            form.show_obsolete.value = "F";
        } else {
            form.search_action.value = "detail";
            form.method.value = contains;
            form.show_obsolete.value = "F";
        }
   }
   form.submit();
   return false;
}

