function BulkActionBarcodeRapidEntry() {
  this.TEMPLATE_DIALOG_ID = "template_bulk_barcode_action_dialog";
  this.TEMPLATE_MENU_ID = "template_bulk_action_barcodes_menu_item";

  this.initMenuItem();
};


BulkActionBarcodeRapidEntry.prototype.initMenuItem = function() {
  var self = this;

  self.$menuItem = AS.yale_containers.bulkContainerSearch.add_menu_item(AS.renderTemplate(self.TEMPLATE_MENU_ID));

  self.$menuItem.on("click", function(event) {
    self.show();
  });
};


BulkActionBarcodeRapidEntry.prototype.show = function() {
  var dialog_content = AS.renderTemplate(this.TEMPLATE_DIALOG_ID, {
    selection: AS.yale_containers.bulkContainerSearch.get_selection()
  });
  AS.openCustomModal("bulkActionBarcodeRapidEntryModal", this.$menuItem.text(), dialog_content, "full");
};


$(function() {
  AS.yale_containers.bulkActionBarcodeRapidEntry = new BulkActionBarcodeRapidEntry(AS.yale_containers.bulkContainerSearch);
});
