//= require jquery
//
//= require angular
//= require_self
//= require_tree ./templates
//= require_tree ./controllers
//= require_tree ./directives
//
//= require lib/jquery.easing


app = angular.module("app", ["templates"])

$(function() {
  var editionTab   = $("#edition-tab"),
      sectionTab   = $("#section-tab"),
      editionPanel = $("#edition-tab-panel"),
      sectionPanel = $("#section-tab-panel"),
      editionCancel= $(".cancel", editionPanel),
      sectionCancel= $(".cancel", sectionPanel);

  editionPanel.hide();
  sectionPanel.hide();

  editionTab.click(function(){
    sectionTab.removeClass('active')
    sectionPanel.hide()

    editionTab.toggleClass('active');
    editionPanel.toggle();
  });

  sectionTab.click(function(){
    editionTab.removeClass('active')
    editionPanel.hide()

    sectionTab.toggleClass('active');
    sectionPanel.toggle();
  });

  editionCancel.click(function(e) {
    e.preventDefault();

    editionTab.removeClass('active')
    editionPanel.hide()
  });

  sectionCancel.click(function(e) {
    e.preventDefault();

    sectionTab.removeClass('active')
    sectionPanel.hide()
  });

  captureAuthenticityToken = function() {
    return $("input[name=authenticity_token]").first().val();
  }


  var addSection  = $('.add-section'),
      sectionsNav = $('.sections-nav'),
      authenticityToken = captureAuthenticityToken();

  var postForm = function(action, method, input) {
    var form;
    form = $('<form />', {
        action: action,
        method: method,
        style: 'display: none;'
    });
    if (typeof input !== 'undefined') {
      $.each(input, function (name, value) {
        $('<input />', {
          type: 'hidden',
          name: name,
          value: value
        }).appendTo(form);
      });
    }
    form.appendTo('body').submit();
  }

  var createPage = function(sectionID, opts) {
    // TODO: Do we need to be passing in the sectionID in two places?
    postForm("/sections/" + sectionID + "/pages", "post", { authenticity_token: authenticityToken });
  }


  // Handle Add Section Click
  addSection.click(function(e){
    e.preventDefault();
    e.stopPropagation();

    var input = $(" <input class='section-nav-input' type='text'></input> ");
    addSection.before(input);

    addSection.hide();

    link = $("<a href=''></a>");
    span = $(" <span class='section-nav-input-span for-size'></span> ");
    span.html(link);
    addSection.before(span);
    span.addClass('for-sizing');

    input.focus();

    var cancel = function() {
      input.remove();
      span.remove();
    }

    var createSection = function(editionID, sectionName, opts) {
      // TODO: Do we need to be passing in the editionID in two places?
      var url         = "/editions/" + editionID + "/sections";
      var sectionPath = sectionName + ".html"
      $.ajax({
        type: "POST",
        url: url,
        data: {
          authenticity_token: authenticityToken,
          section: {
            name: sectionName,
            path: sectionPath,
            sequence: 10,
            edition_id: editionID
          }
        },
        dataType: 'json'
      });
    }

    $document = $(document);
    var submit = function() {
      var sectionName = input.val();
      if (sectionName == '') {
        cancel();
      } else {
        var value = input.val();

        input.remove()

        link.html(value);
        link.attr({'href': value + ".html"});

        span.removeClass('for-sizing');

        addSection.before(" "); // Induce proper spacing.
        addSection.show();

        createSection(composer.editionID, sectionName);
      }
    }

    var resize = function() {
      // Measure Invisible Span.
      link.text(input.val());
      input.css({'width': link.width() + 15 + 'px'});
    }

    // ESC to Cancel, Enter to submit.
    $(input).keyup(function(e){
      switch(e.keyCode) {
        case 27: // ESC
          cancel();
          break;
        case 13: // ENTER
          submit();
          break;
        default:
          resize();
      }
    });

  });

  $(".add-page-btn").click(function() {
    createPage(composer.sectionID); // Temp solution, should be pulling this from the dom and using a directive.
  });

  var composerModal = $(".composer-modal");

  $(".add-content-btn").click(function() {
    var pageID = $(this).data("page-id");

    var form = $("form", composerModal);

    var pageIDInput = $("[name='content_region[page_id]']");
    pageIDInput.val(pageID);
    console.log(pageIDInput.val());

    // Set hidden form field values

    composerModal.removeClass("hidden")

    //var createContentRegion = function(sectionID, pageNumber, params) {
      //$.extend(params, {
        //sectionID: sectionID,
        //pageNumber: pageNumber,
        //authenticity_token: authenticityToken
      //});
      //postForm("/content_regions", "post", params);
    //}
      //createContentRegion(sectionID, pageNumber, params); // Temp solution, should be pulling this from the dom and using a directive.
  });

  $(".composer-modal-dismiss").click(function(){
    composerModal.addClass("hidden");
  });

})
