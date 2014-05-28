$(document).ready () ->
  $("#show-instructions").on "click", () ->
    if $('#instructions').height() == 0
      $('#instructions').animate
        height: $('#instructions')[0].scrollHeight+'px'
      , 500
      $(this).css("-webkit-transition","0.2s ease")
      $(this).css("-webkit-transform","rotate(90deg)")
    else
      $('#instructions').animate
        height: '0px'
      , 500 
      $(this).css("-webkit-transition","0.2s ease")
      $(this).css("-webkit-transform","rotate(0deg)")
    return

  window.graph = new Graph
  window.graphUI = new Graph.vis(graph,$('#graph'))
  window.graph = graph
  window.graphUI = graphUI
  graph.addNode(null,null).d3.html = 'Click me<br>to edit text'
  child1 = graph.addNode(null,0)
  child1.d3.html = 'Child 1'
  graph.addNode(null,0).d3.html = '<i class="fa fa-arrow-left"></i> Drag me onto Child 1'  
  newroot = graph.addNode(null,child1.id)
  newroot.d3.html = 'Drag me into<br>a blank area'
  graph.addNode(null,newroot.id).d3.html = 'Click me, then<br>click the <i class="fa fa-plus-circle"></i>'
  graph.addNode(null,newroot.id)
  graph.addNode(null,child1.id).d3.html = 'Drag me<br>into the <i class="fa fa-trash-o">'
  graphUI.redraw()

  # The following are all jQuery event handlers for graphical interactions.

  ######################
  # EDITING NODE CONTENT
  ######################

  # Enable node content editing when clicked
  $(document).on "click", ".node", (e) ->
    $(this).attr "contenteditable", "true"
    return true

  # Adjust position of nodes as content is dynamically edited
  # TODO: Set a limit on how many times per second to do this so that it
  # doesn't slow down typing.
  $(document).on "input", ".node", (e) ->
    id = parseInt($(this).attr("data-id"))
    graph.node(id).d3.html = $(this).html()
    graphUI.reposition graphUI.graph.vis
    graphUI.redraw()
    return true

  # Turn off node content editing mode when node loses focus.
  $(document).on "blur", ".node", (e) ->
    $(this).attr "contenteditable", "false"
    return true

  ##############
  # ADDING NODES
  ##############

  # Create an add node button when single-clicked.
  $(document).on "click", ".node", (e) ->
    id = $(this).attr("data-id")
    # Hide any other add buttons.
    $(".add-node-btn").not("[data-id=#{id}]").fadeOut(100)
    # Get the .node-container for this .node
    container = $(this).parent()
    # If there is no button for this node, create one.
    if $(container).find(".add-node-btn").length == 0  
      button = $("<i></i>")
        .attr("class", "add-node-btn fa fa-plus-circle")
        .attr("data-id",id)
        .hide()
      $(container).append(button)
    # Show the button
    $(container).find(".add-node-btn").fadeIn(250)

  # Hide node button when svg canvas is clicked
  $(document).on "click", "#graph svg", (e) ->
    $(".add-node-btn").fadeOut(100)
    $(".node").attr("contenteditable","false")

  # Add a node
  $(document).on "click", ".add-node-btn", (e) ->
    node = parseInt($(this).attr("data-id"))
    graph.addNode("?", node)
    graphUI.redraw()

  #####################
  # DRAG-DROPPING NODES
  #####################

  # This is needed to allow for drag-dropping.
  $(document).on "dragover", (e) ->
    e.preventDefault()
    return false

  # Drag a node
  $(document).on "dragstart", ".node", (e) ->
    e.originalEvent.dataTransfer.setData("text/plain", $(this).attr("data-id"));
    return

  # Make trashcan red on dragover
  $(document).on "dragenter", ".fa-trash-o", (e) ->
    console.log "dragenter"
    $(this).addClass("dragover")
  $(document).on "dragleave", ".fa-trash-o", (e) ->
    $(this).removeClass("dragover")

  # Drop a node on the trashcan
  $(document).on "drop", ".fa-trash-o", (e) ->
    e.preventDefault()
    dragged = parseInt(e.originalEvent.dataTransfer.getData("text/plain"))
    deleteAll = (id)->
      node = graph.node(id)
      if node.children.length > 0
        deleteAll child for child in node.children
      graph.removeNode(id)
    deleteAll(dragged)
    # For aesthetics, we instantly remove the visible link between the node and it's parent.
    d3.selectAll("#graph line[data-child='#{dragged}']").remove()
    graphUI.redraw()
    setTimeout () ->
      $("#trashcan").removeClass("dragover")
    , 500
    return

  # Drop a node on a blank part of the blank svg canvas
  $(document).on "drop", "body", (e) ->
    e.stopPropagation()
    e.preventDefault()
    dragged = parseInt(e.originalEvent.dataTransfer.getData("text/plain"))
    graph.moveNode(dragged,null)  if dragged isnt null
    # For aesthetics, we remove the link. Otherwise, the link flies to the 
    # trash, and that might startle users.
    console.log d3.selectAll("#graph line[data-child='#{dragged}']")
    d3.selectAll("#graph line[data-child='#{dragged}']").remove()
    graphUI.redraw()
    return

  # Drop a node onto another node
  $(document).on "drop", ".node", (e) ->
    e.stopPropagation()
    e.preventDefault()
    dragged = parseInt(e.originalEvent.dataTransfer.getData("text/plain"))
    dest = parseInt($(this).attr("data-id"))
    # Sanity checks - TODO: add more
    if dragged == dest then return # Accidental drag. Dropped on self.
    graph.moveNode(dragged, dest) if dragged isnt null
    graphUI.redraw()
    return