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

  # Trashcan detection code
  intrash = (el)->
    el_x = $(el).offset().left
    el_y = $(el).offset().top
    trash_x = $(".trashcan").offset().left + $(".trashcan").width()
    trash_y = $(".trashcan").offset().top + $(".trashcan").height()
    el_x < trash_x and el_y < trash_y

  # Time to pull out the big guns!
  $(document).on "mousedown", ".node", (e) ->
    # TODO: remove graphUI part, rely on closure
    graphUI.dragged = parseInt($(this).attr("data-id"))
    p = $('#graph').position()
    startx = e.originalEvent.pageX-p.left
    starty = e.originalEvent.pageY-p.top
    # Start dragging
    dragstart = false
    $(document).on "mousemove.drag", (e) ->
      e.preventDefault()
      # e.stopPropagation()
      # Get cursor position relative to #graph
      p = $('#graph').position()
      x = e.originalEvent.pageX-p.left
      y = e.originalEvent.pageY-p.top
      # Threshold
      threshold = 10 #px
      dist = Math.sqrt((x-startx)*(x-startx) + (y-starty)*(y-starty))
      if dist < threshold and not dragstart
        return
      else
        dragstart = true
        $(".node[data-id=#{graphUI.dragged}]").attr 'contenteditable', 'false'

      # Draw node in new location.
      child = graph.node(graphUI.dragged)
      graphUI.drawNodeAt(child.id, x-startx, y-starty)

      if intrash(".node[data-id=#{graphUI.dragged}]")
        $(".trashcan").addClass("dragover")
        graphUI.dropParent = null
        $("#graph .edge[data-child=#{child.id}]")
          .attr("x1", (d) -> child.d3.x+x-startx)
          .attr("y1", (d) -> child.d3.y+y-starty)
        return
      else
        $(".trashcan").removeClass("dragover")

      # Find nearest node that is above the cursor
      dist = (d)->
        Math.sqrt(Math.pow(d.d3.x - x,2) + Math.pow(d.d3.y - y,2))
      candidates = (node for node in graph._nodes when Math.abs(node.d3.y - y + graphUI.h) < graphUI.h/2)
      # candidates = (node for node in candidates when dist(node) < 150)
      candidates = (node for node in candidates when not graph.isDescendent(graphUI.dragged,node.id))
      # Nothing nearby
      if candidates.length == 0 
        graphUI.dropParent = null
        $("#graph .edge[data-child=#{child.id}]")
          .attr("x1", (d) -> child.d3.x+x-startx)
          .attr("y1", (d) -> child.d3.y+y-starty)
        return

      dists = (dist(node) for node in candidates)
      min_dist = Math.min(dists...)
      min_idx = dists.indexOf(min_dist)
      nearest = candidates[min_idx]
      graphUI.dropParent = nearest.id
      # Nearest to itself
      if graphUI.dropParent != graphUI.dragged 
        parent = graph.node(graphUI.dropParent)
        # This fixes the occasional flickering "Can't Drop Here" bug
        y = y - 5
        $("#graph .edge[data-child=#{child.id}]")
          .attr("x1", (d) -> parent.d3.x)
          .attr("y1", (d) -> parent.d3.y)
        angle = (x1,y1,x2,y2)->
          rise = y1 - y2
          run  = x1 - x2
          Math.atan2(rise, run)
        angleNode = (child, parent)->
          return angle(child.d3.x, child.d3.y, parent.d3.x, parent.d3.y)
        child = graph.node(graphUI.dragged)
        parent = graph.node(graphUI.dropParent)
        mouse_angle = angle(child.d3.x+x-startx, child.d3.y+y-starty, parent.d3.x, parent.d3.y)
        children_to_the_left = (child for child in parent.children when angleNode(graph.node(child),parent) > mouse_angle and child isnt graphUI.dragged)
      return true

    # Stop dragging
    $(document).on "mouseup", (e) ->
      # Remove handler
      $(document).off "mousemove.drag"
      $(".node[data-id=#{graphUI.dragged}]").attr 'contenteditable', 'true'
      # Do stuff
      if dragstart
        # Do drag drop             
        dragstart = false   
        e.stopPropagation()
        e.preventDefault()
        # Get cursor position relative to #graph
        p = $('#graph').position()
        x = e.originalEvent.pageX-p.left
        y = e.originalEvent.pageY-p.top
        if graphUI.dropParent is null
          # For aesthetics, we instantly remove the visible link between the node and it's parent
          # so it doesn't fly to the trash, which might startle users.
          d3.selectAll("#graph line[data-child='#{graphUI.dragged}']").remove()
          # Did we drop it in the trash?
          if intrash(".node[data-id=#{graphUI.dragged}]")
            deleteAll = (id)->
              node = graph.node(id)
              if node.children.length > 0
                deleteAll child for child in node.children
              graph.removeNode(id)
            deleteAll(graphUI.dragged)
            setTimeout () ->
              $("#trashcan").removeClass("dragover")
            , 500
          else
            graph.moveNode(graphUI.dragged, graphUI.dropParent)
          graphUI.redraw()
          return
        else
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
          child = graph.node(graphUI.dragged)
          parent = graph.node(graphUI.dropParent)
          mouse_angle = angle(child.d3.x+x-startx, child.d3.y+y-starty, parent.d3.x, parent.d3.y)
          children_to_the_left = (child for child in parent.children when angleNode(graph.node(child),parent) > mouse_angle and child isnt graphUI.dragged)
          insert_at = children_to_the_left.length
          # Move node
          graph.moveNode(graphUI.dragged, graphUI.dropParent, insert_at)
        graphUI.redraw()
        graphUI.dragged = null
        return
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