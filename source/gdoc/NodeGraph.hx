package gdoc;

import haxe.ds.StringMap;

using Lambda;

class Element {
	function new(id:Int) {
		this.id = id;
	}

	public var properties = new StringMap<Dynamic>();
	public var name:String;
	public var id(default, null):Int;

	function cloneTo(other:Element) {
		id = other.id;
		other.name = name;
		for (prop in properties.keyValueIterator()) {
			other.properties.set(prop.key, prop.value);
		}
	}

	public function toString():String {
		return 'Element(${name}, ${id})';
	}
}

final CHILD_RELATION = "_CHILD";

class Edge extends Element {
	public var source:Node;
	public var target:Node;

    public function isChildRelation() {
        return name == CHILD_RELATION;
    }
	public override function toString():String {
		return 'Edge(${name}, ${id})';
	}
}



// Node is a bit heavy, but we're not making giant graphs
class Node extends Element {
	public var connections = new Array<Edge>();

	// User data

	override function cloneTo(other:Element) {
		super.cloneTo(other);
		var n = cast other;
		n.x = x;
		n.y = y;
	}

	// Used for drawing
	public var x:Float;
	public var y:Float;

    public function distanceTo(n:Node):Float {
        return Math.sqrt((n.x - x) * (n.x - x) + (n.y - y) * (n.y - y));
    }
    public function distanceToSquared(n:Node):Float {
        return (n.x - x) * (n.x - x) + (n.y - y) * (n.y - y);
    }
	// any
	public inline function getEdges():Array<Edge> {
		return connections;
	}

	public inline function getEdge(relation:String):Edge {
		return connections.find((x) -> x.name == relation);
	}

	public inline function getEdgesBy(relation:String):Array<Edge> {
		return connections.filter((x) -> x.name == relation);
	}

	public inline function getConnectedNodes():Array<Node> {
		return connections.map((x) -> x.target);
	}

	public inline function getConnectedNode(relation:String):Node {
		return connections.find((x) -> x.name == relation).target;
	}

	public inline function getConnectedNodesBy(relation:String):Array<Node> {
		return connections.filter((x) -> x.name == relation).map((x) -> x.target);
	}

	public inline function getConnectedNodesByNot(relation:String):Array<Node> {
		return connections.filter((x) -> x.name != relation).map((x) -> x.target);
	}

	// outgoing
	public inline function getOutgoingEdges():Array<Edge> {
		return connections.filter((x) -> (x.source == this));
	}

	public inline function getOutgoingEdge(relation:String):Edge {
		return connections.find((x) -> (x.source == this && x.name == relation));
	}

	public inline function getOutgoingNodes():Array<Node> {
		return connections.filter((x) -> (x.source == this)).map((x) -> x.target);
	}

	public inline function getOutgoingNode(relation:String):Node {
		var e = connections.find((x) -> (x.source == this && x.name == relation));
		if (e == null)
			return null;
		return e.target;
	}

	public inline function getOutgoingEdgesBy(relation:String):Array<Edge> {
		return connections.filter((x) -> (x.source == this && x.name == relation));
	}

	public inline function getOutgoingEdgesByNot(relation:String):Array<Edge> {
		return connections.filter((x) -> (x.source == this && x.name != relation));
	}

	public function getOutgoingNodesBy(relation:String):Array<Node> {
		return getOutgoingEdgesBy(relation).map((x) -> x.target);
	}

	public function getOutgoingNodesByNot(relation:String):Array<Node> {
		return getOutgoingEdgesByNot(relation).map((x) -> x.target);
	}

	public function isConnected(n:Node):Bool {
		for (c in connections) {
			if (c.source == n || c.target == n)
				return true;
		}
		return false;
	}

	public function countOutgoing() : Int {
		return connections.count((x) -> x.source == this);
	}

	// incoming
	public inline function getIncomingEdges():Array<Edge> {
		return connections.filter((x) -> (x.target == this));
	}

