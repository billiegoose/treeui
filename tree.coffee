# Tree UI - CoffeeScript Version

# The original code used a tree data structure.
# We are going to use a directed graph data structure.
class window.Graph
  class @Node 
    constructor: (@id) ->
      # Core required properties: id, parent, children
      @parent = null
      @children = []
      # d3 visual properties
      @d3 =
        html: '?'
        x: null
        y: null
      # Abstract data properties (suggested)
      @data =
        token: null
        value: null

  class @Link 
    constructor: (@child, @parent) ->
      # Core required properties: child, parent
      # d3 visual properties
      @d3 = 
        child:
          x: null
          y: null
        parent:
          x: null
          y: null

  # Really we just want to discourage people from modifying the array accidentally
  nodes: =>
    return @_nodes.slice(0)

  node: (id) =>
    nodes = (node for node in @_nodes when node.id is id)
    switch nodes.length
      when 0 then throw "No node found matching id: " + id
      when 1 then return nodes[0]
      else
        console.log nodes
        throw "Multiple nodes matched id: " + id

  addNode: (data, parent) =>
    node = new Graph.Node
    node.id = @_nextid++ # Auto-increment
    node.data = data       # Store AST data
    @_nodes.push(node)
    if parent? then @_link(node.id,parent)
    return node

  moveNode: (id, newparent) =>
    oldparent = @node(id).parent
    if oldparent? then @_unlink(id, oldparent)
    if newparent? then @_link(id, newparent)
    return true

  removeNode: (id) =>
    # Note: If you don't use list comprehensions, but try to use .map and .filter,
    # you run into trouble where `this.removeLink` is no longer in the scope.
    @_unlink link.child, link.parent for link in @_links when (link.parent is id or link.child is id)
    @_nodes = (node for node in @_nodes when node.id isnt id)
    return true

  leaves: =>
    return (node for node in @_nodes when node.children.length is 0)

  roots: =>
    return (node for node in @_nodes when node.parent is null)

  depth: (id) =>
    node = @node(id)
    if node.parent is null
      return 0
    else
      # TODO: Keep track of which nodes we've visited to avoid cycles.
      return 1 + @depth(node.parent)

  # Really we just want to discourage people from modifying the array accidentally
  links: =>
    return @_links.slice(0)

  # Just for consistancy really
  _link: (child,parent) =>
    # TODO: Add sanity checks.
    if not @node(parent)? then throw "Parent node " + parent + " does not exist."
    # NOTE: It is important we store the parent ID here, not an actual object,
    # so that we can serialize _nodes as a flat array later on for storage!!!
    @node(child).parent = parent
    @node(parent).children.push(child)
    @_links.push(new Graph.Link(child,parent))
    return true

  # TODO: Make this more efficient?
  _unlink: (child,parent) =>
    @node(child).parent = null
    @node(parent).children = (id for id in @node(parent).children when id isnt child)
    @_links = (link for link in @_links when (link.child isnt child or link.parent isnt parent))
    return true

  # Constructor for main graph class.
  constructor: ->
    self = this # A hack, so we can access the graph methods inside nested closures that have different `this`
    # TODO: Perhaps get rid of this? Too many levels of object nesting. :-?
    @nodes.get = (id) =>
      nodes = @_nodes.filter((node) -> node.id is id)
      if nodes.length is 1
        return nodes[0]
      else
        throw "Multiple nodes matched id: " + id

    # TODO: We gotta figure out how much manipulation of the guts of the graph are
    # to be done 
    @_nodes = []
    @_nextid = 0
    @_links = []
    return this

