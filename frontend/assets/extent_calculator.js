$(function () {

	var init = function () {
	    $('.extent-calculator-btn').on('click', function (event) {
		    event.stopImmediatePropagation();
		    event.preventDefault();

		    var dialog_content = AS.renderTemplate("extent_calculator_show_calculation_template", {
			    results: "moo"
			});

		    var $modal = AS.openCustomModal("extentCalculationModal", "Extent Calculation", dialog_content, 'full');

		    var $form = $modal.find("form");

		    $.ajax({
			    url:"/plugins/extent_calculator/",
				data: {record_uri: $("#extent_calculator_show_calculation_template").attr("record_uri")},
				type: "get",
				success: function(html) {
				$("#show_calculation_results").html(html);
			    },
				error: function(jqXHR, textStatus, errorThrown) {
				alert("boo");
			    }
			});
		});

	}
	if ($('.extent-calculator-btn').length > 0) {
	    init();
	} else {
	    $(document).bind("loadedrecordform.aspace", init);
	}

    });
