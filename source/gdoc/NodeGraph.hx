package gdoc;

import haxe.ds.StringMap;
using Lambda;

class NodeGraphArc {
    public function new() {

    }

    public var source : NodeGraphNode;
    public var target : NodeGraphNode;
    public var properties = new StringMap<String>();
    public var name : String;
}

class NodeGraphNode {
    public var name : String;
    public var parent : NodeGraphNode;
    public var children  = new Array<NodeGraphArc>();
    public var properties = new StringMap<String>();
    public var outgoing  = new Array<NodeGraphArc>();
    public var incoming  = new Array<NodeGraphArc>();

    public function new() {

    }

    public function connectTo(target : NodeGraphNode, relation : String = null) {
        var arc = new NodeGraphArc();
        arc.source = this;
        arc.target = target;
        arc.name = relation;
        outgoing.push(arc);
        target.incoming.push(arc);
    }

    public function connectChild(target : NodeGraphNode) {
        target.parent = this;
        var arc = new NodeGraphArc();
        arc.source = this;
        arc.target = target;
        arc.name = "_CHILD";
        children.push(arc);
    }

    public function getConnectedByOutgoing(relation: String) : Array<NodeGraphNode> {
        return outgoing.filter((x)->x.name == relation).map((x)->x.target);
    }

    public function getConnectedByNotOutgoing(relation: String) : Array<NodeGraphNode> {
        return outgoing.filter((x)->x.name != relation).map((x)->x.target);
    }

    public inline function getChildrenConnections() return children;
    public function getChildren() return children.map((x)->x.target);
    public function getNonChildrenOutgoing() return outgoing.map((x)->x.target);
    public function hasChildNamed(name:String) return children.find((x) -> x.target.name == name) != null;
    public function hasChildren() return children.length > 0;
    public function numChildren() return children.length;
    public function getChildNamed(name:String)return children.find((x) -> x.target.name == name).target;
    public function root() : NodeGraphNode {
        if (parent == null) return this;
        return parent.root();
    }
    public function walkOutgoingNonChildren(f:(NodeGraphArc) -> Void) {
        for (c in outgoing) {
            f(c);
        }
    }

    public function isAncestorOf( n : NodeGraphNode) : Bool {
        if (this == n) return true;
    
        while (n.parent != null) {
            if (this == n.parent) return true;
            n = n.parent;
        }
        return false;
    }

    public function firstCommonAncestor(n : NodeGraphNode) {
        if (this == n) return this;
        if (this.isAncestorOf( n)) return this;
        if (n.isAncestorOf(this)) return n;
        
        var current : NodeGraphNode = this;
    
        while ((current = current.parent) != null) {
            if (current.isAncestorOf( n )) 
                return current;
        }
    
        return null;
    }
}

class NodeGraph {
    public function new() {

    }

    public inline function addNode() : NodeGraphNode {
        var x = new NodeGraphNode();
        _nodes.push(x);
        return x;
    }

    public function gatherOutgoingRelationNames() : Array<String> {
        var names = new haxe.ds.StringMap<Bool>();
     
        for (n in _nodes) {
            for (c in n.outgoing) {
                names.set(c.name, true);
            }
        }

        return [for (k in names.keys()) k];
    }

    public var nodes(get,never) : Array<NodeGraphNode>;
    inline function get_nodes() return _nodes;

    public inline function numNodes() return _nodes.length;

    var _nodes = new Array<NodeGraphNode>();
}

