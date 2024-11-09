package gdoc;

class TriEdge2D extends Edge2D {
    public var faceA:Triangle2D;
    public var faceB:Triangle2D;

    public inline function new() {
        super();
    }

    public inline function addFace(face:Triangle2D) {
        if (faceA == null) {
            faceA = face;
        } else if (faceB == null) {
            faceB = face;
        } else {
            throw "TriEdge2D.addFace: Edge already has two faces";
        }
    }
}

class TriangleConnectivity2D {
    public inline function new() {

    }
    var _pointToID = new Map<Point2D, Int>();
    var _pointCount = 0;
    var _edgeMap = new Map<Int, TriEdge2D>();
    var _vertEdges = new Map<Point2D, Array<TriEdge2D>>();

    public var vertIt(get, never):Iterator<Point2D>;
    inline function get_vertIt() {
        return _pointToID.keys();
    }
    public var edgeIt(get, never):Iterator<TriEdge2D>;
    inline function get_edgeIt() {
        return _edgeMap.iterator();
    }

    public inline function getPointID(p:Point2D) : Int{
		return  _pointToID.get(p);
	}

	public inline function getOrAddPoint(p:Point2D) : Int{
        var id = _pointToID.get(p);
        if (id == null) {
            id = _pointCount++;
            _pointToID.set(p, id);
        }
		return id;
	}

    inline function getEdgeKeyFromPoints(a:Point2D, b:Point2D) {
		var aid = getOrAddPoint(a);
		var bid = getOrAddPoint(b);
		if (aid < bid) {
			return (aid << 16) | bid;
		} else {
			return (bid << 16) | aid;
		}
	}

    inline function addEdgeToVertex(v:Point2D, edge:TriEdge2D) {
        var edges = _vertEdges.get(v);
        if (edges == null) {
            edges = new Array<TriEdge2D>();
            _vertEdges.set(v, edges);
        }
        edges.push(edge);
    }

    public inline function getEdgeCount(v:Point2D) {
        var edges = _vertEdges.get(v);
        if (edges == null) {
            return 0;
        }
        return edges.length;
    }

    public function getOrCreateEdgeFromPoints(a:Point2D, b:Point2D):TriEdge2D {
        var key = getEdgeKeyFromPoints(a, b);

        var edge = _edgeMap.get(key);
        if (edge == null) {
            edge = new TriEdge2D();
            edge.setFromPointsUndirected(a, b);
            _edgeMap.set(key, edge);

            addEdgeToVertex(a, edge);
            addEdgeToVertex(b, edge);
        }

        return edge;
    }

    public function addTriangle(t : Triangle2D) {
        var edgeA = getOrCreateEdgeFromPoints(t.a, t.b);
        edgeA.addFace(t);
        var edgeB = getOrCreateEdgeFromPoints(t.b, t.c);
        edgeB.addFace(t);
        var edgeC = getOrCreateEdgeFromPoints(t.c, t.a);
        edgeC.addFace(t);
    }

    public function getOppositeTriangle( t : Triangle2D, a : Point2D, b : Point2D) : Triangle2D {
        var edge = _edgeMap.get(getEdgeKeyFromPoints(a, b));
        if (edge == null) {
            return null;
        }
        if (edge.faceA == t) {
            return edge.faceB;
        } else if (edge.faceB == t) {
            return edge.faceA;
        } else {
            throw "TriangleConnectivity2D.getOppositeTriangle: Edge does not belong to triangle";
        }
    }

    public static function fromTriangles(triangles : Array<Triangle2D>) : TriangleConnectivity2D {
        var connectivity = new TriangleConnectivity2D();
        for (t in triangles) {
            connectivity.addTriangle(t);
        }
        return connectivity;
    }
}