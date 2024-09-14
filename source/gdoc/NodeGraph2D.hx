package gdoc;

import haxe.ds.StringMap;
import gdoc.NodeGraph;
using Lambda;


class NodeGraphNode2D extends NodeGraphNode {
    public var x : Float;
    public var y : Float;
}

class NodeGraph2D {
    public function new() {

    }

    public inline function addNode() : NodeGraphNode2D {
        var x = new NodeGraphNode2D();
        _nodes.push(x);
        return x;
    }

    public var nodes(get,never) : Array<NodeGraphNode2D>;
    inline function get_nodes() return _nodes;
    
    public inline function numNodes() return _nodes.length;
    
    var _nodes = new Array<NodeGraphNode2D>();
}