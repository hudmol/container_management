$(document).ready(function() {
  $(document).bind("loadedrecordform.aspace", function(event, $container) {
    //$("section.notes-form.subrecord-form:not(.initialised)", $container).init_notes_form();
    if ($("section.notes-form.subrecord-form:not(.initialised)", $container).length > 0) {
      console.log("loadedrecordform.aspace");
      console.log($container);
    }
  });

  console.log($("section.notes-form.subrecord-form:not(.initialised)").length);
  //$("section.notes-form.subrecord-form:not(.initialised)").init_notes_form();
});