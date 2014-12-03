$(document).ready(function() {
  var $form = $("#new_yale_container_form");

  function resetAllForms() {
    $("#container_top_level .subrecord-form-fields", $form).html(
      AS.renderTemplate("template_yale_container_top_level", {
        path: "yale_container_hierarchy[yale_container_1]",
        id_path: "yale_container_hierarchy_yale_container_1",
        index: 0,
        name: "yale_container_1"
      })
    );
    $("#container_child_1 .subrecord-form-fields", $form).html(
      AS.renderTemplate("template_yale_container_child", {
        path: "yale_container_hierarchy[yale_container_2]",
        id_path: "yale_container_hierarchy_yale_container_2",
        index: 0,
        name: "yale_container_2"
      })
    );
    $("#container_child_2 .subrecord-form-fields", $form).html(
      AS.renderTemplate("template_yale_container_child", {
        path: "yale_container_hierarchy[yale_container_3]",
        id_path: "yale_container_hierarchy_yale_container_3",
        index: 0,
        name: "yale_container_3"
      })
    );
  };

  function setupForms(yaleContainer) {
    // Find out what containers we have to work with...
    var container_1, container_2, container_3;

    if (yaleContainer.hasOwnProperty("parent")) {
      if (yaleContainer.parent._resolved.hasOwnProperty("parent")) {
        // 3 levels!
        container_1 = yaleContainer.parent._resolved.parent._resolved;
        container_2 = yaleContainer.parent._resolved;
        container_3 = yaleContainer;
      } else {
        // 2 levels!
        container_1 = yaleContainer.parent._resolved;
        container_2 = yaleContainer;
      }
    } else {
      // 1 level!
      container_1 = yaleContainer;
    }

    // Output hidden inputs for those already in the hierarchy
    if (container_1) {
      $("#container_top_level .subrecord-form-fields", $form).html(
        AS.renderTemplate("template_yale_container_ref", {
          path: "yale_container_hierarchy",
          id_path: "yale_container_hierarchy",
          index: 1,
          name: "yale_container_1",
          yale_container: container_1
        })
      );
    }
    if (container_2) {
      $("#container_child_1 .subrecord-form-fields", $form).html(
        AS.renderTemplate("template_yale_container_ref", {
          path: "yale_container_hierarchy",
          id_path: "yale_container_hierarchy",
          index: 2,
          name: "yale_container_2",
          yale_container: container_2
        })
      );
    }
    if (container_3) {
      $("#container_child_2 .subrecord-form-fields", $form).html(
        AS.renderTemplate("template_yale_container_ref", {
          path: "yale_container_hierarchy",
          id_path: "yale_container_hierarchy",
          index: 3,
          name: "yale_container_3",
          yale_container: container_3
        })
      );
    }
  };

  var $linker = $("#yale_container_hierarchy_ref_");

  function setupFormsFromLinker() {
    if ($linker.val() != "") {
      var selectedYaleContainerJSON = $linker.tokenInput("get")[0];
      var recordJSON = JSON.parse(selectedYaleContainerJSON.json.json)

      setupForms(recordJSON);
    }
  }


  $linker.on("change", function(event) {
    resetAllForms();

    setupFormsFromLinker();
  });

  setTimeout(function() {
    setupFormsFromLinker();
  });
});