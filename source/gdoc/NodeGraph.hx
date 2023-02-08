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
    public var properties = new StringMap<String>();
    public var outgoing  = new Array<NodeGraphArc>();
    public var incoming  = new Array<NodeGraphArc>();

    public function new() {

    }

    public function getConnectedBy(relation: String) : Array<NodeGraphNode> {
        return outgoing.filter((x)->x.name == relation).map((x)->x.target);
    }

    public function getConnectedByNot(relation: String) : Array<NodeGraphNode> {
        return outgoing.filter((x)->x.name != relation).map((x)->x.target);
    }

    public function getChildren() return getConnectedBy("_CHILD");
    public function getNonChildren() return getConnectedByNot("_CHILD");
    public function hasChild(name:String) return outgoing.find((x) -> x.target.name == name) != null;
    public function hasChildren() return outgoing.exists((x) -> x.name == "_CHILD");
    public function numChildren() return outgoing.count((x)-> x.name == "_CHILD" );
    public function getChild(name:String)return outgoing.find((x) -> x.target.name == name).target;
    public function root() : NodeGraphNode {
        if (parent == null) return this;
        return parent.root();
    }
    public function walkOutgoingNonChildren(f:(NodeGraphArc) -> Void) {
        for (c in outgoing) {
            if (c.name != "_CHILD") {
                f(c);
            }
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

    public function addNode() : NodeGraphNode {
        var x = new NodeGraphNode();
        _nodes.push(x);
        return x;
    }

    public function gatherTransitionNames() : Array<String> {
        var names = new haxe.ds.StringMap<Bool>();
     
        for (n in _nodes) {
            for (c in n.outgoing) {
                if (c.name != "_CHILD") {
                    names.set(c.name, true);
                }
            }
        }

        return [for (k in names.keys()) k];
    }

    public var nodes(get,never) : Array<NodeGraphNode>;
    function get_nodes() return _nodes;

    var _nodes = new Array<NodeGraphNode>();
}