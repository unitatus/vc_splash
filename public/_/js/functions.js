// CONFIGURATION OPTIONS
// ***********************************************
// Change to the date of your site launch
// 
var year    = 2011;
var month   = 8;
var day     = 1;

// Don't Change below this line unless you know what you are doing.

var launch_date = new Date(year, month-1, day);
var message_delay = 2000;


// remap jQuery to $
(function($){
    
    $('#style_menu').hover(function() {
        $('#style_menu .color_options').fadeIn('slow');
    }, function() {
        $('#style_menu .color_options').fadeOut('slow');
    });
    
    // Create countdown using jquery.countdown plugin
    $('div.countdown').countdown({
        until: launch_date,
        layout: '<span class="countdown_section first"><span class="countdown_amount">{dn}</span><br />{dl}</span><span class="countdown_section"><span class="countdown_amount">{hn}</span><br />{hl}</span><span class="countdown_section"><span class="countdown_amount">{mn}</span><br />{ml}</span><span class="countdown_section last"><span class="countdown_amount">{sn}</span><br />{sl}</span>'
    });

    // Placeholder text fallback
    $('#sender_email').defaultValue();

    // Add last-child attributes.
    $('span.countdown_section:last').css('margin-right', '0');
    
    // Ajax form processing
    $( init );

    function init() {
        $('#notification-email').submit( submitForm ); 
    }

    function submitForm() {
        var contact_form = $( this );
        var sender_email = $('#sender_email');
        var filter = /^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$/;

        // Are all fields filled in?
        if ( !$(sender_email).val() ) { 
            $('#incomplete-message').fadeIn('slow').delay(message_delay).fadeOut('slow');
        } else if ( !filter.test(sender_email.val()) ) { 
            $('#invalid-email').fadeIn('slow').delay(message_delay).fadeOut('slow');
        } else {

            $.ajax( {
                url:      contact_form.attr( 'action' ) + "?ajax=true",
                type:     contact_form.attr( 'method' ),
                data:     contact_form.serialize(),
                success:  submit_finished
            });
        }
        return false;
    }

    function submit_finished( response ) {
        response = $.trim( response );

        if ( response == "success" ) { 
            $('#success-message').fadeIn('slow').delay(message_delay).fadeOut('slow');
            $('#sender_email').val("");
        } else {
            $('#failure-message').fadeIn('slow').delay(message_delay).fadeOut('slow');
        };
    }


})(window.jQuery);
