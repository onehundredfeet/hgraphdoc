package gdoc;
import gdoc.PrimConnectivity2D;
import gdoc.Point2D;

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
}

class PrimPathCache2DNode {
    public function new( src : PrimPathNode2D, cache: PrimPathCache2D) {
        this.src = src;

        this.a = @:privateAccess cache.getNodeFromPrim(src.a.src);
        this.b = @:privateAccess cache.getNodeFromPrim(src.b.src);
        this.c = @:privateAccess cache.getNodeFromPrim(src.c.src);
        if (src.d != null)
            this.d = @:privateAccess cache.getNodeFromPrim(src.d.src);
    }
    public var src: PrimPathNode2D;
    public var pathDistance:Float = 0.0;
    public var allowed:Int = 0;
    public var distanceToTarget:Float = Math.POSITIVE_INFINITY;
    public var totalScore:Float = Math.POSITIVE_INFINITY;
    public var openIndex = -1;
    public var prev:PrimPathCache2DNode;

    public var a:PrimPathCache2DNode;
    public var b:PrimPathCache2DNode;
    public var c:PrimPathCache2DNode;
    public var d:PrimPathCache2DNode;
}

class PrimPath {
    public var nodes:Array<PrimPathNode2D>;
}

class PrimPathCache2D{
    public function new( finder : PrimPathFinder2D) {
        _finder = finder;
        _cache = @:privateAccess _finder._nodes.map((n) -> new PrimPathCache2DNode(n, this));
    }

    public function flush() {
        // overkill, but clean
        for (c in _cache) {
            c.pathDistance = 0.0;
            c.distanceToTarget = Math.POSITIVE_INFINITY;
            c.allowed = 0;     
            c.prev = null;
            c.openIndex = -1;
        }
        _frontier.resize(0);
    }

    inline function getNodeFromPrim(prim:Prim2D):PrimPathCache2DNode {
        return _cache[@:privateAccess _finder._nodeToIndex.get(prim)];
    }

    // order by totalScore, greatest to least
    var _frontier:Array<PrimPathCache2DNode> = [];
    
    function insert( node : PrimPathCache2DNode ) {
        var last = _frontier.length - 1;
        var totalScore = node.totalScore;
        
        while (last >= 0) {
            if (totalScore < _frontier[last].totalScore ) {
                break;
            }
            last--;
        }

        
        var current = node;
        // bubble them up
        for (i in (last + 1)..._frontier.length) {
            var tmp = _frontier[i];
            current.openIndex = i - 1;
            _frontier[i] = current;
            current = tmp;
        }

        current.openIndex = _frontier.length ;
        _frontier.push(current);
    }

    function update(node : PrimPathCache2DNode) {
        var d = node.totalScore;

        for (i in (node.openIndex+1)..._frontier.length) {
            if (d < _frontier[i].totalScore) {
                // swap
                var tmp = _frontier[i];
                _frontier[i] = node;
                _frontier[node.openIndex] = tmp;
            }
        }
    }


    public function getPath( a : Prim2D, b : Prim2D, out : PrimPath ) : Bool {
        flush();

        var aNode = getNodeFromPrim(a);
        var destNode = getNodeFromPrim(b);

        inline function computeDistanceToTarget( a : PrimPathCache2DNode) : Float {
            var dx = a.src.x - destNode.src.x;
            var dy = a.src.y - destNode.src.y;
            return Math.sqrt(dx * dx + dy * dy);
        }

        aNode.distanceToTarget = computeDistanceToTarget(aNode);
        insert(aNode);

        // A-star path finding
        while (_frontier.length > 0) {
            var current = _frontier.pop();

            if (current == destNode) {
                // Found the path
                return true;
            }
            current.openIndex = -1;

            var minIndex = _frontier.length;

            function checkNeighbour( neighbour : PrimPathCache2DNode ) {            
                if (neighbour.distanceToTarget == Math.POSITIVE_INFINITY) {
                    // distance to target
                    var dx = destNode.src.x - neighbour.src.x;
                    var dy = destNode.src.y - neighbour.src.y;
                    neighbour.distanceToTarget = computeDistanceToTarget(destNode);
                }
                var dx = neighbour.src.x - current.src.x;
                var dy = neighbour.src.y - current.src.y;
                var neighborDistance = Math.sqrt(dx * dx + dy * dy);
                var pathDistance = current.pathDistance + neighborDistance;
                if (pathDistance < neighbour.pathDistance) {
                    neighbour.pathDistance = pathDistance;
                    neighbour.totalScore = neighbour.pathDistance + neighbour.distanceToTarget;
                    if (neighbour.openIndex == -1) {
                        insert(neighbour);
                    } else {
                        update(neighbour);
                    }
                }
            }

            checkNeighbour( current.a);
            checkNeighbour( current.b);
            checkNeighbour( current.c);
            if (current.d != null)
                checkNeighbour( current.d);
        }

        return false;
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
        return finder;
    }
}