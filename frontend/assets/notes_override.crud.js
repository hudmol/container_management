$(document).ready(function() {

  function setupRightsRestrictionNoteFields($subform) {
    var noteJSONModelType = $subform.data("type");

    if (noteJSONModelType == "note_multipart") {
      var toggleRightsFields = function() {
        var noteType = $(".note-type option:selected", $subform).val();
        var $restriction_fields = $("#notes_restriction", $subform);;

        if (noteType == "accessrestrict" || noteType == "userestrict") {
          $(":input", $restriction_fields).removeAttr("disabled");
          $restriction_fields.show();
        } else {
          $(":input", $restriction_fields).attr("disabled", "disabled");
          $restriction_fields.hide();
        }
      }

      $(".note-type", $subform).on("change", function() {
        toggleRightsFields();
      });

      toggleRightsFields();
    }
  }


  $(document).bind("subrecordcreated.aspace", function(event, jsonmodel_type, $subform) {
    if (jsonmodel_type == "note") {
      setupRightsRestrictionNoteFields($subform);
    }
  });


  $("section.notes-form.subrecord-form .subrecord-form-fields").each(function() {
    setupRightsRestrictionNoteFields($(this));
  });

});