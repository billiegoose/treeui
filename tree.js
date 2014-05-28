// Generated by CoffeeScript 1.6.3
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.Graph = (function() {
    Graph.Node = (function() {
      function Node(id) {
        this.id = id;
        this.parent = null;
        this.children = [];
        this.d3 = {
          html: '?',
          x: null,
          y: null
        };
        this.data = {
          token: null,
          value: null
        };
      }

      return Node;

    })();

    Graph.Link = (function() {
      function Link(child, parent) {
        this.child = child;
        this.parent = parent;
        this.d3 = {
          child: {
            x: null,
            y: null
          },
          parent: {
            x: null,
            y: null
          }
        };
      }

      return Link;

    })();

    Graph.prototype.nodes = function() {
      return this._nodes.slice(0);
    };

    Graph.prototype.node = function(id) {
      var node, nodes;
      nodes = (function() {
        var _i, _len, _ref, _results;
        _ref = this._nodes;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          if (node.id === id) {
            _results.push(node);
          }
        }
        return _results;
      }).call(this);
      switch (nodes.length) {
        case 0:
          throw "No node found matching id: " + id;
          break;
        case 1:
          return nodes[0];
        default:
          console.log(nodes);
          throw "Multiple nodes matched id: " + id;
      }
    };

    Graph.prototype.addNode = function(data, parent) {
      var node;
      node = new Graph.Node;
      node.id = this._nextid++;
      node.data = data;
      this._nodes.push(node);
      if (parent != null) {
        this._link(node.id, parent);
      }
      return node;
    };

    Graph.prototype.moveNode = function(id, newparent) {
      var oldparent;
      oldparent = this.node(id).parent;
      if (oldparent != null) {
        this._unlink(id, oldparent);
      }
      if (newparent != null) {
        this._link(id, newparent);
      }
      return true;
    };

    Graph.prototype.removeNode = function(id) {
      var link, node, _i, _len, _ref;
      _ref = this._links;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        link = _ref[_i];
        if (link.parent === id || link.child === id) {
          this._unlink(link.child, link.parent);
        }
      }
      this._nodes = (function() {
        var _j, _len1, _ref1, _results;
        _ref1 = this._nodes;
        _results = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          node = _ref1[_j];
          if (node.id !== id) {
            _results.push(node);
          }
        }
        return _results;
      }).call(this);
      return true;
    };

    Graph.prototype.leaves = function() {
      var node;
      return (function() {
        var _i, _len, _ref, _results;
        _ref = this._nodes;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          if (node.children.length === 0) {
            _results.push(node);
          }
        }
        return _results;
      }).call(this);
    };

    Graph.prototype.roots = function() {
      var node;
      return (function() {
        var _i, _len, _ref, _results;
        _ref = this._nodes;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          if (node.parent === null) {
            _results.push(node);
          }
        }
        return _results;
      }).call(this);
    };

    Graph.prototype.depth = function(id) {
      var node;
      node = this.node(id);
      if (node.parent === null) {
        return 0;
      } else {
        return 1 + this.depth(node.parent);
      }
    };

    Graph.prototype.links = function() {
      return this._links.slice(0);
    };

    Graph.prototype._link = function(child, parent) {
      if (this.node(parent) == null) {
        throw "Parent node " + parent + " does not exist.";
      }
      this.node(child).parent = parent;
      this.node(parent).children.push(child);
      this._links.push(new Graph.Link(child, parent));
      return true;
    };

    Graph.prototype._unlink = function(child, parent) {
      var id, link;
      this.node(child).parent = null;
      this.node(parent).children = (function() {
        var _i, _len, _ref, _results;
        _ref = this.node(parent).children;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          id = _ref[_i];
          if (id !== child) {
            _results.push(id);
          }
        }
        return _results;
      }).call(this);
      this._links = (function() {
        var _i, _len, _ref, _results;
        _ref = this._links;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          link = _ref[_i];
          if (link.child !== child || link.parent !== parent) {
            _results.push(link);
          }
        }
        return _results;
      }).call(this);
      return true;
    };

    function Graph() {
      this._unlink = __bind(this._unlink, this);
      this._link = __bind(this._link, this);
      this.links = __bind(this.links, this);
      this.depth = __bind(this.depth, this);
      this.roots = __bind(this.roots, this);
      this.leaves = __bind(this.leaves, this);
      this.removeNode = __bind(this.removeNode, this);
      this.moveNode = __bind(this.moveNode, this);
      this.addNode = __bind(this.addNode, this);
      this.node = __bind(this.node, this);
      this.nodes = __bind(this.nodes, this);
      var self,
        _this = this;
      self = this;
      this.nodes.get = function(id) {
        var nodes;
        nodes = _this._nodes.filter(function(node) {
          return node.id === id;
        });
        if (nodes.length === 1) {
          return nodes[0];
        } else {
          throw "Multiple nodes matched id: " + id;
        }
      };
      this._nodes = [];
      this._nextid = 0;
      this._links = [];
      return this;
    }

    return Graph;

  })();

  window.Graph.vis = (function() {
    function vis(graph, div) {
      var d3, self;
      this.graph = graph;
      this.div = div;
      this.redraw = __bind(this.redraw, this);
      this.reposition = __bind(this.reposition, this);
      self = this;
      d3 = window.d3;
      this.svgW = "100%";
      this.svgH = 460;
      this.cx = 20;
      this.cy = 20;
      this.padding = 20;
      this.h = 70;
      if (typeof this.div !== "string") {
        this.div = '#' + $(this.div).attr('id');
      }
      d3.select("body").append("div").attr("class", "node").attr("id", "protonode").html("?").style("visibility", "hidden");
      d3.select(this.div).append("div").attr("class", "div_nodes");
      d3.select(this.div).append("svg").attr("class", "graphsvg").append("g").attr("class", "g_lines");
    }

    vis.prototype.reposition = function() {
      var child, cur_height, cur_width, getChildrenWidth, getNodeHeight, getNodeWidth, half_width, left, link, maxtop, parent, reposition, root, _i, _j, _len, _len1, _ref, _ref1, _results,
        _this = this;
      getNodeWidth = function(node) {
        var children_width, div, my_width;
        div = $(".node[data-id=" + node.id + "]");
        if (div.length === 0) {
          div = $("#protonode");
        }
        my_width = div.outerWidth();
        children_width = getChildrenWidth(node);
        return Math.max(my_width, children_width);
      };
      getNodeHeight = function(node) {
        var div;
        div = $(".node[data-id=" + node.id + "]");
        if (div.length === 0) {
          div = $("#protonode");
        }
        return div.outerHeight();
      };
      getChildrenWidth = function(node) {
        var id, width;
        if (node.children.length > 0) {
          width = _this.padding * (node.children.length - 1);
          width += ((function() {
            var _i, _len, _ref, _results;
            _ref = node.children;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              id = _ref[_i];
              _results.push(getNodeWidth(this.graph.node(id)));
            }
            return _results;
          }).call(_this)).reduce(function(a, b) {
            return a + b;
          });
          return width;
        } else {
          return 0;
        }
      };
      maxtop = 0;
      reposition = function(node) {
        var child, id, left, padding, _i, _len, _ref;
        left = node.d3.x - getChildrenWidth(node) / 2;
        _ref = node.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          id = _ref[_i];
          child = _this.graph.node(id);
          padding = getNodeWidth(child);
          left += padding / 2;
          child.d3.oldx = child.d3.x;
          child.d3.oldy = child.d3.y;
          child.d3.x = left;
          child.d3.y = node.d3.y + _this.h;
          left += padding / 2 + _this.padding;
          maxtop = Math.max(maxtop, child.d3.y + getNodeHeight(child) / 2);
          reposition(child);
        }
      };
      left = this.padding;
      _ref = this.graph.roots();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        root = _ref[_i];
        half_width = getNodeWidth(root) / 2;
        left += this.padding + half_width;
        root.d3.oldx = root.d3.x;
        root.d3.oldy = root.d3.y;
        root.d3.x = left;
        root.d3.y = this.padding;
        reposition(root);
        left += half_width;
      }
      cur_width = $("" + this.div + " .graphsvg").outerWidth();
      cur_height = $("" + this.div + " .graphsvg").outerHeight();
      left += this.padding;
      left = Math.max($('body').outerWidth(), left);
      maxtop += this.padding;
      if (cur_width <= left) {
        $("" + this.div + " .graphsvg").css("width", left);
        $("" + this.div).css("width", left);
      } else {
        setTimeout(function() {
          $("" + _this.div + " .graphsvg").css("width", left);
          $("" + _this.div).css("width", left);
        }, 1000);
      }
      if (cur_height <= maxtop) {
        $("" + this.div + " .graphsvg").css("height", maxtop);
        $("" + this.div).css("height", maxtop);
      } else {
        setTimeout(function() {
          $("" + _this.div + " .graphsvg").css("height", maxtop);
          $("" + _this.div).css("height", maxtop);
        }, 1000);
      }
      _ref1 = this.graph.links();
      _results = [];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        link = _ref1[_j];
        parent = this.graph.node(link.parent);
        child = this.graph.node(link.child);
        _results.push(link.d3 = {
          parent: {
            oldx: parent.d3.oldx,
            oldy: parent.d3.oldy,
            x: parent.d3.x,
            y: parent.d3.y
          },
          child: {
            oldx: child.d3.oldx,
            oldy: child.d3.oldy,
            x: child.d3.x,
            y: child.d3.y
          }
        });
      }
      return _results;
    };

    vis.prototype.redraw = function() {
      var centerLeft, centerTop, currentCenterLeft, currentCenterTop, edges, edges_enter, nodes, nodes_enter, self,
        _this = this;
      self = this;
      centerLeft = function(x, el) {
        if (x === null) {
          return x;
        }
        if ($(el).hasClass("node-container")) {
          el = $(el).find(".node");
        }
        return x - $(el).outerWidth() / 2 + "px";
      };
      centerTop = function(y, el) {
        if (y === null) {
          return y;
        }
        if ($(el).hasClass("node-container")) {
          el = $(el).find(".node");
        }
        return y - $(el).outerHeight() / 2 + "px";
      };
      currentCenterLeft = function(id) {
        var el;
        el = $(_this.div).find(".node[data-id=" + id + "]");
        return $(el).parent().position().left + $(el).outerWidth() / 2;
      };
      currentCenterTop = function(id) {
        var el;
        el = $(_this.div).find(".node[data-id=" + id + "]");
        return $(el).parent().position().top + $(el).outerHeight() / 2;
      };
      edges = d3.select("" + this.div + " .g_lines").selectAll("line").data(this.graph._links, function(d) {
        return d.child;
      });
      nodes = d3.select("" + this.div + " .div_nodes").selectAll(".node-container").data(this.graph._nodes, function(d) {
        return d.id;
      });
      nodes_enter = nodes.enter().append("div").attr("class", "node-container");
      nodes_enter.append("div").attr("class", "node").attr("id", function(d) {
        return "node" + d.id;
      }).attr("data-id", function(d) {
        return d.id;
      }).attr("draggable", "true").html(function(d) {
        return d.d3.html;
      });
      this.reposition();
      edges.transition().duration(500).attr("x1", function(d) {
        return d.d3.parent.x;
      }).attr("y1", function(d) {
        return d.d3.parent.y;
      }).attr("x2", function(d) {
        return d.d3.child.x;
      }).attr("y2", function(d) {
        return d.d3.child.y;
      });
      edges_enter = edges.enter().append("line").attr("data-child", function(d) {
        return d.child;
      }).attr("x1", function(d) {
        return d.d3.parent.oldx;
      }).attr("y1", function(d) {
        return d.d3.parent.oldy;
      }).attr("x2", function(d) {
        return d.d3.parent.oldx;
      }).attr("y2", function(d) {
        return d.d3.parent.oldy;
      });
      edges_enter.transition().duration(500).attr("x1", function(d) {
        return d.d3.parent.x;
      }).attr("y1", function(d) {
        return d.d3.parent.y;
      }).attr("x2", function(d) {
        return d.d3.child.x;
      }).attr("y2", function(d) {
        return d.d3.child.y;
      });
      edges.exit().transition().duration(500).attr("x1", "0").attr("x2", "0").attr("y1", "0").attr("y2", "0").style('opacity', '0').remove();
      nodes.transition().duration(500).style("left", function(d) {
        return centerLeft(d.d3.x, this);
      }).style("top", function(d) {
        return centerTop(d.d3.y, this);
      }).style("z-index", function(d) {
        return 1000 - self.graph.depth(d.id);
      });
      nodes_enter.style("position", "absolute").style("z-index", function(d) {
        return 1000 - self.graph.depth(d.id);
      }).style("left", function(d) {
        var x;
        x = d.parent === null ? d.d3.oldx : self.graph.node(d.parent).d3.oldx;
        return centerLeft(x, this);
      }).style("top", function(d) {
        var y;
        y = d.parent === null ? d.d3.oldy : self.graph.node(d.parent).d3.oldy;
        return centerTop(y, this);
      });
      nodes_enter.transition().duration(500).style("left", function(d) {
        return centerLeft(d.d3.x, this);
      }).style("top", function(d) {
        return centerTop(d.d3.y, this);
      });
      return nodes.exit().transition().duration(500).style("left", function(d) {
        return centerLeft(0, this);
      }).style("top", function(d) {
        return centerTop(0, this);
      }).style('opacity', '0').remove();
    };

    return vis;

  })();

}).call(this);

/*
//@ sourceMappingURL=tree.map
*/