	public inline function getIncomingEdge(relation:String):Edge {
		return connections.find((x) -> (x.target == this && x.name == relation));
	}

	public inline function getIncomingNodes():Array<Node> {
		return getIncomingEdges().map((x) -> x.source);
	}

	public inline function getIncomingNode(relation:String):Node {
		var x = getIncomingEdge(relation);
		if (x == null)
			return null;
		return x.source;
	}

	public function getIncomingNodesBy(relation:String):Array<Node> {
		return connections.filter((x) -> (x.target == this && x.name == relation)).map((x) -> x.source);
	}

	public function getIncomingNodesByNot(relation:String):Array<Node> {
		return connections.filter((x) -> (x.target == this && x.name != relation)).map((x) -> x.source);
	}

	public function countIncoming() : Int {
		return connections.count((x) -> x.target == this);
	}

	// hierarchy
	public inline function getParent():Node {
		return getIncomingNode(CHILD_RELATION);
	}

	public var parent(get, never):Node;

	inline function get_parent()
		return getParent();

	public inline function getChildrenEdges():Array<Edge> {
		return getOutgoingEdgesBy(CHILD_RELATION);
	}

	public inline function getChildrenNodes():Array<Node> {
		return getOutgoingNodesBy(CHILD_RELATION);
	}

	// exclude hierarhcy
	public inline function getNonChildrenOutgoingEdges():Array<Edge> {
		return getOutgoingEdgesByNot(CHILD_RELATION);
	}

	public inline function getNonChildrenOutgoingNodes():Array<Node> {
		return getOutgoingNodesByNot(CHILD_RELATION);
	}

	public function hasChildNamed(name:String)
		return connections.find((x) -> (x.source == this && x.name == CHILD_RELATION && x.target.name == name)) != null;

	public function hasChildren()
		return connections.find((x) -> (x.source == this && x.name == CHILD_RELATION)) != null;

	public function numChildren()
		return connections.filter((x) -> (x.source == this && x.name == CHILD_RELATION)).length;

	public function getChildNamed(name:String)
		return connections.find((x) -> (x.source == this && x.name == CHILD_RELATION && x.target.name == name));

	public function root():Node {
		var parent = getParent();
		if (parent == null)
			return this;
		return parent.root();
	}

	public function walkOutgoingEdgesNonChildren(f:(Edge) -> Void) {
		for (c in connections) {
			if (c.source == this && c.name != CHILD_RELATION) {
				f(c);
			}
		}
	}

	public function isAncestorOf(n:Node):Bool {
		if (this == n)
			return true;

		var parent = getParent();

		while (parent != null) {
			if (this == parent)
				return true;
			parent = parent.getParent();
		}
		return false;
	}

	public function firstCommonAncestor(n:Node) {
		if (this == n)
			return this;
		if (this.isAncestorOf(n))
			return this;
		if (n.isAncestorOf(this))
			return n;

		var current:Node = this;

		while ((current = current.getParent()) != null) {
			if (current.isAncestorOf(n))
				return current;
		}

		return null;
	}

	public override function toString():String {
		return 'Node(${name}, ${id})';
	}
}

class NodeGraph {
	var _nextNodeId = 0;
	var _nextEdgeId = 0;

	public function new() {}

	public function addNode(name:String = null) {
		var n = @:privateAccess new Node(_nextNodeId++);
		_nodes.push(n);
		n.name = name;
		return n;
	}

	public function connectNodes(source:Node, target:Node, relation:String = null) {
		var arc = @:privateAccess new Edge(_nextEdgeId++);
		_edges.push(arc);
		arc.source = source;
		arc.target = target;
		arc.name = relation;
		source.connections.push(arc);
		target.connections.push(arc);
		return arc;
	}

