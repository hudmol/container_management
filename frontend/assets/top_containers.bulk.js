function BulkContainerSearch($search_form, $results_container, $toolbar) {
  this.$search_form = $search_form;
  this.$results_container = $results_container;
  this.$toolbar = $toolbar;

  this.setup_form();
  this.setup_results_list();
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

  $.ajax({
    url:"/plugins/top_containers/bulk_operations/search",
    data: data,
    type: "post",
    success: function(html) {
      self.$results_container.closest(".row-fluid").show();
      self.$results_container.html(html);
      self.setup_table_sorter();
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
    var $checkbox = $(this);
    var $row = $checkbox.closest("tr");
    $row.toggleClass("selected");

    self.update_button_state();
  });

  self.$results_container.on("click", "td", function(event) {
    $(this).closest("tr").find(":checkbox").trigger("click");
  });
};

BulkContainerSearch.prototype.update_button_state = function() {
  var self = this;

  if ($("tbody :checkbox:checked", self.$results_container).length > 0) {
    self.$toolbar.find(".btn").removeClass("disabled").removeAttr("disabled");
  } else {
    self.$toolbar.find(".btn").addClass("disabled").attr("disabled", "disabled");
  }
};

BulkContainerSearch.prototype.setup_table_sorter = function() {
  var tablesorter_opts = {
    // disable sort on the checkbox column
    headers: {
      0: { sorter: false}
    },
    // default sort: Collection, Series, Indicator
    sortList: [[1,0],[2,0],[4,0]]
  };
  this.$results_container.find("table").tablesorter(tablesorter_opts);
};


$(function() {

  new BulkContainerSearch($("#bulk_operation_form"),
                          $("#bulk_operation_results"),
                          $(".record-toolbar.bulk-operation-toolbar"));

});