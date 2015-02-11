function BulkContainerSearch($search_form, $results_container, $toolbar) {
  this.$search_form = $search_form;
  this.$results_container = $results_container;
  this.$toolbar = $toolbar;

  this.setup_form();
  this.setup_results_list();
  this.setup_bulk_action_update_ils_holding();
  this.setup_bulk_action_delete();
}

function BulkContainerUpdate($update_form) {
  this.$update_form = $update_form;

  this.setup_update_form();
}

BulkContainerSearch.prototype.setup_form = function() {
  var self = this;

  this.$search_form.on("submit", function(event) {
    event.preventDefault();
    self.perform_search(self.$search_form.serializeArray());
  });
};

BulkContainerSearch.prototype.perform_search = function(data) {
  var self = this;

  self.$results_container.closest(".row-fluid").show();
  self.$results_container.html(AS.renderTemplate("template_bulk_operation_loading"));

  $.ajax({
    url:"/plugins/top_containers/bulk_operations/search",
    data: data,
    type: "post",
    success: function(html) {
      self.$results_container.html(html);
      self.setup_table_sorter();
      self.update_button_state();
    },
    error: function(jqXHR, textStatus, errorThrown) {
      var html = AS.renderTemplate("template_bulk_operation_error_message", {message: jqXHR.responseText})
      self.$results_container.html(html);
      self.update_button_state();
    }
  });
};

BulkContainerSearch.prototype.setup_results_list = function(docs) {
  var self = this;

  self.$results_container.on("click", "#select_all", function(event) {
    var $checkbox = $(this);
    if ($checkbox.is(":checked")) {
      $("tbody :checkbox:not(:checked)", self.$results_container).trigger("click");
    } else {
      $("tbody :checkbox:checked", self.$results_container).trigger("click");
    }
  });

  self.$results_container.on("click", ":checkbox", function(event) {
    event.stopPropagation();

    var $checkbox = $(this);
    var $row = $checkbox.closest("tr");
    $row.toggleClass("selected");
    var $first_row_state = $row[0].className

    if (event.altKey) {
	$row = $row.prev();
	while ($row[0] != null && $row[0].className != $first_row_state) {
	    $row.find(":checkbox").click();
	    $row = $row.prev();
	}
    }

    self.update_button_state();
  });

  self.$results_container.on("click", "td", function(event) {
    $(this).closest("tr").find(":checkbox").trigger("click");
  });
};

BulkContainerSearch.prototype.update_button_state = function() {
  var self = this;
  var checked_boxes = $("tbody :checkbox:checked", self.$results_container);
  var delete_btn = self.$toolbar.find(".btn");

  if (checked_boxes.length > 0) {
    var selected_records = $.makeArray(checked_boxes.map(function() {return $(this).val();}));
    delete_btn.data("form-data", {
      record_uris: selected_records
    });
    delete_btn.removeClass("disabled").removeAttr("disabled");
  } else {
    delete_btn.data("form-data", {});
    delete_btn.addClass("disabled").attr("disabled", "disabled");
  }
};

BulkContainerSearch.prototype.setup_table_sorter = function() {
  var tablesorter_opts = {
    // only sort on the second row of header columns
    selectorHeaders: "thead tr.sortable-columns th",
    // disable sort on the checkbox column
    headers: {
        0: { sorter: false}
    },
    // default sort: Collection, Series, Indicator
    sortList: [[1,0],[2,0],[4,0]],
    // customise text extraction to pull only the first collection/series
    textExtraction: function(node) {
      var $node = $(node);

      if ($node.hasClass("top-container-collection")) {
        return $node.find(".collection-identifier:first").text().trim();
      } else if ($node.hasClass("top-container-series")) {
        var level = $node.find(".series-level:first").text().trim();
        var identifier = $node.find(".series-identifier:first").text().trim();

        if ((level+identifier).length > 0) {
          return level + "-" + identifier;
        } else {
          return "";
        }
      }

      return $node.text().trim();
    }
  };
  this.$results_container.find("table").tablesorter(tablesorter_opts);
};

BulkContainerSearch.prototype.get_selection = function() {
  var self = this;
  var results = [];

  self.$results_container.find("tbody :checkbox:checked").each(function(i, checkbox) {
    results.push({
      uri: checkbox.value,
      display_string: $(checkbox).data("display-string"),
      row: $(checkbox).closest("tr")
    });
  });

  return results;
};

BulkContainerSearch.prototype.add_menu_item = function(menuItemHtml) {
  return $($(menuItemHtml).appendTo($("#bulkActions ul.dropdown-menu", this.$toolbar))[0]);
};


BulkContainerSearch.prototype.setup_bulk_action_update_ils_holding = function() {
  var self = this;
  var $link = $("#bulkActionUpdateIlsHolding", self.$toolbar);

  $link.on("click", function() {
    AS.openCustomModal("bulkUpdateModal", "Update ILS Holding IDs", AS.renderTemplate("bulk_action_update_ils_holding", {
      selection: self.get_selection()
    }), 'full')
  });
};

BulkContainerSearch.prototype.setup_bulk_action_delete = function() {
  var self = this;
  var $link = $("#bulkActionDelete", self.$toolbar);

  $link.on("click", function() {
    var updateUris = self.get_selection().map(function(c) { return c[0] });
    AS.openCustomModal("bulkActionModal", "Delete Top Containers", AS.renderTemplate("bulk_action_delete", {
      selection: self.get_selection(),
      updateUris: updateUris
    }), 'full')
  });
};

BulkContainerUpdate.prototype.setup_update_form = function() {
  var self = this;

  this.$update_form.on("submit", function(event) {
    event.preventDefault();
    self.perform_update(self.$update_form.serializeArray());
  });
};

BulkContainerUpdate.prototype.perform_update = function(data) {
  var self = this;

  $.ajax({
	  url:"/plugins/top_containers/bulk_operations/update",
	      data: data,
	      type: "post",
	      success: function(html) {
	      $('#alertBucket').replaceWith(html);
	  },
	      error: function(jqXHR, textStatus, errorThrown) {
	      $('#alertBucket').replaceWith('<div id="alertBucket" class="alert alert-error">' + jqXHR.responseText + '</div>');
	  }
      });
};


$(function() {

  AS.yale_containers = {};
  AS.yale_containers.bulkContainerSearch = new BulkContainerSearch(
                                                  $("#bulk_operation_form"),
                                                  $("#bulk_operation_results"),
                                                  $(".record-toolbar.bulk-operation-toolbar"));

});