class window.Graph.vis
  constructor: (@graph, @div) ->
    self = this;
    d3 = window.d3;
    @svgW = "100%"
    @svgH = 460
    @cx = 20
    @cy = 20
    @padding = 20
    @h = 70

    if typeof @div isnt "string" then @div = '#'+$(@div).attr('id')

    # This exists for the bizaire purpose of computing the width of a brand new node that doesn't 
    # have any physical existance yet.
    d3.select("body").append("div").attr("class", "node").attr("id", "protonode").html("?").style("visibility", "hidden")

    # Initialize the node group
    d3.select(@div).append("div").attr("class", "div_nodes")

    # Initialize the edge group
    d3.select(@div).append("svg").attr("class", "graphsvg")
      .append("g").attr("class", "g_lines")
      # .attr("width", @svgW).attr("height", @svgH)

  reposition: =>
    # I don't think this algorithm is perfect. But I currently
    # cannot formulate a "perfect" algorithm in my head. (I can 
    # formulate some denser but sometimes unexpected layouts.)
    # I am waiting to re-write this stuff until I have my AHA
    # perfect layout algorithm breakthrough.
    getNodeWidth = (node) =>      
      # Try to get a handle to the actual node.
      div = $(".node[data-id=#{node.id}]")      
      # If it doesn't exist, grab the proto-node so we don't have width == 0.
      div = $("#protonode") if div.length is 0 
      # Return whichever is wider, me or my children
      my_width = div.outerWidth()     
      # console.log('my_width: ' + my_width) 
      children_width = getChildrenWidth(node)     
      Math.max(my_width, children_width)

    getNodeHeight = (node) =>      
      # Try to get a handle to the actual node.
      div = $(".node[data-id=#{node.id}]")      
      # If it doesn't exist, grab the proto-node so we don't have width == 0.
      div = $("#protonode") if div.length is 0 
      # Return the height of node
      return div.outerHeight()

    getChildrenWidth = (node) =>
      # Sum up the width of the children
      if (node.children.length > 0) 
        width = (@padding * (node.children.length - 1))
        width += (getNodeWidth(@graph.node(id)) for id in node.children).reduce (a,b) -> a+b
        return width
      else 
        return 0

    # We are modifying this to use an actual node width rather than
    # a constant value (graph.padding)
    maxtop = 0
    reposition = (node) =>
      left = node.d3.x - getChildrenWidth(node) / 2
      for id in node.children
        child = @graph.node(id)
        padding = getNodeWidth(child)
        left += padding / 2
        child.d3.oldx = child.d3.x
        child.d3.oldy = child.d3.y
        child.d3.x = left
        child.d3.y = node.d3.y + @h
        left += padding / 2 + @padding
        maxtop = Math.max(maxtop, child.d3.y + getNodeHeight(child)/2)
        reposition child
      return

    # main reposition function.
    left = @padding
    for root in @graph.roots()
      half_width = getNodeWidth(root) / 2
      left += @padding + half_width
      root.d3.oldx = root.d3.x
      root.d3.oldy = root.d3.y
      root.d3.x = left
      root.d3.y = @padding
      reposition(root)
      left += half_width

    # Stretch SVG to cover width.
    cur_width = $("#{@div} .graphsvg").outerWidth()
    cur_height = $("#{@div} .graphsvg").outerHeight()
    left += @padding
    # Alright, too many browsers are having wrapping glitches. Make the minimum width the viewport width.
    left = Math.max($('body').outerWidth(), left)
    maxtop += @padding
    if (cur_width <= left)
      $("#{@div} .graphsvg").css("width",left)
      $("#{@div}").css("width",left)    
    else # Wait until the animated transitions have finished
      setTimeout () =>    
        $("#{@div} .graphsvg").css("width",left)
        $("#{@div}").css("width",left)
        return
      , 1000 
    if (cur_height <= maxtop)
      $("#{@div} .graphsvg").css("height",maxtop)
      $("#{@div}").css("height",maxtop)
    else # Wait until the animated transitions have finished
      setTimeout () =>
        $("#{@div} .graphsvg").css("height",maxtop)
        $("#{@div}").css("height",maxtop)
        return
      , 1000

    for link in @graph.links()
      parent = @graph.node(link.parent)
      child = @graph.node(link.child)
      link.d3 =
        parent:
          oldx: parent.d3.oldx
          oldy: parent.d3.oldy
          x: parent.d3.x
          y: parent.d3.y
        child:
          oldx: child.d3.oldx
          oldy: child.d3.oldy
          x: child.d3.x
          y: child.d3.y

  # TODO: Put edge labels back in?
  redraw: =>
    # Hack around `this` scope in callbacks.
    self = this

    centerLeft =(x, el) =>
      if x is null then return x
      if $(el).hasClass("node-container") then el = $(el).find(".node")
      x - $(el).outerWidth() / 2 + "px"

    centerTop = (y, el) =>
      if y is null then return y
      if $(el).hasClass("node-container") then el = $(el).find(".node")
      y - $(el).outerHeight() / 2 + "px"

    currentCenterLeft = (id) =>
      el = $(@div).find(".node[data-id=#{id}]")
      $(el).parent().position().left + $(el).outerWidth() /2
    currentCenterTop = (id) =>
      el = $(@div).find(".node[data-id=#{id}]")
      $(el).parent().position().top + $(el).outerHeight() /2

    # TODO: Decide if edge links should have an id outside of the d3 realm.
    edges = d3.select("#{@div} .g_lines").selectAll("line").data(@graph._links, (d)-> d.child)
    nodes = d3.select("#{@div} .div_nodes").selectAll(".node-container").data(@graph._nodes, (d)-> d.id)
    
    # Phase 1 - create all the HTML fatness so we know how wide all the elements are going to be.    
    nodes_enter = nodes.enter().append("div").attr("class","node-container")

    nodes_enter.append("div").attr("class", "node")
      .attr("id", (d) -> "node" + d.id)
      .attr("data-id", (d) -> d.id)
      .attr("draggable", "true")
      .html((d)-> d.d3.html)

    # Phase 2 - With these elements (hopefully) created now, compute their final positions.
    @reposition()

    # Phase 3 - Now, create the motion madness!
    edges.transition().duration(500)
      .attr("x1", (d) -> d.d3.parent.x)
      .attr("y1", (d) -> d.d3.parent.y)
      .attr("x2", (d) -> d.d3.child.x)
      .attr("y2", (d) -> d.d3.child.y)

    edges_enter = edges.enter().append("line")
      .attr("data-child", (d) -> d.child)
      .attr("x1", (d) -> d.d3.parent.oldx)
      .attr("y1", (d) -> d.d3.parent.oldy)
      .attr("x2", (d) -> d.d3.parent.oldx)
      .attr("y2", (d) -> d.d3.parent.oldy)

    edges_enter
      .transition().duration(500)
      .attr("x1", (d) -> d.d3.parent.x)
      .attr("y1", (d) -> d.d3.parent.y)
      .attr("x2", (d) -> d.d3.child.x)
      .attr("y2", (d) -> d.d3.child.y)

    edges.exit().transition().duration(500)  
      .attr("x1", "0")
      .attr("x2", "0")
      .attr("y1", "0")
      .attr("y2", "0")
      .style('opacity','0').remove()

    nodes.transition().duration(500)
      .style("left", (d) -> centerLeft(d.d3.x, this))
      .style("top",  (d) -> centerTop(d.d3.y, this))
      .style("z-index", (d)-> 1000-self.graph.depth(d.id)) # Child nodes are rendered underneath parents

    # Note: Since these set left and top based on the width and height,
    # this must be executed AFTER setting .html in the child.
    nodes_enter
      .style("position", "absolute")
      .style("z-index", (d)-> 1000-self.graph.depth(d.id)) # Child nodes are rendered underneath parents
      .style("left", (d) -> 
        x = if (d.parent is null) then d.d3.oldx else self.graph.node(d.parent).d3.oldx #currentCenterLeft(d.parent)
        centerLeft(x, this))
      .style("top",  (d) -> 
        y = if (d.parent is null) then d.d3.oldy else self.graph.node(d.parent).d3.oldy
        centerTop(y, this))

    # Note to future self: Apply transitions LAST after appending nested elements in order to behave propertly
    nodes_enter.transition().duration(500)
      .style("left", (d) -> centerLeft(d.d3.x, this))
      .style("top", (d) -> centerTop(d.d3.y, this))
   
    nodes.exit().transition().duration(500)    
      .style("left", (d) -> centerLeft(0, this))
      .style("top",  (d) -> centerTop(0, this))
      .style('opacity','0').remove()