	public function collapseEdge(edge:Edge, fn:(Edge, source:Node, target:Node, merged:Node) -> Void = null):Node {
		var source = edge.source;
		var target = edge.target;
		var merged = addNode();
		removeEdge(edge);

		for (c in source.connections) {
			if (c.source == source) {
				c.source = merged;
			} else {
				c.target = merged;
			}
			merged.connections.push(c);
		}

		for (c in target.connections) {
			if (c.source == target) {
				c.source = merged;
			} else {
				c.target = merged;
			}
			merged.connections.push(c);
		}

		source.connections.resize(0);
		target.connections.resize(0);
		_nodes.remove(target);
		_nodes.remove(source);

		if (fn != null) {
			fn(edge, source, target, merged);
		}

		return merged;
	}

	public function subdivideEdge(edge:Edge, copyProperties = true,
			fn:(edge:Edge, source:Node, target:Node, sourceEdge:Edge, targetEdge:Edge, splitNode:Node) -> Void = null):Node {
		var source = edge.source;
		var target = edge.target;

		var split = addNode();

		var sourceEdge = connectNodes(source, split);
		var targetEdge = connectNodes(split, target);

		for (prop in edge.properties) {
			sourceEdge.properties.set(prop.key, prop.value);
			targetEdge.properties.set(prop.key, prop.value);
		}

		removeEdge(edge);

		if (fn != null) {
			fn(edge, source, target, sourceEdge, targetEdge, split);
		}
		return split;
	}

	// replaces an edge with a subraph
	public function replaceEdgeWithSubgraph(edge:Edge, sourceNew:Node, targetNew:Node) {
		var source = edge.source;
		var target = edge.target;

		var sourceEdge = connectNodes(source, sourceNew);
		var targetEdge = connectNodes(targetNew, target);

		removeEdge(edge);
	}

	public function replaceNodeWithSubgraph(node:Node, fn:(Edge) -> Node) {
		for (c in node.connections) {
			var newNode = fn(c);
			if (newNode != null) {
				if (c.source == node) {
					c.source = newNode;
				} else {
					c.target = newNode;
				}
			}
		}
		node.connections.resize(0);
		removeNode(node);
	}

	public function parentNode(parent:Node, child:Node) {
		return connectNodes(parent, child, CHILD_RELATION);
	}

	public function removeNode(node:Node) {
		_nodes.remove(node);
		for (c in node.connections) {
			if (c.source == node) {
				c.target.connections.remove(c);
			} else {
				c.source.connections.remove(c);
			}
			_edges.remove(c);
		}

		node.connections.resize(0);
	}

	public inline function splitEdge(edge:Edge, nodeName:String = null) {
        var node = insertNodeIntoEdge(edge, addNode(nodeName));
        var source = edge.source;
        var target = edge.target;
        node.x = (source.x + target.x) / 2;
		node.y = (source.y + target.y) / 2;
        return node;
	}

    public function insertNodeIntoEdge(edge:Edge, node:Node) {
		var target = edge.target;
		target.connections.remove(edge);

		edge.target = node;
		node.connections.push(edge);

		var newEdge = connectNodes(node, target, edge.name);
		// Copy properties
		for (p in edge.properties.keyValueIterator()) {
			newEdge.properties.set(p.key, p.value);
		}
		return node;
	}

    public function breakIntersection( e0 : Edge, e1 : Edge, nodeName : String) : Node {
        var n0 = e0.source;
        var n1 = e0.target;
        var n2 = e1.source;
        var n3 = e1.target;

        var intersection = Line2D.segmentIntersectionXY(n0.x, n0.y, n1.x, n1.y, n2.x, n2.y, n3.x, n3.y);
        if (intersection == null) {
            return null;
        }

        // insert node
        var newNode = addNode(nodeName);
        newNode.x = intersection.x;
        newNode.y = intersection.y;

        var ne0 = connectNodes(n0, newNode, e0.name);
        var ne1 = connectNodes(newNode, n1, e0.name);
        var ne2 = connectNodes(n2, newNode, e1.name);
        var ne3 = connectNodes(newNode, n3, e1.name);

        for (p in e0.properties.keyValueIterator()) {
            ne0.properties.set(p.key, p.value);
            ne1.properties.set(p.key, p.value);
        }
        for (p in e1.properties.keyValueIterator()) {
            ne2.properties.set(p.key, p.value);
            ne3.properties.set(p.key, p.value);
        }
        removeEdge(e0);
        removeEdge(e1);
        return newNode;
    }

