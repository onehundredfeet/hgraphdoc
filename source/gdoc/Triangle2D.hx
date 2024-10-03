package gdoc;

class Triangle2D {
	public var a:Point2D;
	public var b:Point2D;
	public var c:Point2D;

	public function new(a:Point2D, b:Point2D, c:Point2D) {
		this.a = a;
		this.b = b;
		this.c = c;
	}

	public function getEdges():Array<Edge2D> {
		return [new Edge2D(a, b), new Edge2D(b, c), new Edge2D(c, a)];
	}

	public inline function containsPoint(point:Point2D):Bool {
		return triangleContainsPoint(point, a, b, c);
	}

	public static function triangleContainsPoint(point:Point2D, a:Point2D, b:Point2D, c:Point2D):Bool {
		var b1 = Point2D.orientation(a, b, point) < 0.0;
		var b2 = Point2D.orientation(b, c, point) < 0.0;
		var b3 = Point2D.orientation(c, a, point) < 0.0;
		return ((b1 == b2) && (b2 == b3));
	}

	public function toString():String {
		return 'Triangle2D(${a}, ${b}, ${c})';
	}

	public function circumCircleContains(p:Point2D):Bool {
		var ax = a.x - p.x;
		var ay = a.y - p.y;
		var bx = b.x - p.x;
		var by = b.y - p.y;
		var cx = c.x - p.x;
		var cy = c.y - p.y;

		var det = (ax * ax
			+ ay * ay) * (bx * cy - cx * by)
			- (bx * bx + by * by) * (ax * cy - cx * ay)
			+ (cx * cx + cy * cy) * (ax * by - bx * ay);
		return det > 0;
	}

    public function hasPointRef(p:Point2D):Bool {
        return a == p || b == p || c == p;
    }
    public function hasPointVal(p:Point2D):Bool {
        return a.eqval(p) || b.eqval(p) || c.eqval(p);
    }
	public function hasEdgeByRef(p1:Point2D, p2:Point2D):Bool {
		return (a == p1 && b == p2) || (b == p1 && c == p2) || (c == p1 && a == p2);
	}

	public function hasEdgeByVal(p1:Point2D, p2:Point2D):Bool {
		return (a.eqval(p1) && b.eqval(p2)) || (b.eqval(p1) && c.eqval(p2)) || (c.eqval(p1) && a.eqval(p2));
	}

	public function getOppositePointByRef(p1:Point2D, p2:Point2D):Point2D {
		if (a != p1 && a != p2) {
			return a;
		}
		if (b != p1 && b != p2) {
			return b;
		}
		return c;
	}

	public function getOppositePointByVal(p1:Point2D, p2:Point2D):Point2D {
		if (!a.eqval(p1) && !a.eqval(p2)) {
			return a;
		}
		if (!b.eqval(p1) && !b.eqval(p2)) {
			return b;
		}
		return c;
	}

	public function findSharedEdge(other:Triangle2D):Edge2D {
		var sharedPoints = [];
		if (this.a == other.a || this.a == other.b || this.a == other.c)
			sharedPoints.push(this.a);
		if (this.b == other.a || this.b == other.b || this.b == other.c)
			sharedPoints.push(this.b);
		if (this.c == other.a || this.c == other.b || this.c == other.c)
			sharedPoints.push(this.c);
		if (sharedPoints.length == 2)
			return new Edge2D(sharedPoints[0], sharedPoints[1]);
		return null;
	}

    public function eqvalCCW(t:Triangle2D):Bool {
        if (!isCounterClockwise()  || !t.isCounterClockwise()) {
            throw 'Triangles must be counter clockwise';
        }
        var aIsA = a.eqval(t.a);
        if (aIsA) {
            return b.eqval(t.b) && c.eqval(t.c);
        }
        var aIsB = a.eqval(t.b);
        if (aIsB) {
            return b.eqval(t.c) && c.eqval(t.a);
        }

        var aIsC = a.eqval(t.c);
        if (aIsC) {
            return b.eqval(t.a) && c.eqval(t.b);
        }

        return false;
    }

    public function eqvalUnordered(t:Triangle2D):Bool {
        var aIsA = a.eqval(t.a);
        if (aIsA) {
            if (b.eqval(t.b)) {
                return c.eqval(t.c);
            }
            if (b.eqval(t.c)) {
                return c.eqval(t.b);
            }
            return false;
        }
        var aIsB = a.eqval(t.b);
        if (aIsB) {
            if (b.eqval(t.a)) {
                return c.eqval(t.c);
            }
            if (b.eqval(t.c)) {
                return c.eqval(t.a);
            }
            return false;
        }

        var aIsC = a.eqval(t.c);
        if (aIsC) {
            if (b.eqval(t.a)) {
                return c.eqval(t.b);
            }
            if (b.eqval(t.b)) {
                return c.eqval(t.a);
            }
            return false;
        }
        return false;
    }

    public inline function isCounterClockwise():Bool {
        return Point2D.orientation(a, b, c) > 0;
    }
}
