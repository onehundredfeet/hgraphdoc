package gdoc;
import gdoc.NodeGraph2D;

class NodeGraphOverlayNode2D  {
    public function new (node : NodeGraphNode2D, id : Int) {
        this.node = node;
        this.id = id;
    }
    public var node : NodeGraphNode2D;
    public var id : Int;
    public var user : Dynamic;
}

class NodeGraph2DOverlay {
    public function new(graph : NodeGraph2D) {
        for (node in graph.nodes) {
            _nodes.push(new NodeGraphOverlayNode2D(node, _nodes.length));
        }
    }

    public var nodes(get,never) : Array<NodeGraphOverlayNode2D>;
    inline function get_nodes() return _nodes;
    
    public inline function numNodes() return _nodes.length;
    
    var _nodes = new Array<NodeGraphOverlayNode2D>();
}