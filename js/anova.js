/** 
* ANOVA analysis
* Isaak Y Tecle <iyt2@cornell.edu>
*
*/


jQuery(document).ready( function() { 
  
    var url = document.URL;
 
    if (url.match(/\/breeders_toolbox\/trial|breeders\/trial|\/solgs\/population\//)) {
	    allowAnova();  
	} 

});


function allowAnova () {
  
    checkDesign();
  
}


function checkDesign () {
    
    var trialId = getTrialId();  
    
    jQuery.ajax({
        type: 'POST',
        dataType: 'json',
	data: {'trial_id': trialId},
        url: '/anova/check/design/',      
        success: function(response) {
	     
	    if (response.Error) {
		showMessage(response.Error);
		jQuery("#run_anova").hide();
	    } else {
		  
		listAnovaTraits();
	    }
        },
        error: function(response) {                          
            showMessage("Error occured running the ANOVA.");	    	
	    jQuery("#run_anova").show();
        }                
    });

}


jQuery(document).ready(function () {
    jQuery(document).on("click", "#run_anova", function() {        
   
	var traitId    =  jQuery("#anova_selected_trait_id").val();
	
	if (traitId) {

	    queryPhenoData(traitId);
   
	    jQuery("#run_anova").hide();

	    showMessage("Running anova analysis...");
	} else {
	    var msg = 'You need to select a trait first.'
	    anovaAlert(msg);
	}
               
    });

});


function anovaAlert(msg) {

    	jQuery('<div />')
	.html(msg)
	    .dialog({
		modal  : true,
		title  : 'Alert',
		buttons: {
		    OK: {
			click: function () {
			    jQuery(this).dialog('close');		
			},
			class: 'btn btn-success',
			text : 'OK',
		    },
		}			
	    });	    
    

}

function queryPhenoData(traitId) {

    var trialId = getTrialId();
   
    jQuery.ajax({
        type: 'POST',
        dataType: 'json',
	data: {'trial_id': trialId, 'traits_ids': [traitId]},
        url: '/anova/phenotype/data/',      
        success: function(response) {
	 	    
	    if (response.Error) {
		showMessage(response.Error);
		jQuery("#run_anova").show();
	    } else {
		var traitsAbbrs = response.traits_abbrs;
		runAnovaAnalysis(traitsAbbrs);
	    }
        },
        error: function(response) {                          
            showMessage("Error occured running the ANOVA.");	    	
	    jQuery("#run_anova").show();
        }                
    });
}


function showMessage (msg) {
     jQuery("#anova_message")
        .css({"padding-left": '0px'})
        .html(msg);
    
}


function runAnovaAnalysis(traits) {
 
    var trialId = getTrialId();
   
    var captions       = jQuery('#anova_table table').find('caption').text();		
    var analyzedTraits = captions.replace(/ANOVA result:/g, ' '); 

    for (var i = 0; i < traits.length; i++) {
	var traitAbbr = traits[i].trait_abbr;

	if (analyzedTraits.match(traitAbbr) == null) {
	    var anovaTraits = JSON.stringify(traits);

	    jQuery.ajax({
		type: 'POST',
		dataType: 'json',
		data: {'trial_id': trialId, 'traits': [anovaTraits]},
		url: '/anova/analysis/',      
		success: function(response) {
		    
		    if (response) {		
			var anovaTable = response.anova_html_table;			
		   	
			jQuery("#anova_table").append('<div style="margin-top: 20px">' + anovaTable + '</div>').show();
		
			var anovaFile = response.anova_table_file;
			var modelFile = response.anova_model_file;
			var meansFile = response.adj_means_file;

			var fileNameAnova = anovaFile.split('/').pop();
			var fileNameModel = modelFile.split('/').pop();
			var fileNameMeans = meansFile.split('/').pop();
		
			
			anovaFile = "<a href=\"" + anovaFile +  "\" download=" + fileNameAnova + ">[Anova table]</a>";
			modelFile = "<a href=\"" + modelFile +  "\" download=" + fileNameModel + ">[Model Summary]</a>";
			meansFile = "<a href=\"" + meansFile +  "\" download=" + fileNameMeans + ">[Adjusted Means]</a>";
		
			jQuery("#anova_table")
			    .append('<br /> <strong>Download:</strong> ' + anovaFile + ' | ' + modelFile + ' | ' + meansFile)
			    .show();
			
			jQuery("#anova_message").empty();
			
			jQuery("#run_anova").show();
		    } else {
			showMessage("There is no anova output for this dataset."); 		
			jQuery("#run_anova").show();
		    }

		    clearTraitSelection();
		},
		error: function(response) {                          
		    showMessage("Error occured running the anova analysis.");	    	
		    jQuery("#run_anova").show();
		    clearTraitSelection();
		}                
	    });
	} else {
	    jQuery("#anova_message").empty();
	    jQuery("#run_anova").show();
	    clearTraitSelection();
	}
    }

}


function listAnovaTraits ()  {

    var trialId = getTrialId();

     jQuery.ajax({
        type: 'POST',
        dataType: 'json',
	data: {'trial_id': trialId},
        url: '/anova/traits/list/',      
        success: function(response) {
	    formatAnovaTraits(response.anova_traits);
	    jQuery("#run_anova").show();	
	  
        },
        error: function(response) {                          
            showMessage("Error occured listing anova traits.");	    	
	    jQuery("#run_anova").show();
        }                
    });

   
}

function formatAnovaTraits(traits) {
    
    var traitsList = '';
   
    for (var i = 0; i < traits.length; i++) {
	var traitName = traits[i].trait_name;

	var idName = JSON.stringify(traits[i]);
	traitsList +='<li>'
        + '<a href="#">' + traitName + '<span class=value>' + idName + '</span></a>'
        + '</li>';
    }
   
    var  traitsList =  '<dl id="anova_selected_trait" class="anova_dropdown">'
        + '<dt> <a href="#"><span>Select a trait</span></a></dt>'
        + '<dd>'
        + '<ul>'
        + traitsList
	+ '</ul></dd></dl>'; 
   
    jQuery("#anova_select_a_trait_div").empty().append(traitsList).show();
      
    jQuery(".anova_dropdown dt a").click(function() {
        jQuery(".anova_dropdown dd ul").toggle();
    });
                 
    jQuery(".anova_dropdown dd ul li a").click(function() {
      
        var text = jQuery(this).html();
           
        jQuery(".anova_dropdown dt a span").html(text);
        jQuery(".anova_dropdown dd ul").hide();
                
        var traitIdName = jQuery("#anova_selected_trait").find("dt a span.value").html();
        traitIdName     = JSON.parse(traitIdName);
      
        var traitId   = traitIdName.trait_id;
        var traitName = traitIdName.trait_name;

        console.log('id ' + traitId + ' name ' + traitName)

        jQuery("#anova_selected_trait_name").val(traitName);
        jQuery("#anova_selected_trait_id").val(traitId);
                               
    });
                       
    jQuery(".anova_dropdown").bind('click', function(e) {
        var clicked = jQuery(e.target);
               
        if (!clicked.parents().hasClass("anova_dropdown"))
            jQuery(".anova_dropdown dd ul").hide();

        e.preventDefault();

	
    });   
        
}


function clearTraitSelection () {

    jQuery("#anova_selected_trait_name").val('');
    jQuery("#anova_selected_trait_id").val('');

}


function getTrialId () {
    
    var trialId    =  jQuery("#trial_id").val();

    if (!trialId) {

	trialId = jQuery("#population_id").val();
    }

    return trialId;

}
