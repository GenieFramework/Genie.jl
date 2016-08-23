
var articleEditor;

$(function() {
  testEditor = editormd("article_editormd", {
    height: 740,
    path : '/vendor/',
    pluginPath : "/vendor/editormd/plugins/",
    mode: "gfm",
    codeFold : true,
    saveHTMLToTextarea : true,
    searchReplace : true,
    htmlDecode : "style,script,iframe|on*",
    emoji : true,
    taskList : true,
    tocm : true,
    tex : true,
    flowChart : false,
    sequenceDiagram : false,
    imageUpload : false,
    imageFormats : ["jpg", "jpeg", "gif", "png", "bmp", "webp"],
    // imageUploadURL : "./php/upload.php",
    tabSize : 2,
    indentUnit : 2,
    onload : function() {
    }
  });

  $("#goto-line-btn").bind("click", function(){
    testEditor.gotoLine(90);
  });

  $("#show-btn").bind('click', function(){
    testEditor.show();
  });

  $("#hide-btn").bind('click', function(){
    testEditor.hide();
  });

  $("#get-md-btn").bind('click', function(){
    alert(testEditor.getMarkdown());
  });

  $("#get-html-btn").bind('click', function() {
    alert(testEditor.getHTML());
  });

  $("#watch-btn").bind('click', function() {
    testEditor.watch();
  });

  $("#unwatch-btn").bind('click', function() {
    testEditor.unwatch();
  });

  $("#preview-btn").bind('click', function() {
    testEditor.previewing();
  });

  $("#fullscreen-btn").bind('click', function() {
    testEditor.fullscreen();
  });

  $("#show-toolbar-btn").bind('click', function() {
    testEditor.showToolbar();
  });

  $("#close-toolbar-btn").bind('click', function() {
    testEditor.hideToolbar();
  });

  $("#toc-menu-btn").click(function(){
    testEditor.config({
      tocDropdown   : true,
      tocTitle      : "Table of Contents",
    });
  });

  $("#toc-default-btn").click(function() {
    testEditor.config("tocDropdown", false);
  });
});