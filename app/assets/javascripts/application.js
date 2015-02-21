// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require foundation
//= require jquery-ui/datepicker
//= require turbolinks
//= require_tree .

$(document).on("page:load ready", function(){

	if ( $('[type="date"]').prop('type') != 'date' ) {
    $('input[type="date"]').datepicker({dateFormat: "yy-mm-dd"});
	}

	$('#event_from_date').change(function() {
		if ($('#event_end_date').val().length != 0 && $('#event_from_date').val().length != 0)  {
			if ($('#event_end_date').val() <= $('#event_from_date').val()) {
				$('#event_from_date').val("");
				$('p.alert').text("From Date must be before End Date.");
			} else {
				$('p.alert').text("");
			}
		}
	});

	$('#event_end_date').change(function() {
		if (this.val().length != 0 && $('#event_from_date').val().length != 0)  {
			if (this.val() <= $('#event_from_date').val()) {
				this.value = "";
				$('p.alert').text("From Date must be before End Date.");
			} else {
				$('p.alert').text("");
			}
		}
	});

	$('#item_exchange_rate').keyup(function () {
		if ( $('#item_foreign_amount').val().length != 0 ) {
			$('#item_base_amount').val( this.value * $('#item_foreign_amount').val() );
		}
	});

	$('#item_foreign_amount').keyup(function () {
		if ( $('#item_exchange_rate').val().length != 0 ) {
			$('#item_base_amount').val( this.value * $('#item_exchange_rate').val() );
		}
	});

});

$(function(){ $(document).foundation(); });
