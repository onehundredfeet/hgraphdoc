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

	public inline function getOppositePointByRef(p:Point2D) {
		if (a == p) {
			return b;
		} else if (b == p) {
			return a;
		} else {
			throw "PrimEdge2D.getOppositePointByRef: Point does not belong to Edge";
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

	public inline function swapFace(face:Prim2D, newFace:Prim2D) {
		if (faceA == face) {
			faceA = newFace;
		} else if (faceB == face) {
			faceB = newFace;
		} else {
			throw "PrimEdge2D.swapFace: Edge does not belong to Prim";
		}
	}

	public inline function getSharedFace(e:PrimEdge2D):Prim2D {
		if (faceA == e.faceA || faceA == e.faceB) {
			return faceA;
		} else if (faceB == e.faceA || faceB == e.faceB) {
			return faceB;
		} else {
			return null;
		}
	}
    public inline function getSharedPoint( e : PrimEdge2D ) {
        if ( a == e.a || a == e.b ) {
            return a;
        } else if ( b == e.a || b == e.b ) {
            return b;
        } else {
            return null;
        }
    }

	// returns true if empty
	public inline function removeFaceFromEdge(face:Prim2D):Bool {
		if (faceA == face) {
			faceA = null;
			return faceB == null;
		} else if (faceB == face) {
			faceB = null;
			return faceA == null;
		} else {
			throw "PrimEdge2D.removeFaceFromEdge: Edge does not belong to Prim";
		}
	}

    public inline function getValidFace() {
        if ( faceA != null ) {
            return faceA;
        }
        if ( faceB != null ) {
            return faceB;
        }
        return null;
    }

    public function toString() {
        return 'PrimEdge2D(${a}, ${b})';
    }
}

class PrimConnectivity2D {
	public inline function new() {}

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

	public inline function getPointID(p:Point2D):Int {
		return _pointToID.get(p);
	}

	public inline function getOrAddPoint(p:Point2D):Int {
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

	public function addPrim(p:Prim2D) {
		var edgeA = getOrCreateEdgeFromPoints(p.a, p.b);
		edgeA.addFace(p);
		var edgeB = getOrCreateEdgeFromPoints(p.b, p.c);
		edgeB.addFace(p);
		if (p is Triangle2D) {
			var t:Triangle2D = cast p;
			var edgeC = getOrCreateEdgeFromPoints(t.c, p.a);
			edgeC.addFace(p);
		} else if (p is Quad2D) {
			var q:Quad2D = cast p;
			var edgeC = getOrCreateEdgeFromPoints(q.c, q.d);
			edgeC.addFace(p);
			var edgeD = getOrCreateEdgeFromPoints(q.d, q.a);
			edgeD.addFace(p);
		}
	}

	public function getOppositePrim(p:Prim2D, a:Point2D, b:Point2D):Prim2D {
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

	public function getNeighbours(prim:Prim2D):Array<Prim2D> {
		var edgeA = getEdgeFromPoints(prim.a, prim.b);
		var edgeB = getEdgeFromPoints(prim.b, prim.c);
		if (prim is Triangle2D) {
			var t:Triangle2D = cast prim;
			var edgeC = getEdgeFromPoints(t.c, prim.a);
			return [edgeA.getOppositeFace(prim), edgeB.getOppositeFace(prim), edgeC.getOppositeFace(prim)];
		} else if (prim is Quad2D) {
			var q:Quad2D = cast prim;
			var edgeC = getEdgeFromPoints(q.c, q.d);
			var edgeD = getEdgeFromPoints(q.d, prim.a);
			return [
				edgeA.getOppositeFace(prim),
				edgeB.getOppositeFace(prim),
				edgeC.getOppositeFace(prim),
				edgeD.getOppositeFace(prim)
			];
		}
		return null;
	}

	public static function fromPrims(prims:Array<Prim2D>):PrimConnectivity2D {
		var connectivity = new PrimConnectivity2D();
		for (p in prims) {
			connectivity.addPrim(p);
		}
		return connectivity;
	}

	public function disolveEdge(e:PrimEdge2D) {
		if (e.faceA == null || e.faceB == null) {
			throw "PrimConnectivity2D.disolveEdge: Edge must have two faces";
		}

		var a = e.a;
		var b = e.b;

		if (e.faceA.isQuad() || e.faceB.isQuad()) {
			throw "PrimConnectivity2D.disolveEdge: Faces must be triangles";
		}

		var edgeKey = getEdgeKeyFromPoints(a, b);
		var edge = _edgeMap.get(edgeKey);

		function swapPrimOnEdge(swapEdge:PrimEdge2D, oldTri:Prim2D, newPrim:Prim2D) {
			if (swapEdge != edge) {
				swapEdge.swapFace(oldTri, newPrim);
			}
		}
		function substitutePrim(newPrim:Prim2D, oldTri:Prim2D) {
			swapPrimOnEdge(getEdgeFromPoints(oldTri.a, oldTri.b), oldTri, newPrim);
			swapPrimOnEdge(getEdgeFromPoints(oldTri.b, oldTri.c), oldTri, newPrim);
			swapPrimOnEdge(getEdgeFromPoints(oldTri.c, oldTri.a), oldTri, newPrim);
		}

		var ta:Triangle2D = cast e.faceA;
		var tb:Triangle2D = cast e.faceB;

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

	public function isVertexExternal(v:Point2D) {
		var edges = _vertEdges.get(v);
		if (edges == null) {
			return true;
		}
		for (e in edges) {
			if (e.faceA == null || e.faceB == null) {
				return true;
			}
		}
		return false;
	}

	function _removeEdgeFromVertex(v:Point2D, e:PrimEdge2D) {
		var vaedges = _vertEdges.get(v);
        if (vaedges != null) {
            vaedges.remove(e);
            if (vaedges.length == 0) {
                _vertEdges.remove(v);
                _pointToID.remove(v);
            }    
        } else {
            _pointToID.remove(v);
        }
	}

    function _removeEdge( e : PrimEdge2D ) {
        var edgeKey = getEdgeKeyFromPoints(e.a, e.b);
        _edgeMap.remove(edgeKey);
        _removeEdgeFromVertex(e.a, e);
        _removeEdgeFromVertex(e.b, e);
    }
    
	public function removeFace(f:Prim2D) {
		function removeFaceFromEdge(e:PrimEdge2D) {
			if (e.removeFaceFromEdge(f)) {
                _removeEdge(e);
			}
		}
		removeFaceFromEdge(getEdgeFromPoints(f.a, f.b));
		removeFaceFromEdge(getEdgeFromPoints(f.b, f.c));

		if (f.isQuad()) {
			removeFaceFromEdge(getEdgeFromPoints(f.c, f.d));
			removeFaceFromEdge(getEdgeFromPoints(f.d, f.a));
		} else {
			removeFaceFromEdge(getEdgeFromPoints(f.c, f.a));
		}
	}

	public function disolveVertex(v:Point2D) {
		if (isVertexExternal(v)) {
			throw "PrimConnectivity2D.disolveVertex: Vertex is external";
		}
		var edges = _vertEdges.get(v);
		if (edges == null) {
			throw "PrimConnectivity2D.disolveVertex: Vertex has no edges";
		}

		var faces = getFacesAroundVert(v);

		var verts = new Array<Point2D>();
		inline function addVert(pv:Point2D) {
			if (pv != v && !verts.contains(pv)) {
				verts.push(pv);
			}
		}
		// collect all permiter vertices
		for (f in faces) {
			addVert(f.a);
			addVert(f.b);
			addVert(f.c);
			if (f.isQuad()) {
				addVert(f.d);
			}
		}

		if (verts.length < 3) {
			throw "PrimConnectivity2D.disolveVertex: Vertex has less than 3 perimeter vertices";
		} else if (verts.length > 4) {
			throw "PrimConnectivity2D.disolveVertex: Vertex has more than 4 perimeter vertices";
		}

		Point2D.sortPointsCCWAroundCenter(v, verts);

        // Remove existing faces
		for (f in faces) {
			removeFace(f);
		}

        // Create new primitive
		var newPrim = verts.length == 3 ? new Triangle2D(verts[0], verts[1], verts[2]) : new Quad2D(verts[0], verts[1], verts[2], verts[3]);
		addPrim(newPrim);
		return newPrim;
	}

    function getEdgesAroundFace( p : Prim2D ) {        
        return p.isQuad() ? 
        [getEdgeFromPoints(p.a, p.b), getEdgeFromPoints(p.b, p.c), getEdgeFromPoints(p.c, p.d), getEdgeFromPoints(p.d, p.a)] : 
        [getEdgeFromPoints(p.a, p.b), getEdgeFromPoints(p.b, p.c), getEdgeFromPoints(p.c, p.a)];
    }



    public function collapseEdge( a: Point2D, b:Point2D ) {
        var edge = getEdgeFromPoints(a, b);
        var edgePoints = [a,b];      
        function getEdgesAroundFaceExcept( p : Prim2D ) {
            var edges = getEdgesAroundFace(p);
            for (i in 0...edges.length) {
                if (edges[i] == edge) {
                    edges[i] = null;
                    break;
                }
            }
            return edges;
        }

        var aEdgesWithout = getEdgesAroundVert(a).filter(function(e) return e != edge);
        var bEdgesWithout = getEdgesAroundVert(b).filter(function(e) return e != edge);


        var faceAEdges = getEdgesAroundFaceExcept(edge.faceA);
        var faceBEdges = getEdgesAroundFaceExcept(edge.faceB);
        
        var faceANullIdx = faceAEdges.indexOf(null);
        var faceBNullIdx = faceBEdges.indexOf(null);

        trace('edge faces ${edge.faceA} ${edge.faceB}');

        var faceA = edge.faceA;
        var faceB = edge.faceB;

        var otherFacesAroundA = getFacesAroundVert(a).filter(function(f) return f != faceA && f != faceB);
        var otherFacesAroundB = getFacesAroundVert(b).filter(function(f) return f != faceA && f != faceB);

        // the common edge will be removed
        removeFace(edge.faceA);
        removeFace(edge.faceB);

        if (faceA.d == null && faceB.d == null && otherFacesAroundA.length == 0 && otherFacesAroundB.length == 0) {
            trace('Empty graph');
            return;
        }

        // make a list of the edges to point at the new vertex
        var modifiedEdges = [];
        for (p in edgePoints) {
            var edges = getEdgesAroundVert(p);
            if (edges != null) {
                for (e in edges) {
                    modifiedEdges.push(e);
                }
            }
        }

        var modifiedFaces = [];
        for (e in modifiedEdges) {
            if (e.faceA != null && !modifiedFaces.contains(e.faceA)) {
                modifiedFaces.push(e.faceA);
            }
            if (e.faceB != null && !modifiedFaces.contains(e.faceB)) {
                modifiedFaces.push(e.faceB);
            }
        }

        // Make the new midpoint & rewrite the existing faces
        var newPoint = new Point2D((a.x + b.x) / 2, (a.y + b.y) / 2);
                
        // May be a little wasteful but the simplicity is worth it (i'm not sure it's that wasteful)
        for (f in modifiedFaces) {
            removeFace(f);
            var count = f.getVertCount();
            for (vi in 0...count) {
                var v = f.arrayGet(vi);
                if (v == a || v == b) {
                    f.arraySet(vi, newPoint);
                }
            }
            addPrim(f);
        }

        function convertQuadToTri( q : Prim2D ) {
            var newPoints = [];
            for (i in 0...q.getVertCount()) {
                var p = q.arrayGet(i);
                if (p == a || p == b) {
                    p = newPoint;
                }
                if (newPoints.contains(p)) {
                    continue;
                }
                newPoints.push(p);
            }
            if (newPoints.length == 3) {
                addPrim(new Triangle2D(newPoints[0], newPoints[1], newPoints[2]));
            } else {
                throw 'Invalid quad reduction ${newPoints} ${q}';
            }
        }
        if (faceA.isQuad()) {
            convertQuadToTri(faceA);
        }
        if (faceB.isQuad()) {
            convertQuadToTri(faceB);
        }
    }
	public inline function getEdgesAroundVert(p:Point2D) {
		return _vertEdges.get(p);
	}

	public function getFacesAroundVert(p:Point2D) {
		var edges = _vertEdges.get(p);
		if (edges == null) {
			return null;
		}
		var faces = [];
		for (e in edges) {
			if (e.faceA != null) {
				if (!faces.contains(e.faceA)) {
					faces.push(e.faceA);
				}
			}
			if (e.faceB != null) {
				if (!faces.contains(e.faceB)) {
					faces.push(e.faceB);
				}
			}
		}
		return faces;
	}

	public function gatherFaces():Array<Prim2D> {
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

	public function getSubdivided():PrimConnectivity2D {
		var prims = gatherFaces();

		var edges:Array<PrimEdge2D> = [for (e in _edgeMap) e];

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
				var q:Quad2D = cast p;
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

	public function walkConnectedFaces(f:Prim2D, cb:Prim2D->Void) {
		inline function cbwrap(e:PrimEdge2D) {
			if (e != null) {
				var of = e.getOppositeFace(f);
				if (of != null) {
					cb(of);
				}
			}
		}
		cbwrap(_edgeMap.get(getEdgeKeyFromPoints(f.a, f.b)));
		cbwrap(_edgeMap.get(getEdgeKeyFromPoints(f.b, f.c)));

		if (f.isQuad()) {
			cbwrap(_edgeMap.get(getEdgeKeyFromPoints(f.c, f.d)));
			cbwrap(_edgeMap.get(getEdgeKeyFromPoints(f.d, f.a)));
		} else {
			cbwrap(_edgeMap.get(getEdgeKeyFromPoints(f.c, f.a)));
		}
	}

	public function getSortedEdgesAroundVertex(origin:Point2D) {
		var edges = _vertEdges.get(origin);

		// sorting in place as order doesn't matter - questionable justification
		edges.sort(function(a:PrimEdge2D, b:PrimEdge2D):Int {
			var edgeAP = a.getOppositePointByRef(origin);
			var edgeBP = b.getOppositePointByRef(origin);
			var angleA = Math.atan2(edgeAP.y - origin.y, edgeAP.x - origin.x);
			var angleB = Math.atan2(edgeBP.y - origin.y, edgeBP.x - origin.x);

			if (angleA < 0)
				angleA += Math.PI * 2;
			if (angleB < 0)
				angleB += Math.PI * 2;

			if (angleA < angleB)
				return -1;
			else if (angleA > angleB)
				return 1;
			else
				return 0;
		});
		return edges;
	}
}
