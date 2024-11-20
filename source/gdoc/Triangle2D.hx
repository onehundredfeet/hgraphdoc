package gdoc;

class Triangle2D extends Prim2D {

	public function new(a:Point2D, b:Point2D, c:Point2D) {
		this.a = a;
		this.b = b;
		this.c = c;
	}

    public function area():Float {
        var y1 = a.y;
        var y2 = b.y;
        var y3 = c.y;

        return Math.abs((a.x * (y2 - y3) +
                         b.x * (y3 - y1) +
                         c.x * (y1 - y2)) / 2);
    }

	public function getEdgesUndirected():Array<Edge2D> {
		return [ Edge2D.fromPointsUndirected(a, b), Edge2D.fromPointsUndirected(b, c), Edge2D.fromPointsUndirected(c, a)];
	}

    public function getEdgesDirected():Array<Edge2D> {
		return [ Edge2D.fromPointsDirected(a, b), Edge2D.fromPointsDirected(b, c), Edge2D.fromPointsDirected(c, a)];
	}

	public static function triangleContainsPoint(point:Point2D, a:Point2D, b:Point2D, c:Point2D):Bool {
		var b1 = Point2D.orientation(a, b, point) < 0.0;
		var b2 = Point2D.orientation(b, c, point) < 0.0;
		var b3 = Point2D.orientation(c, a, point) < 0.0;
		return ((b1 == b2) && (b2 == b3));
	}

    static inline final EPSILON = 1e-12;

    public function isDegenerate():Bool {
        return Math.abs((b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)) < EPSILON;
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

	public function findSharedEdgeUndirected(other:Triangle2D):Edge2D {
		var sharedPoints = [];
		if (this.a == other.a || this.a == other.b || this.a == other.c)
			sharedPoints.push(this.a);
		if (this.b == other.a || this.b == other.b || this.b == other.c)
			sharedPoints.push(this.b);
		if (this.c == other.a || this.c == other.b || this.c == other.c)
			sharedPoints.push(this.c);
		if (sharedPoints.length == 2)
			return Edge2D.fromPointsUndirected(sharedPoints[0], sharedPoints[1]);
		return null;
	}

    public function findSharedEdgeDirected(other:Triangle2D):Edge2D {
		var sharedPoints = [];
		if (this.a == other.a || this.a == other.b || this.a == other.c)
			sharedPoints.push(this.a);
		if (this.b == other.a || this.b == other.b || this.b == other.c)
			sharedPoints.push(this.b);
		if (this.c == other.a || this.c == other.b || this.c == other.c)
			sharedPoints.push(this.c);
		if (sharedPoints.length == 2)
			return Edge2D.fromPointsDirected(sharedPoints[0], sharedPoints[1]);
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

    
    public function overlapsCircle(center_x : Float, center_y : Float, radius:Float):Bool {
        var r2 = (radius + EPSILON) * (radius + EPSILON);

        if (a.withinSquaredXY(center_x,center_y, r2)) return true;
        if (b.withinSquaredXY(center_x,center_y, r2)) return true;
        if (c.withinSquaredXY(center_x,center_y, r2)) return true;
        
        if (containsXY(center_x, center_y)) return true;

        if (Line2D.segmentIntersectsCircle(a, b, center_x, center_y, radius)) return true;
        if (Line2D.segmentIntersectsCircle(b, c, center_x, center_y,radius)) return true;
        if (Line2D.segmentIntersectsCircle(c, a, center_x, center_y,radius)) return true;
        
        return false; 
    }

    public inline function calculateCenter() {
        return new Point2D((a.x + b.x + c.x) / 3, (a.y + b.y + c.y) / 3);
    }

    public function getAngleOpposite( a : Point2D, b : Point2D) {
        var c = getOppositePointByRef(a, b);

        var ca_x = a.x - c.x;
        var ca_y = a.y - c.y;
        var len_ca = Math.sqrt(ca_x * ca_x + ca_y * ca_y);

        var cb_x = b.x - c.x;
        var cb_y = b.y - c.y;
        var len_cb = Math.sqrt(cb_x * cb_x + cb_y * cb_y);

        return Math.acos((ca_x * cb_x + ca_y * cb_y) / (len_ca * len_cb));
    }
}


@:forward
abstract TriangleList2D ( Array<Triangle2D> ) from Array<Triangle2D> to Array<Triangle2D> {
    public inline function new(tris : Array<Triangle2D>) {
        this = tris;
    }
    public function conformCCW() {
        for (t in this) {
            if (!t.isCounterClockwise()) {
                var temp = t.b;
                t.b = t.c;
                t.c = temp;
            }
        }
    }
}