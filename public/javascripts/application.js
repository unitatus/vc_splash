// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function SetAllCheckBoxes(FormName, FieldName, CheckValue)
{
	if(!document.forms[FormName])
		return;
	var objCheckBoxes = document.forms[FormName].elements[FieldName];
	if(!objCheckBoxes)
		return;
	var countCheckBoxes = objCheckBoxes.length;
	if(!countCheckBoxes)
		objCheckBoxes.checked = CheckValue;
	else
		// set the check value for all check boxes
		for(var i = 0; i < countCheckBoxes; i++)
			objCheckBoxes[i].checked = CheckValue;
}

submit_counter = 0
function formMonitor(obj)
{	
	submit_counter++;
	if (submit_counter > 1) {
		return false;
	}
	else {
		return true;
	}
}

function addressSelected(radio_field_name, hidden_div_name)
{
	if (document.getElementById(radio_field_name).checked)
		document.getElementById(hidden_div_name).style.display = 'block'
	else
		document.getElementById(hidden_div_name).style.display = 'none'
}

function ToggleIndexingLock()
{
	document.forms['box_form'].elements['marked_for_indexing'].checked = document.forms['box_form'].elements['marked_for_indexing_locked'].checked;
	document.forms['box_form'].elements['marked_for_indexing'].disabled = document.forms['box_form'].elements['marked_for_indexing_locked'].checked;
}

function toggleBoxCountSelect()
{
	placeholder = document.getElementById("vc_boxes").style.display

	document.getElementById("vc_boxes").style.display = document.getElementById("cust_boxes").style.display
	document.getElementById("cust_boxes").style.display = placeholder
}

function showTagsForm(storedItemId)
{
	link_div = 'add_tags_link_' + storedItemId;
	form_div = 'add_tags_form_' + storedItemId;
	form_name = 'tags_form_' + storedItemId
	
	document.getElementById(link_div).style.display = 'none';
	document.getElementById(form_div).style.display = 'block'; // This seems to show it
	document.getElementById(form_name).elements["tag"].focus();
}

function validateTagForm() {
	if (document.forms["tags_form"]["tag"].value.length > 255) {
		alert("Max length is 255 characters");
		return false;
	} else {
		return true;
	}
}

function hideTagsForm(storedItemId)
{
	link_div = 'add_tags_link_' + storedItemId;
	form_div = 'add_tags_form_' + storedItemId;
	
	document.getElementById(link_div).style.display = 'block';
	document.getElementById(form_div).style.display = 'none';	
}

function removeElement(parentDiv, childDiv)
{
     if (childDiv == parentDiv) {
          alert("The parent div cannot be removed.");
     }
     else if (document.getElementById(childDiv)) {     
          var child = document.getElementById(childDiv);
          var parent = document.getElementById(parentDiv);

          parent.removeChild(child);
     }
     else {
          alert("Child div has already been removed or does not exist.");
          return false;
     }
}

function utcToLocal(value) {
	var a = /^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})\sUTC$/.exec(value);

    if (a) {
		parsed_date = new Date(Date.UTC(+a[1], +a[2] - 1, +a[3], +a[4], +a[5], +a[6]));
        return parsed_date.toString("MMMM dd, yyyy hh:mm tt ");
    }

    return null;
}

function toggleHIWMenu() {
	if((navigator.userAgent.match(/iPhone/i)) || (navigator.userAgent.match(/iPod/i)) || (navigator.userAgent.match(/iPad/i))) {	
		hiw_submenu = document.getElementById("hiw_submenu")
	
		hiw_submenu.style.top = (hiw_submenu.style.top == "30px" ? "-999em" : "30px");
		hiw_submenu.style.zIndex = (hiw_submenu.style.zIndex == "9999" ? "0" : "9999");
	}
    else
    {
        window.location = "/how_it_works";
    }
}

function getObjectClass(obj) {
    if (obj && obj.constructor && obj.constructor.toString) {
        var arr = obj.constructor.toString().match(
            /function\s*(\w+)/);

        if (arr && arr.length == 2) {
            return arr[1];
        }
    }

    return undefined;
}

