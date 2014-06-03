$(document).ready () ->
  window.graph = new Graph
  window.graphUI = new Graph.vis(graph,$('#graph'))
  window.graph = graph
  window.graphUI = graphUI
  graph.addNode(null,null).d3.html = 'Root Node'
  child1 = graph.addNode(null,0)
  child1.d3.html = 'Child 1'
  child2 = graph.addNode(null,0)
  child2.d3.html = '<i class="fa fa-arrow-left"></i> Drag me under Child 1'  
  graph.addNode(null,child2.id).d3.html = 'Click me<br>to edit text'
  newroot = graph.addNode(null,child1.id)
  newroot.d3.html = 'Drag me above<br>the Root Node'
  graph.addNode(null,newroot.id).d3.html = 'Click me, then<br>click the <i class="fa fa-plus-circle"></i>'
  graph.addNode(null,newroot.id)
  graph.addNode(null,child1.id).d3.html = 'Drag me<br>into the <i class="fa fa-trash-o">'
  graphUI.redraw()

  # The following are all jQuery event handlers for graphical interactions.

  ########################
  # SHOW/HIDE INSTRUCTIONS
  ########################
  $("#show-instructions").on "click", () ->
    if $('#instructions').height() == 0
      $('#instructions').animate
        height: $('#instructions')[0].scrollHeight+'px'
      , 500
      $(this).addClass("rotate90")
    else
      $('#instructions').animate
        height: '0px'
      , 500 
      $(this).removeClass("rotate90")
    return
    
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
  $(document).on "keyup", ".node", (e) ->
    id = parseInt($(this).attr("data-id"))
    graph.node(id).d3.html = $(this).html()
    graphUI.redraw()
    return true

  # Turn off node content editing mode when node loses focus.
  $(document).on "blur", ".node", (e) ->
    $(this).attr "contenteditable", "false"
    graphUI.redraw()
    return true

  ##############
  # ADDING NODES
  ##############
  # Create an add node button when single-clicked.
  $(document).on "click", ".node", (e) ->
    e.stopPropagation();
    e.preventDefault();
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

  # Unselect the node when something else is clicked.
  $(document).on "click", "body", (e) ->
    # e.stopPropagation();  # BAD! VERY BAD. BROKE CLICKING <input type="file">
    # e.preventDefault();
    $(".add-node-btn").fadeOut(100)
    $(".node").attr("contenteditable","false")

  # Add a node
  $(document).on "click", ".add-node-btn", (e) ->
    e.stopPropagation()
    e.preventDefault()
    node = parseInt($(this).attr("data-id"))
    graph.addNode("?", node)
    graphUI.redraw()

  #####################
  # DRAG-DROPPING NODES
  #####################
  # This is needed to allow for drag-dropping.
  $(document).on "dragover", (e) ->
    e.preventDefault()
    e.stopPropagation()
    return false

  # Drag a node
  $(document).on "dragstart", ".node", (e) ->
    graphUI.dragged = parseInt($(this).attr("data-id"))
    data = {dragged: graphUI.dragged}
    setData e, data
    return

  $(document).on "dragover", "body", (e) ->
    e.preventDefault()
    e.stopPropagation()
    # Get cursor position relative to #graph
    p = $('#graph').position()
    x = e.originalEvent.clientX-p.left
    y = e.originalEvent.clientY-p.top
    # Find nearest node that is above the cursor
    # Add some fudge factor (25) ... we mean "really" above, not just slightly. Slightly above are probably siblings.
    candidates = (node for node in graph._nodes when node.d3.y < y - 25)
    candidates = (node for node in candidates when not graph.isDescendent(graphUI.dragged,node.id))
    # Nothing nearby
    if candidates.length == 0 
      graphUI.dropParent = null
      graphUI.drawAux([])
      return
    dists = (Math.pow(node.d3.x - x,2) + Math.pow(node.d3.y - y,2) for node in candidates)
    min_dist = Math.min(dists...)
    min_idx = dists.indexOf(min_dist)
    nearest = candidates[min_idx]
    graphUI.dropParent = nearest.id
    # Nearest to itself
    if graphUI.dropParent != graphUI.dragged 
      parent = graph.node(graphUI.dropParent)
      child = graph.node(graphUI.dragged)
      # This fixes the occasional flickering "Can't Drop Here" bug
      y = y - 5
      # Draw line from cursor to node.
      auxline = 
        d3:
          parent:
            oldx: parent.d3.oldx
            oldy: parent.d3.oldy
            x:    parent.d3.x
            y:    parent.d3.y
          child:
            oldx: x
            oldy: y
            x:    x
            y:    y
      graphUI.drawAux([auxline])
    else
      graphUI.drawAux([])
    return true

  # Delete auxillary lines
  $(document).on "dragend", "body", (e) ->
    graphUI.drawAux([])

  # Make trashcan red on dragover
  $(document).on "dragenter", ".fa-trash-o", (e) ->
    console.log "dragenter"
    $(this).addClass("dragover")
    graphUI.dropParent = null
    graphUI.drawAux([])
  $(document).on "dragleave", ".fa-trash-o", (e) ->
    $(this).removeClass("dragover")

  $(document).on "dragover", ".trashcan", (e) ->
    e.stopPropagation();
    e.preventDefault();

  # Drop a node on the trashcan
  $(document).on "drop", ".fa-trash-o", (e) ->
    e.stopPropagation()
    e.preventDefault()
    deleteAll = (id)->
      node = graph.node(id)
      if node.children.length > 0
        deleteAll child for child in node.children
      graph.removeNode(id)
    deleteAll(graphUI.dragged)
    # For aesthetics, we instantly remove the visible link between the node and it's parent.
    d3.selectAll("#graph line[data-child='#{graphUI.dragged}']").remove()
    graphUI.redraw()
    setTimeout () ->
      $("#trashcan").removeClass("dragover")
    , 500
    return

  # Move a node when the node is dropped
  $(document).on "drop", "body", (e) ->
    e.stopPropagation()
    e.preventDefault()
    # Get cursor position relative to #graph
    p = $('#graph').position()
    x = e.originalEvent.clientX-p.left
    y = e.originalEvent.clientY-p.top
    console.log graphUI.dragged
    console.log graphUI.dropParent
    # Sanity checks
    if graphUI.dragged == graphUI.dropParent then return
    if graph.isDescendent(graphUI.dragged, graphUI.dropParent) then return
    # OK, proceed.
    # Find where among the children to insert it.
    # Find all children to the right of the mouse. ^H^H^H
    # No, that doesn't actually work intuitively. We need the angle the children's lines
    # make with their parent so we know which rays the cursor is in between.
    angle = (x1,y1,x2,y2)->
      rise = y1 - y2
      run  = x1 - x2
      Math.atan2(rise, run)
    angleNode = (child, parent)->
      return angle(child.d3.x, child.d3.y, parent.d3.x, parent.d3.y)
    parent = graph.node(graphUI.dropParent)
    mouse_angle = angle(x,y,parent.d3.x,parent.d3.y)
    children_to_the_right = (child for child in parent.children when angleNode(graph.node(child),parent) < mouse_angle)
    # Get the index to insert it at.
    if children_to_the_right.length == 0
      insert_at =  parent.children.length
    else
      insert_before = children_to_the_right[0]
      insert_at = parent.children.indexOf(insert_before) 
    # Handle off by one error
    if graph.node(graphUI.dragged).parent == graphUI.dropParent then insert_at--
    # Move node
    graph.moveNode(graphUI.dragged, graphUI.dropParent, insert_at)
    if graphUI.dropParent is null
      # For aesthetics, we remove the link so it doesn't fly to the trash, which might startle users.
      d3.selectAll("#graph line[data-child='#{graphUI.dragged}']").remove()
    graphUI.redraw()
    return

  ###########################
  # SAVING AND LOADING GRAPHS
  ###########################
  $("#download").on "click", (e) ->
    text = graph.toJSON()
    blob = new Blob([text], {type: 'text/plain;charset=utf-8'})
    saveAs(blob, 'graph.json')

  $("#upload").on "click", (e) ->
    $(this).hide()
    $("#file-chooser").show()

  $("#file-chooser").on "change", (e) ->
    f = e.target.files[0]
    reader = new FileReader()
    reader.onload = (e)->
      # TODO: Error handling?
      graph.loadJSON(e.target.result)
      graphUI.redraw()
    reader.readAsText(f)
    $(this).hide()
    resetFormElement(this)
    $("#upload").show()
    
# http://stackoverflow.com/a/13351234/2168416
resetFormElement = (el)->
  $(el).wrap('<form>').closest('form').get(0).reset()
  $(el).unwrap()

setData = (e,obj) ->
  e.originalEvent.dataTransfer.setData("text", JSON.stringify(obj));

getData = (e) ->
  JSON.parse(e.originalEvent.dataTransfer.getData("text"))