$(document).foundation();
	
/*
(function($, window) {
  $.fn.replaceOptions = function(options) {
    var self, $option;

    this.empty();
    self = this;

    $.each(options, function(index, option) {
      $option = $("<option></option>")
        .attr("value", option.value)
        .text(option.text);
      self.append($option);
    });
  };
})(jQuery, window);
*/

function fetchCategories() {
	//alert("fetching categories");

	$.ajax({
		
		url: "/api/categories",
		processData: true,
		data: {},
		dataType: "json",
		success: processCategories,
		error: function(x,y,z) {
		// x.responseText should have what's wrong
			alert("error:"+x.responseText);
		}
	});

};

function processCategories(data) {
	console.log( "success: " );
	
		$('#category_selection').empty();
		$.each(data.categories, function(index, option) {
			optionTag = $("<option></option>").attr("value", option.name).text(option.label)
			$('#category_selection').append(optionTag)
		});
	
}


function fetchResources() {
	$.ajax({
		url:"/api/resources",
		processData: true,
		data:{},
		dataType: "json",
		success: processResources,
		error: function(x,y,z) {
			alert("error:"+y+" for: "+x.responseText)
		}
	});
}

function processResources(data) {
	
	$.each(data.resources, function(index, res) {
		displayhtml = '<div class="row"> <div class="large-12 columns "> <span class="primary callout large-8 columns" ><strong>'+res.name+'</strong></span><a href="#" id="'+res.id+'" class="small-4 columns alert button float-right edit_btn">Edit Btn</a></div><div class="large-12 columns edit_form"></div></div>';
		displayResource = $(displayhtml);
        
		$('#main').append(displayResource);
	});
}

function loadEditForm(event) {
	formroot = $(event.currentTarget).parent().siblings(".edit_form")
	formroot.load('/yres_basic/edit_reference_ajax.html', function() {
		$.ajax({
			url:"/api/resource/"+event.currentTarget.id,
			processData: true,
			data:{},
			dataType: "json",
			success: setupEditResourceForm,
			error: function(x,y,z) {
				alert("error:"+y+" for: "+x.responseText)
			}
		});
		
	});
	
}

function saveCategoryCheck(event) {
    
    catid = $(event.currentTarget)[0].value;
    cattask = $(event.currentTarget)[0].checked;
    resid = $("input[name=id]").val()
    if(cattask == true){
        operation = "add"
    } else {
        operation = "remove"
    }
    $.ajax({
           url:"/admin/resource_cat/"+resid,
           processData: true,
           method: "post",
           data:{"catid":catid, "resid":resid, "operation":operation},
           dataType: "json",
           success: null,
           error: function(x,y,z) {
           alert("error:"+y+" for: "+x.responseText)
           }
        });
}

function setupEditResourceForm(data, resourceform) {
	console.log("resourceform data received"+data)
	resource = data.resource;
	formroot = $("#"+resource.id).parent().siblings(".edit_form");
	formroot.childNodes("ref_name").value(resource.name);
}

function setupEditPage() {
    $("body").on("click", ".category_list", saveCategoryCheck);
}

function setupPage() {
	$("body").on("click", ".category_list", saveCategoryCheck);
	fetchCategories();
	//fetchResources();
}

setupPage();
