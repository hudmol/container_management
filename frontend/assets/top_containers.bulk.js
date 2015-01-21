function BulkContainerSearch($search_form, $results_container) {
  this.$search_form = $search_form;
  this.$results_container = $results_container;

  this.setupForm();
}

BulkContainerSearch.prototype.setupForm = function() {
  var self = this;

  this.$search_form.on("submit", function(event) {
    event.preventDefault();
    self.perform_search(self.$search_form.serializeArray());
  });
};

BulkContainerSearch.prototype.perform_search = function(data) {
  var self = this;

  $.ajax({
    url:"/plugins/top_containers/bulk_operations/search.json",
    data: data,
    type: "post",
    success: function(json) {
      self.$results_container.closest(".row-fluid").show();
      self.render_results(json.response.docs);
    }
  })
};

BulkContainerSearch.prototype.render_results = function(docs) {
  var self = this;

  self.$results_container.empty();
  $.each(docs, function(i, doc) {
    var real_json = JSON.parse(doc.json);
    var foo = AS.renderTemplate("template_bulk_operation_result", real_json);
    self.$results_container.append(foo);
  });
};

$(function() {

  new BulkContainerSearch($("#bulk_operation_form"), $("#bulk_operation_results"));

});