$(document).ready(function(){
	// Fades store/portfolio link overlays
	
	jQuery('.thumbnails .post-thumbnail').hover( function () {
		jQuery(this).find('ul').css('display','inline').animate({opacity: 0}, 0).stop().animate({opacity: 1}, 300);
	}, function () {
		jQuery(this).find('ul').stop().animate({opacity: 0}, 300);
	});
	
	// Start Capacitr
    $('.browse-box .browse-box-menu').hover(
          function () {
            $($(this)).find("div").show();
          }, 
          function () {
            $($(this)).find("div").hide();
          }
    );
    // 
    // $('.browse-item-menu').hover(
    //       function () {
    //         $($(this)).find("div").toggle();
    //       }, 
    //       function () {
    //         $($(this)).find("div").toggle();
    //       }
    // );

	    $('.browse-item-menu').mouseover(
	          function () {
	            $($(this)).find("div").toggle();
	          }
	    );
    
		    $('.browse-item-menu').mouseout(
		          function () {
		            $($(this)).find("div").toggle();
		          }
		    );

    $('.browse-item-menu-link').click(
          function () {
            $($(this)).parent().find("div").mouseover();
          }
    );

    $('.increment-up').click(function(){
        oldVal = parseInt($($(this)).parent().find("input").attr('value'));
        $($(this)).parent().find("input").attr('value',oldVal+1)
    });
    
    $('.increment-down').click(function(){
        oldVal = parseInt($($(this)).parent().find("input").attr('value'));
        if(oldVal>0){
        $($(this)).parent().find("input").attr('value',oldVal-1)
        }
    });
    
    $('#pricing .price-box .nav li a').click(function(){ 
        $($(this)).parent().parent().find(".active").removeClass('active');
        whichOne = $($(this)).parent().attr('class');
        $($(this)).parent().parent().parent().parent().find("#box1").hide();
        $($(this)).parent().parent().parent().parent().find("#box2").hide();
        $($(this)).parent().parent().parent().parent().find("#box3").hide();
        $($(this)).parent().parent().parent().parent().find("#box4").hide();
		if (whichOne == "box4") {
			$($(this)).parent().parent().parent().parent().find("#price-box-viewer").addClass('viewer-onebox');
		} else {
			$($(this)).parent().parent().parent().parent().find("#price-box-viewer").removeClass('viewer-onebox');
		}
        $($(this)).parent().parent().parent().parent().find("#"+whichOne).show();
        $($(this)).parent().addClass('active');
        return false;
    });
    
    $('#pricing .price-box input[type=checkbox]').change(function(){
        sansInvValue = $($(this)).parent().parent().parent().parent().find("#sans_inv").attr('value');
		withInvValue = $($(this)).parent().parent().parent().parent().find("#with_inv").attr('value');
        var n = $($(this)).parent().find(":checked").length;
        if(n>0){
            formattedValue = withInvValue;
	        $($(this)).parent().parent().parent().parent().find("strong").text(formattedValue);
	        // $($(this)).parent().parent().parent().find(".to-strike").css('text-decoration','none');
        }else{
            formattedValue = sansInvValue;
	        $($(this)).parent().parent().parent().parent().find("strong").text(formattedValue);
	        // $($(this)).parent().parent().parent().find(".to-strike").css('text-decoration','line-through');
        }
    });
    
    $('.chooser').click(function(){
        $(".our-boxes").hide();
        $(".your-boxes").hide();
        whichOne = $($(this)).attr('id');
        $("."+whichOne).show();
        $('#choosebox').find('.active').removeClass('active');
        $($(this)).addClass('active');
        return false;
    });
    
    $('#inventory-menu-rightarrow').click(function(){
        if($('#inventory-menu-rightarrow').hasClass('enabled')){
            $('#inventory-menu-rightarrow').removeClass('enabled');
            boxCount = $("#inventory-boxcanvas").find(".inventory-boxdisplay-box").length;
            curPos = $("#inventory-boxcanvas").position().left;
            boxSize = 120;
            if(curPos > 0-((boxCount*boxSize)-(5*boxSize))){
                $("#inventory-boxcanvas").animate({
                    left: '-='+boxSize
                  }, 1000, function() {
                    $('#inventory-menu-rightarrow').addClass('enabled');
                    $('#inventory-menu-leftarrow').removeClass('disabled');
                    boxCount = $("#inventory-boxcanvas").find(".inventory-boxdisplay-box").length;
                    curPos = $("#inventory-boxcanvas").position().left;
                    if(curPos <= 0-((boxCount*boxSize)-(5*boxSize))){
                        $('#inventory-menu-rightarrow').addClass('disabled');
                    }
                  });
            }else{
                $('#inventory-menu-rightarrow').addClass('enabled');
            }
        }
    });
    
    $('#inventory-menu-leftarrow').click(function(){
        if($('#inventory-menu-leftarrow').hasClass('enabled')){
            $('#inventory-menu-leftarrow').removeClass('enabled');
            boxCount = $("#inventory-boxcanvas").find(".inventory-boxdisplay-box").length;
            curPos = $("#inventory-boxcanvas").position().left;
            boxSize = 120;
            if(curPos < 0){
                $("#inventory-boxcanvas").animate({
                    left: '+='+boxSize
                  }, 1000, function() {
                    $('#inventory-menu-leftarrow').addClass('enabled');
                    $('#inventory-menu-rightarrow').removeClass('disabled');
                    boxCount = $("#inventory-boxcanvas").find(".inventory-boxdisplay-box").length;
                    curPos = $("#inventory-boxcanvas").position().left;
                    if(curPos >= 0){
                        $('#inventory-menu-leftarrow').addClass('disabled');
                    }
                  });
            }else{
                $('#inventory-menu-leftarrow').addClass('enabled');
            }
        }
    });
    
    boxCount = $("#inventory-boxcanvas").find(".inventory-boxdisplay-box").length;
    boxSize = 120;
    widthCalc = boxSize * boxCount;
    $("#inventory-boxcanvas").css('width',widthCalc);
    whichActive = $('#inventory-boxdisplay').find(".activebox").index()+1;
    offsetMax = boxCount-5
    if(offsetMax<0){
        offsetMax=0;
    }

    if (whichActive > 5){
        offsetCalc = offsetMax*boxSize;
    }else{
        offsetCalc = 0;
    }

    $("#inventory-boxcanvas").animate({
        left: '-='+offsetCalc
      }, 1000, function() {
        $('#inventory-menu-leftarrow').addClass('enabled');
        $('#inventory-menu-rightarrow').addClass('enabled');
        curPos = $("#inventory-boxcanvas").position().left;
        if(curPos != 0){
            $('#inventory-menu-leftarrow').removeClass('disabled');
        }
        if(curPos == 0-((boxCount*boxSize)-(5*boxSize))){
            $('#inventory-menu-rightarrow').addClass('disabled');
        }
        if(boxCount<=5){
            $('#inventory-menu-rightarrow').addClass('disabled');
        }
      });

	// This code exists because IE does not handle the placeholder attribute
	function switchText()
	{
		if ($(this).val() == $(this).attr('placeholder'))
			$(this).val('').removeClass('exampleText');
		else if ($.trim($(this).val()) == '')
			$(this).addClass('exampleText').val($(this).attr('placeholder'));
	}

	$('input[type=text][placeholder!=""]').each(function() {
		if ($.trim($(this).val()) == '') $(this).val($(this).attr('placeholder'));
		if ($(this).val() == $(this).attr('placeholder')) $(this).addClass('exampleText');
	}).focus(switchText).blur(switchText);

	$('form').submit(function() {
		$(this).find('input[type=text][placeholder!=""]').each(function() {
			if ($(this).val() == $(this).attr('placeholder')) $(this).val('');
		});
	});
	// end IE work-around for placeholder

///////////////////////Start Fancybox

	$("#member_agreement_link").fancybox({
        'width': 665, 
        'height': 500, 
        'autoDimensions': false, 
		ajax : {
		    type	: "GET"
		}
	});
	
	
	$("a.grouped_images_class").fancybox({
		'transitionIn'	:	'fade',
		'transitionOut'	:	'fade',
		'speedIn'		:	1000, 
		'speedOut'		:	200, 
		'overlayShow'	:	true,
		'autoDimensions': true,
		'autoScale'			: true,
		'centerOnScroll'	: true,
		'cyclic'			: true,
		'scrolling'			: 'no'
	});

	$("#cf_explainer_link_1").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 350,
		'height': 50
	});
	
	$("#cf_explainer_link_2").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 350,
		'height': 50
	});
	
	$("#cf_explainer_link_3").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 350,
		'height': 50
	});
	
	$("#cf_explainer_link_4").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 350,
		'height': 50
	});
	
	$("#cf_explainer_link_5").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 350,
		'height': 50
	});
	
	$("#cf_explainer_link_6").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 350,
		'height': 50
	});
	
	$("#cf_explainer_link_7").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 350,
		'height': 50
	});
	
	$("#cf_explainer_link_8").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 350,
		'height': 50
	});
	
	$("#cf_explainer_link_9").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 350,
		'height': 50
	});
	
	$("#cf_explainer_link_10").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 350,
		'height': 50
	});
	
	$("#co_inv_link").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 650,
		'height': 200
	});
	
	$("#vc_product_link").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none'
	});
	
	$("#checkout_plan_link").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 600,
		'height': 150
	});

	$("#cc_expl_link").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 600,
		'height': 100
	});

	$("#discount_synopsis_link").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 600,
		'height': 300
	});
	
	$("#pricing_link").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 400,
		'height': 55
	});
	
	$("#cust_product_link").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'autoDimensions': false, 
		'width': 600,
		'height': 125,
		'transitionOut'		: 'none'
	});
	
	$("#cvv_link").fancybox({
		'width'				: '75%',
		'height'			: '75%',
		'autoScale'			: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'type'				: 'iframe'
	});
	
	$("#first_box_return_link").fancybox();
	
	$("#first_item_processing_link").fancybox();
	
	$("#explain_invalid_address_link").fancybox();
	
	$("#explain_tbd_shipping_link").fancybox();
	
	$("#edit_cc_number_link").fancybox({
		'titleShow'		: false,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 400,
		'height': 100
	});
	
	$("#pricing_explainer_link").fancybox({
		'titleShow'		: true,
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'autoDimensions': false, 
		'width': 600,
		'height': 400
	});
	
	/************ Autocomplete **************/
	$('#tags').bind('railsAutocomplete.select', function(event, data){
	    document.forms['tags_search'].submit();
	});

});
