package gdoc;

class Quad2D extends Prim2D {
	public function new(a:Point2D, b:Point2D, c:Point2D, d:Point2D) {
		this.a = a;
		this.b = b;
		this.c = c;
        this.d = d;
	}

    function calculateArea():Float {    
        // Apply the Shoelace Formula
        var area = Math.abs(
            (a.x * b.y + b.x * c.y + c.x * d.y + d.x * a.y) -
            (a.y * b.x + b.y * c.x + c.y * d.x + d.y * a.x)
        ) / 2;
    
        return area;
    }

	public function getEdgesUndirected():Array<Edge2D> {
		return [ Edge2D.fromPointsUndirected(a, b), Edge2D.fromPointsUndirected(b, c), Edge2D.fromPointsUndirected(c, d), Edge2D.fromPointsUndirected(d, a)];
	}

    public function getEdgesDirected():Array<Edge2D> {
		return [ Edge2D.fromPointsDirected(a, b), Edge2D.fromPointsDirected(b, c), Edge2D.fromPointsDirected(c, d), Edge2D.fromPointsDirected(d, a)];
	}

    static inline final EPSILON = 1e-12;

    public function containsPoint(p:Point2D): Bool {
        // Divide the quad into two triangles: (a, b, c) and (a, c, d)
        return Triangle2D.triangleContainsPoint(p, a, b, c) || Triangle2D.triangleContainsPoint(p, a, c, d);
    }

	public function toString():String {
		return 'Quad2D(${a}, ${b}, ${c}, ${d})';
	}

    public function hasPointRef(p:Point2D):Bool {
        return a == p || b == p || c == p || d == p;
    }
    public function hasPointVal(p:Point2D):Bool {
        return a.eqval(p) || b.eqval(p) || c.eqval(p) || d.eqval(p);
    }


    public function intersectsLineSegment(p1:Point2D, p2:Point2D):Bool {        
        if (containsPoint(p1) || containsPoint(p2)) {
            return true; 
        }

        if (Line2D.segmentsIntersect(p1, p2, a, b)) {
            return true;
        }
        if (Line2D.segmentsIntersect(p1, p2, b, c)) {
            return true;
        }
        if (Line2D.segmentsIntersect(p1, p2, c, d)) {
            return true;
        }
        if (Line2D.segmentsIntersect(p1, p2, d, a)) {
            return true;
        }

        return false; 
    }

    
    public function overlapsCircle(center:Point2D, radius:Float):Bool {
        var r2 = (radius + EPSILON) * (radius + EPSILON);

        if (a.withinSquaredXY(center.x,center.y, r2)) return true;
        if (b.withinSquaredXY(center.x,center.y, r2)) return true;
        if (c.withinSquaredXY(center.x,center.y, r2)) return true;
        if (d.withinSquaredXY(center.x,center.y, r2)) return true;
        
        if (containsPoint(center)) return true;

        if (Line2D.segmentIntersectsCircle(a, b, center.x, center.y,radius)) return true;
        if (Line2D.segmentIntersectsCircle(b, c, center.x, center.y,radius)) return true;
        if (Line2D.segmentIntersectsCircle(c, d, center.x, center.y,radius)) return true;
        if (Line2D.segmentIntersectsCircle(d, a, center.x, center.y,radius)) return true;
        
        return false; 
    }

    public function overlapsThickSegment(segStart:Point2D, segEnd:Point2D, distance:Float):Bool {
        if (intersectsLineSegment(segStart, segEnd)) {
            return true; 
        }
        // // Check if any vertex of the triangle is within the specified distance from the segment
        if (Line2D.segmentDistanceToPoint(segStart, segEnd, this.a) <= distance) return true;
        if (Line2D.segmentDistanceToPoint(segStart, segEnd, this.b) <= distance) return true;
        if (Line2D.segmentDistanceToPoint(segStart, segEnd, this.c) <= distance) return true;
        if (Line2D.segmentDistanceToPoint(segStart, segEnd, this.d) <= distance) return true;
        
        // Check if any endpoint of the segment lies within the specified distance from the triangle
        // This involves checking the distance from the segment endpoints to the triangle's edges
        // Something is wrong in here:
        // if (Line2D.segmentDistanceToSegment(a, b, segStart, segEnd) <= distance) return true;
        // if (Line2D.segmentDistanceToSegment(b, c, segStart, segEnd) <= distance) return true;
        // if (Line2D.segmentDistanceToSegment(c, a, segStart, segEnd) <= distance) return true;
        
                
        return false; 
    }

    public function calculateCenter() {
        return new Point2D((a.x + b.x + c.x + d.x) * 0.25, (a.y + b.y + c.y + d.y) * 0.25);
    }
}
