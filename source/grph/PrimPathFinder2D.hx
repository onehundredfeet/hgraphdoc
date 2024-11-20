package grph;
import grph.Prim2D;
import grph.PrimConnectivity2D;
import grph.Point2D;
import grph.MinHeap;

using Lambda;

class PrimPathNode2D {
    public var src:Prim2D;
    public var a:PrimPathNode2D;
    public var b:PrimPathNode2D;
    public var c:PrimPathNode2D;
    public var d:PrimPathNode2D;
    public var x:Float;
    public var y:Float;
    public inline function new(src:Prim2D) {
        this.src = src;
        var p = src.getCentroid();
        x = p.x;
        y = p.y;
    }

    @:keep
    public function toString() {
        return 'PrimPathNode2D([${x}, ${y}] ${src})';
    }
}

class PrimPathCache2DNode extends AMinHeapItem{
    public function new( src : PrimPathNode2D) {
        super();
        this.src = src;
    }

    public function link(cache: PrimPathCache2D) {
        if (src.a != null) this.a = @:privateAccess cache.getNodeFromPrim(src.a.src);
        if (src.b != null) this.b = @:privateAccess cache.getNodeFromPrim(src.b.src);
        if (src.c != null) this.c = @:privateAccess cache.getNodeFromPrim(src.c.src);
        if (src.d != null) this.d = @:privateAccess cache.getNodeFromPrim(src.d.src);

    }
    public var src: PrimPathNode2D;
    public var pathDistance:Float = Math.POSITIVE_INFINITY;
    public var allowed:Int = 0;
    public var distanceToTarget:Float = Math.POSITIVE_INFINITY;
    public var totalScore:Float = Math.POSITIVE_INFINITY;
    public var prev:PrimPathCache2DNode;

    public var a:PrimPathCache2DNode;
    public var b:PrimPathCache2DNode;
    public var c:PrimPathCache2DNode;
    public var d:PrimPathCache2DNode;

    @:keep
    public function toString() {
        return 'PrimPathCache2DNode(${src})';
    }
}

@:forward
@:forward.new
abstract PrimPath(Array<Prim2D>) from Array<Prim2D> to Array<Prim2D> {
    @:keep
    public function toString() {
        return 'PrimPath[${this.length}](${this})';
    }
}

class PrimPathCache2D{
    public function new( finder : PrimPathFinder2D) {
        _finder = finder;
        _cache = @:privateAccess _finder._nodes.map((n) -> new PrimPathCache2DNode(n));
        for (c in _cache) {
            c.link(this);
        }
    }

    public function flush() {
        // overkill, but clean
        for (c in _cache) {
            c.pathDistance = Math.POSITIVE_INFINITY;
            c.distanceToTarget = Math.POSITIVE_INFINITY;
            c.totalScore = Math.POSITIVE_INFINITY;
            c.allowed = 0;     
            c.prev = null;
        }
        _frontier.clear();
    }

    function getNodeFromPrim(prim:Prim2D):PrimPathCache2DNode {
        return _cache[@:privateAccess _finder._nodeToIndex.get(prim)];
    }

    // order by totalScore, greatest to least
    var _frontier = new MinHeap<PrimPathCache2DNode>();

    var _origin : Prim2D;
    var _originNode : PrimPathCache2DNode;

    public function setOrigin( p : Prim2D ) {
        _origin = p;
        _originNode = getNodeFromPrim(p);
    }
    public function getPathTo( destination : Prim2D, out : PrimPath ) : Bool {
        var destNode = getNodeFromPrim(destination);

        inline function computeDistanceToTarget( a : PrimPathCache2DNode) : Float {
            var dx = a.src.x - destNode.src.x;
            var dy = a.src.y - destNode.src.y;
            return Math.sqrt(dx * dx + dy * dy);
        }

        _originNode.distanceToTarget = computeDistanceToTarget(_originNode);
        
        _originNode.pathDistance = 0;
        _frontier.insert(_originNode, _originNode.totalScore);

        // A-star path finding
        while (_frontier.length > 0) {
            var current = _frontier.pop();
            //trace('current ${current.src.src}');
            if (current == destNode) {
                while (current != null) {
                    out.push(current.src.src);
                    current = current.prev;
                }
                out.reverse();
                // Found the path
                return true;
            }

            function checkNeighbour( neighbour : PrimPathCache2DNode ) {      
                if (neighbour == null) return;
                if (neighbour == current.prev) return;

                if (neighbour.distanceToTarget == Math.POSITIVE_INFINITY) {
                    // distance to target
                    neighbour.distanceToTarget = computeDistanceToTarget(neighbour);
                }
                var dx = neighbour.src.x - current.src.x;
                var dy = neighbour.src.y - current.src.y;
                var neighborDistance = Math.sqrt(dx * dx + dy * dy);
                var pathDistance = current.pathDistance + neighborDistance;
//                trace('pathDistance ${pathDistance} n dist ${neighborDistance} current neighbour path distance ${neighbour.pathDistance}');
                var totalDistance = pathDistance + neighbour.distanceToTarget;
                if (totalDistance < neighbour.totalScore) {
                    neighbour.pathDistance = pathDistance;
                    neighbour.totalScore = neighbour.pathDistance + neighbour.distanceToTarget;
                    neighbour.prev = current;
                    if (_frontier.contains(neighbour)) {
                        _frontier.decreaseKey(neighbour, neighbour.totalScore);
                    } else {
//                        trace('inserting ${neighbour.src.src}');
                        _frontier.insert(neighbour, neighbour.totalScore);
                    }
                }
            }

            checkNeighbour( current.a);
            checkNeighbour( current.b);
            checkNeighbour( current.c);
            checkNeighbour( current.d);
        }

        return false;
    }
    public function getPath( a : Prim2D, b : Prim2D, out : PrimPath ) : Bool {
        flush();

        setOrigin(a);
        
        return getPathTo(b, out);
    }

    var _finder:PrimPathFinder2D;
    var _cache:Array<PrimPathCache2DNode>;
}

class PrimPathFinder2D {
    public function new() {

    }
    
    public function getCache():PrimPathCache2D {
        return new PrimPathCache2D(this);
    }

    var _nodes:Array<PrimPathNode2D>;
    var _nodeToIndex:Map<Prim2D,Int> = new Map<Prim2D,Int>();

    public static function fromPrimConnectivity(connectivity:PrimConnectivity2D):PrimPathFinder2D {
        var finder = new PrimPathFinder2D();

        var prims = connectivity.gatherFaces();
        finder._nodes = prims.map((p) -> new PrimPathNode2D(p));
        for (i in 0...finder._nodes.length) {
            finder._nodeToIndex.set(prims[i], i);
        }
        for (n in finder._nodes) {
            var neighbours = connectivity.getNeighbours(n.src);
            if (neighbours[0] != null) n.a = finder._nodes[finder._nodeToIndex.get(neighbours[0])];
            if (neighbours[1] != null) n.b = finder._nodes[finder._nodeToIndex.get(neighbours[1])];
            if (neighbours[2] != null) n.c = finder._nodes[finder._nodeToIndex.get(neighbours[2])];
            if (neighbours.length == 4 && neighbours[3] != null) n.d = finder._nodes[finder._nodeToIndex.get(neighbours[3])];
        }
        return finder;
    }
}