	public function removeEdge(edge:Edge) {
		// trace('Removing edge ${edge.name} : ${edge.source.name} -> ${edge.target.name}');
		edge.source.connections.remove(edge);
		edge.target.connections.remove(edge);
		_edges.remove(edge);
	}

	public var nodes(get, never):Array<Node>;
	public var edges(get, never):Array<Edge>;

	inline function get_nodes()
		return _nodes;

	inline function get_edges()
		return _edges;

	public inline function numNodes()
		return _nodes.length;

	var _nodes = new Array<Node>();
	var _edges = new Array<Edge>();

	public function gatherOutgoingRelationNames():Array<String> {
		var names = new haxe.ds.StringMap<Bool>();

		for (n in _nodes) {
			for (c in n.getOutgoingEdges()) {
				if (c.name != null && c.name != null)
					names.set(c.name, true);
			}
		}

		names.remove(@:privateAccess CHILD_RELATION);

		return [for (k in names.keys()) k];
	}

	function copyContentsFrom(other:NodeGraph, cloneFn:(src:Element, tgt:Element) -> Void = null) {
		var nodeMap = new haxe.ds.IntMap<Node>();
		
		for (n in other._nodes) {
			var n2 = addNode();
			if (cloneFn != null)
				cloneFn(n, n2);
			else {
				@:privateAccess n.cloneTo(n2);
			}

			nodeMap.set(n.id, n2);
		}
		for (e in other._edges) {
			var src = nodeMap.get(e.source.id);
			var tgt = nodeMap.get(e.target.id);
			var e2 = connectNodes(src, tgt, e.name);
			if (cloneFn != null)
				cloneFn(e, e2);
			else {
				@:privateAccess e.cloneTo(e2);
			}
			@:privateAccess e2.id = e.id;
		}
	}
	public function clone(cloneFn:(src:Element, tgt:Element) -> Void = null):NodeGraph {
		var g = new NodeGraph();
		g.copyContentsFrom(this, cloneFn);
		return g;
	}

	public inline function getNodeFromID(id:Int):Node {
		return _nodes.find((x) -> x.id == id);
	}

	public inline function getEdgeFromID(id:Int):Edge {
		return _edges.find((x) -> x.id == id);
	}

	public inline function getElementFromId(id:Int):Element {
		var n = getNodeFromID(id);
		if (n != null)
			return n;
		return getEdgeFromID(id);
	}

	public static function fromTriangeCenters(triangles:Array<Triangle2D>, bidirectional = false, triangleAttribute:String = null):NodeGraph {
		var graph = new NodeGraph();
		var triToInt = new Map<Triangle2D, Int>();
		var pointToID = new Map<Point2D, Int>();
		var points = new Array<Point2D>();
		var pointCount = 0;
		var edges = new Map<Int, {a:Triangle2D, b:Triangle2D}>();

		inline function addPointToMap(p:Point2D) {
			if (!pointToID.exists(p)) {
				pointToID.set(p, pointCount++);
				points.push(p);
			}
			return pointToID.get(p);
		}

		inline function keyForPointPair(a:Point2D, b:Point2D) {
			var aid = pointToID.get(a);
			var bid = pointToID.get(b);
			if (aid < bid) {
				return (aid << 16) | bid;
			} else {
				return (bid << 16) | aid;
			}
		}

		function traceEdge(a:Point2D, b:Point2D, t:Triangle2D) {
			var edgekey = keyForPointPair(a, b);
			if (edges.exists(edgekey)) {
				var edge = edges.get(edgekey);
				if (edge.b == null) {
					edge.b = t;
					var otherTri = edge.a;
					var node = graph.nodes[triToInt.get(t)];
					var otherNode = graph.nodes[triToInt.get(otherTri)];
					graph.connectNodes(node, otherNode, "connected");
					if (bidirectional) {
						graph.connectNodes(otherNode, node, "connected");
					}
				} else {
					throw 'Non-manifold geometry';
				}
			} else {
				edges.set(edgekey, {a: t, b: null});
			}
		}

		// id's don't line up
		for (i in 0...triangles.length) {
			var t = triangles[i];
			var center = t.calculateCenter();

			triToInt.set(t, i);

			var n = graph.addNode();
			n.x = center.x;
			n.y = center.y;

			if (triangleAttribute != null) {
				n.properties.set(triangleAttribute, t);
			}

			addPointToMap(t.a);
			addPointToMap(t.b);
			addPointToMap(t.c);
		}

		for (i in 0...triangles.length) {
			var t = triangles[i];

			traceEdge(t.a, t.b, t);
			traceEdge(t.b, t.c, t);
			traceEdge(t.c, t.a, t);
		}

		return graph;
	}

