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

	// public inline function containsPoint(point:Point2D):Bool {
	// 	return triangleContainsPoint(point, a, b, c);
	// }

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

    public function containsPoint(p: Point2D): Bool {
        var x = p.x;
        var y = p.y;
        var x1 = this.a.x;
        var y1 = this.a.y;
        var x2 = this.b.x;
        var y2 = this.b.y;
        var x3 = this.c.x;
        var y3 = this.c.y;
        
        var denom = (y2 - y3)*(x1 - x3) + (x3 - x2)*(y1 - y3);
        if (denom == 0) {
            return false; // Degenerate triangle
        }
        var a = ((y2 - y3)*(x - x3) + (x3 - x2)*(y - y3)) / denom;
        var b = ((y3 - y1)*(x - x3) + (x1 - x3)*(y - y3)) / denom;
        var c = 1 - a - b;
        
        return a >= 0 && a <= 1 && b >= 0 && b <= 1 && c >= 0 && c <= 1;
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


    public function intersectsLineSegment(p1:Point2D, p2:Point2D):Bool {        
        if (containsPoint(p1) || containsPoint(p2)) {
            return true; 
        }

        if (Line2D.segmentsIntersect(p1, p2, a, b) || Line2D.segmentsIntersect(p1, p2, b, c) || Line2D.segmentsIntersect(p1, p2, c, a)) {
            return true;
        }
                
        return false; 
    }

    
    public function overlapsCircle(center:Point2D, radius:Float):Bool {
        var r2 = (radius + EPSILON) * (radius + EPSILON);

        if (a.withinSqared(center, r2)) return true;
        if (b.withinSqared(center, r2)) return true;
        if (c.withinSqared(center, r2)) return true;
        
        if (containsPoint(center)) return true;

        if (Line2D.segmentIntersectsCircle(a, b, center, radius)) return true;
        if (Line2D.segmentIntersectsCircle(b, c, center, radius)) return true;
        if (Line2D.segmentIntersectsCircle(c, a, center, radius)) return true;
        
        return false; 
    }

    public function overlapsThickSegment(segStart:Point2D, segEnd:Point2D, distance:Float):Bool {
        if (intersectsLineSegment(segStart, segEnd)) {
            return true; 
        }
        // Check if any vertex of the triangle is within the specified distance from the segment
        if (Line2D.segmentDistanceToPoint(segStart, segEnd, this.a) <= distance) return true;
        if (Line2D.segmentDistanceToPoint(segStart, segEnd, this.b) <= distance) return true;
        if (Line2D.segmentDistanceToPoint(segStart, segEnd, this.c) <= distance) return true;
        
        // Check if any endpoint of the segment lies within the specified distance from the triangle
        // This involves checking the distance from the segment endpoints to the triangle's edges
        if (Line2D.segmentDistanceToSegment(a, b, segStart, segEnd) <= distance) return true;
        if (Line2D.segmentDistanceToSegment(b, c, segStart, segEnd) <= distance) return true;
        if (Line2D.segmentDistanceToSegment(c, a, segStart, segEnd) <= distance) return true;
        
                
        return false; 
    }

}
