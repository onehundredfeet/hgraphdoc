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
    public function numChildren() return outgoing.count((x)-> x.name == "_CHILD" );
    public function getChild(name:String)return outgoing.find((x) -> x.target.name == name).target;
}

class NodeGraph {
    public function new() {

    }

    public function addNode() : NodeGraphNode {
        var x = new NodeGraphNode();
        _nodes.push(x);
        return x;
    }
    public var nodes(get,never) : Array<NodeGraphNode>;
    function get_nodes() return _nodes;

    var _nodes = new Array<NodeGraphNode>();
}