	public function closestMatchByConnections(start:Node, fn:(Node) -> Bool, bidirectional:Bool = true):{node:Node, length:Int} {
		var open = new List<Node>();
		var jumps = new haxe.ds.IntMap<Int>();
		jumps.set(start.id, 0);

		function pushConnections(n:Node, depth:Int) {
			var connections = bidirectional ? n.connections : n.getOutgoingEdges();
			for (c in connections) {
				if (jumps.exists(c.target.id))
					continue;
				open.add(c.target);
				jumps.set(c.target.id, depth);
				if (fn(c.target))
					return c.target;
			}
			return null;
		}
		open.add(start);

		var next = null;
		while ((next = open.pop()) != null) {
			var result = pushConnections(next, jumps.get(next.id) + 1);
			if (result != null) {
				return {node: result, length: jumps.get(result.id)};
			}
		}

		return null;
	}

	public function findFirstIntersection( sharedVertex = false) : {e0:Edge, e1:Edge, point:Point2D} {
		// check for intersections
        var l = this.edges.length;
        for (i in 0...(l - 1)) {
            var e0 = this.edges[i];
            var n0 = e0.source;
			var n1 = e0.target;

            for (j in (i + 1)...l) {
                var e1 = this.edges[j];
                if (e0.source == e1.source || e0.source == e1.target || e0.target == e1.source || e0.target == e1.target) {
					if (sharedVertex) {
                        var p = e0.source == e1.source || e0.source == e1.target ? e0.source : e0.target;
                        return {e0: e0, e1: e1, point: new Point2D(p.x, p.y)};
                    }
                    continue;
				}
				var n2 = e1.source;
				var n3 = e1.target;
				var intersection = Line2D.segmentIntersectionXY(n0.x, n0.y, n1.x, n1.y, n2.x, n2.y, n3.x, n3.y);
				if (intersection != null) {
					return {e0: e0, e1: e1, point: intersection};
				}
            }
        }

		return null;
	}

	public function isAcyclicFrom(root:Node) : Bool {
		function scanNode(path: Map<Node, Bool>, n : Node) : Bool{
			path.set(n, true);

			for (c in n.getOutgoingEdges()) {
				if (path.exists(c.target)) {
					return false;
				}
				if (!scanNode(path, c.target)) {
					return false;
				}
			}

			path.remove(n);

			return true;
		}
		
		return scanNode([], root);
	}

	public function isSafeToInsertEdge(a : Node, b:Node) : Bool {
		if (a == b) return false;
		for (e in _edges) {
			if (e.source == a || e.target == a) {
				continue;
			}
			if (e.source == b || e.target == b) {
				continue;
			}
			if (Line2D.areSegmentsIntersectingXY(a.x, a.y, b.x, b.y, e.source.x, e.source.y, e.target.x, e.target.y)) {
				trace('a ${a.name}[${a.id}] b ${b.name}[${b.id}] intersects e ${e.source.name}[${e.source.id}] -> ${e.target.name}[${e.target.id}]');
				return false;
			}
		}
		return true;
	}
}
