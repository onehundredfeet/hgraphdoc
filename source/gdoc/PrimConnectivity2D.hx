package gdoc;

import haxe.Int64;
import gdoc.Prim2D;

typedef EdgeKeyInt = haxe.Int64;
typedef EdgeKeyMapType = hl.types.Int64Map;

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

    public function swapFace(face:Prim2D, newFace:Prim2D) {
        if (faceA == face) {
            faceA = newFace;
        } else if (faceB == face) {
            faceB = newFace;
        } else {
            throw "PrimEdge2D.swapFace: Edge does not belong to Prim";
        }
    }
}

class PrimConnectivity2D {
    public inline function new() {

    }
    var _pointToID = new Map<Point2D, Int>();
    var _pointCount = 0;
    var _edgeMap = new EdgeKeyMapType();
    var _vertEdges = new Map<Point2D, Array<PrimEdge2D>>();

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
			return Int64.make(aid, bid);
		} else {
			return Int64.make(bid, aid);
		}
	}

    inline function addEdgeToVertex(v:Point2D, edge:PrimEdge2D) {
        var edges = _vertEdges.get(v);
        if (edges == null) {
            edges = new Array<PrimEdge2D>();
            _vertEdges.set(v, edges);
        }
        edges.push(edge);
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

            addEdgeToVertex(a, edge);
            addEdgeToVertex(b, edge);
        }

        return edge;
    }
    public inline function getEdgeCount(v:Point2D) {
        var edges = _vertEdges.get(v);
        if (edges == null) {
            return 0;
        }
        return edges.length;
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

    public function disolveEdge( e : PrimEdge2D) {       
        if (e.faceA == null || e.faceB == null) {
            throw "PrimConnectivity2D.disolveEdge: Edge must have two faces";
        }

        var a = e.a;
        var b = e.b;


        if (e.faceA.d != null || e.faceB.d != null) {
            throw "PrimConnectivity2D.disolveEdge: Faces must be triangles";
        }

        var edgeKey = getEdgeKeyFromPoints(a, b);
        var edge = _edgeMap.get(edgeKey);
        
        function swapPrimOnEdge( swapEdge : PrimEdge2D, oldTri : Prim2D, newPrim : Prim2D) {
            if (swapEdge != edge) {
                swapEdge.swapFace(oldTri, newPrim);
            }
        }
        function substitutePrim(newPrim : Prim2D, oldTri : Prim2D) {
            swapPrimOnEdge(getEdgeFromPoints(oldTri.a, oldTri.b), oldTri, newPrim);
            swapPrimOnEdge(getEdgeFromPoints(oldTri.b, oldTri.c), oldTri, newPrim);
            swapPrimOnEdge(getEdgeFromPoints(oldTri.c, oldTri.a), oldTri, newPrim);      
        }

        var ta : Triangle2D = cast e.faceA;
        var tb : Triangle2D = cast e.faceB;

        var quad = new Quad2D(e.a, ta.getOppositePointByRef(e.a, e.b), e.b, tb.getOppositePointByRef(e.a, e.b));

        if (!quad.isCCW()) {
            quad.flipQuad();

            if (!quad.isCCW()) {
                trace('area: ${quad.calculateSignedArea()}');
                trace('a: ${quad.a}');
                trace('b: ${quad.b}');
                trace('c: ${quad.c}');
                trace('d: ${quad.d}');

                throw 'PrimConnectivity2D.disolveEdge: Quad must be counter clockwise ${quad}';
            }
        }
        substitutePrim(quad, ta);
        substitutePrim(quad, tb);

        var edgeListA = _vertEdges.get(a);
        var edgeListB = _vertEdges.get(b);

        _edgeMap.remove(edgeKey);

        edgeListA.remove(e);
        edgeListB.remove(e);
    }

    public inline function getEdgesAroundVert(p:Point2D) {
        return _vertEdges.get(p);
    }

    public function gatherFaces() : Array<Prim2D> {
        var faces = new Map<Prim2D, Bool>();

        for (edge in _edgeMap) {
            if (edge.faceA != null) {
                faces.set(edge.faceA, true);
            }
            if (edge.faceB != null) {
                faces.set(edge.faceB, true);
            }
        }
        return [for (f in faces.keys()) f];
    }

    public function getSubdivided() : PrimConnectivity2D {
        var prims = gatherFaces();

        var edges : Array<PrimEdge2D> = [for (e in _edgeMap) e];
        
        // edgeVerts
        var edgeVerts = new Map<PrimEdge2D, Point2D>();
        for (e in edges) {
            edgeVerts.set(e, new Point2D((e.a.x + e.b.x) / 2, (e.a.y + e.b.y) / 2));
        }

        var primCentroids = new Map<Prim2D, Point2D>();
        for (p in prims) {
            primCentroids.set(p, p.getCentroid());
        }
        var newConnectivity = new PrimConnectivity2D();
        for (p in prims) {
            if (p is Triangle2D) {
                var ab = getEdgeFromPoints(p.a, p.b);
                var bc = getEdgeFromPoints(p.b, p.c);
                var ca = getEdgeFromPoints(p.c, p.a);

                // add 3 quads
                newConnectivity.addPrim(new Quad2D(p.a, edgeVerts.get(ab), primCentroids.get(p), edgeVerts.get(ca)));
                newConnectivity.addPrim(new Quad2D(p.b, edgeVerts.get(bc), primCentroids.get(p), edgeVerts.get(ab)));
                newConnectivity.addPrim(new Quad2D(p.c, edgeVerts.get(ca), primCentroids.get(p), edgeVerts.get(bc)));
            } else if (p is Quad2D) {
                var q : Quad2D = cast p;
                // add 4 quads
                var ab = getEdgeFromPoints(q.a, q.b);
                var bc = getEdgeFromPoints(q.b, q.c);
                var cd = getEdgeFromPoints(q.c, q.d);
                var da = getEdgeFromPoints(q.d, q.a);

                newConnectivity.addPrim(new Quad2D(q.a, edgeVerts.get(ab), primCentroids.get(q), edgeVerts.get(da)));
                newConnectivity.addPrim(new Quad2D(q.b, edgeVerts.get(bc), primCentroids.get(q), edgeVerts.get(ab)));
                newConnectivity.addPrim(new Quad2D(q.c, edgeVerts.get(cd), primCentroids.get(q), edgeVerts.get(bc)));
                newConnectivity.addPrim(new Quad2D(q.d, edgeVerts.get(da), primCentroids.get(q), edgeVerts.get(cd)));
            }
        }
        
        return newConnectivity;
    }
    
}