function BulkActionBarcodeRapidEntry(bulkContainerSearch) {
  this.TEMPLATE_DIALOG_ID = "template_bulk_barcode_action_dialog";
  this.TEMPLATE_MENU_ID = "template_bulk_action_barcodes_menu_item";

  this.bulkContainerSearch = bulkContainerSearch;

  this.initMenuItem();
};


BulkActionBarcodeRapidEntry.prototype.initMenuItem = function() {
  var self = this;

  self.$menuItem = self.bulkContainerSearch.add_menu_item(AS.renderTemplate(self.TEMPLATE_MENU_ID));

  self.$menuItem.on("click", function(event) {
    self.show();
  });
};


BulkActionBarcodeRapidEntry.prototype.show = function() {
  var dialog_content = AS.renderTemplate(this.TEMPLATE_DIALOG_ID, {
    selection: this.bulkContainerSearch.get_selection()
  });
  var $modal = AS.openCustomModal("bulkActionBarcodeRapidEntryModal", this.$menuItem.text(), dialog_content, "full");

  this.setup_keyboard_handling($modal);
};


BulkActionBarcodeRapidEntry.prototype.setup_keyboard_handling = function($modal) {
  $modal.find(":input:first").focus().select();

  $(":input", $modal).
    on("focus",
      function() {
        $(this).ScrollTo({duration: 0});
      }).
    on("keyup",
      function(event) {
        if (event.keyCode == 13) {
          $(":input", $(this).closest("tr").next()).focus().select();
        }
      }
    );
};


$(function() {
  AS.yale_containers.bulkActionBarcodeRapidEntry = new BulkActionBarcodeRapidEntry(AS.yale_containers.bulkContainerSearch);
});
