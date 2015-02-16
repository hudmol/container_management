//= require form

$(function () {
	var init = function () {
	    $('#top_container_override_restricted_').on('click', function (event) {
		    event.stopPropagation();
		    if ($(this).is(":checked")) {
			$('#top_container_restricted_').removeAttr("disabled");
		    } else {
			$('#top_container_restricted_').attr("disabled", "disabled");;
		    }
		});
	};

	init();
    });
