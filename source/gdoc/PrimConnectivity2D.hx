package gdoc;

import gdoc.Prim2D;

class PrimEdge2D extends Edge2D {
    public var faceA:Prim2D;
    public var faceB:Prim2D;

    public inline function new() {
        super();
    }

    public inline function addFace(face:Prim2D) {
        if (faceA == null) {
            faceA = face;
        } else if (faceB == null) {
            faceB = face;
        } else {
            throw "PrimEdge2D.addFace: Edge already has two faces";
        }
    }

    public inline function getOppositeFace(face:Prim2D) {
        if (faceA == face) {
            return faceB;
        } else if (faceB == face) {
            return faceA;
        } else {
            throw "PrimEdge2D.getOppositeFace: Edge does not belong to Prim";
        }
    }
}

class PrimConnectivity2D {
    public inline function new() {

    }
    var _pointToID = new Map<Point2D, Int>();
    var _pointCount = 0;
    var _edgeMap = new Map<Int, PrimEdge2D>();

    public var vertIt(get, never):Iterator<Point2D>;
    inline function get_vertIt() {
        return _pointToID.keys();
    }
    public var edgeIt(get, never):Iterator<PrimEdge2D>;
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

    inline public function getEdgeFromPoints(a:Point2D, b:Point2D):PrimEdge2D {
        return _edgeMap.get(getEdgeKeyFromPoints(a, b));
    }

    public function getOrCreateEdgeFromPoints(a:Point2D, b:Point2D):PrimEdge2D {
        var key = getEdgeKeyFromPoints(a, b);

        var edge = _edgeMap.get(key);
        if (edge == null) {
            edge = new PrimEdge2D();
            edge.setFromPointsUndirected(a, b);
            _edgeMap.set(key, edge);
        }

        return edge;
    }

    public function addPrim(p : Prim2D) {
        var edgeA = getOrCreateEdgeFromPoints(p.a, p.b);
        edgeA.addFace(p);
        var edgeB = getOrCreateEdgeFromPoints(p.b, p.c);
        edgeB.addFace(p);
        if (p is Triangle2D) {
            var t : Triangle2D = cast p;
            var edgeC = getOrCreateEdgeFromPoints(t.c, p.a);
            edgeC.addFace(p);
        } else if (p is Quad2D) {
            var q : Quad2D = cast p;
            var edgeC = getOrCreateEdgeFromPoints(q.c, q.d);
            edgeC.addFace(p);
            var edgeD = getOrCreateEdgeFromPoints(q.d, q.a);
            edgeD.addFace(p);
        }
    }

    public function getOppositePrim( p : Prim2D, a : Point2D, b : Point2D) : Prim2D {
        var edge = _edgeMap.get(getEdgeKeyFromPoints(a, b));
        if (edge == null) {
            return null;
        }
        if (edge.faceA == p) {
            return edge.faceB;
        } else if (edge.faceB == p) {
            return edge.faceA;
        } else {
            throw "PrimConnectivity2D.getOppositePrim: Edge does not belong to Prim";
        }
    }

    public function getNeighbours(prim : Prim2D) : Array<Prim2D> {
        var edgeA = getEdgeFromPoints(prim.a, prim.b);
        var edgeB = getEdgeFromPoints(prim.b, prim.c);
        if (prim is Triangle2D) {
            var t : Triangle2D = cast prim;
            var edgeC = getEdgeFromPoints(t.c, prim.a);
            return [edgeA.getOppositeFace(prim), edgeB.getOppositeFace(prim), edgeC.getOppositeFace(prim)];
        } else if (prim is Quad2D) {
            var q : Quad2D = cast prim;
            var edgeC = getEdgeFromPoints(q.c, q.d);
            var edgeD = getEdgeFromPoints(q.d, prim.a);
            return [edgeA.getOppositeFace(prim), edgeB.getOppositeFace(prim), edgeC.getOppositeFace(prim), edgeD.getOppositeFace(prim)];
        }
        return null;
    }

    public static function fromPrims(prims : Array<Prim2D>) : PrimConnectivity2D {
        var connectivity = new PrimConnectivity2D();
        for (p in prims) {
            connectivity.addPrim(p);
        }
        return connectivity;
    }
}