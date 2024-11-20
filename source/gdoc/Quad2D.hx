package gdoc;

class Quad2D extends Prim2D {
	public function new(a:Point2D, b:Point2D, c:Point2D, d:Point2D) {
		this.a = a;
		this.b = b;
		this.c = c;
        this.d = d;
	}

    public inline function calculateArea():Float {    
        // Apply the Shoelace Formula
        var area = Math.abs(calculateSignedArea());
    
        return area;
    }

    public function calculateSignedArea():Float {    
        // Apply the Shoelace Formula
        var area = 
            ((a.x * b.y + b.x * c.y + c.x * d.y + d.x * a.y) -
            (a.y * b.x + b.y * c.x + c.y * d.x + d.y * a.x))
        / 2;
    
        return area;
    }

	public function getEdgesUndirected():Array<Edge2D> {
		return [ Edge2D.fromPointsUndirected(a, b), Edge2D.fromPointsUndirected(b, c), Edge2D.fromPointsUndirected(c, d), Edge2D.fromPointsUndirected(d, a)];
	}

    public function getEdgesDirected():Array<Edge2D> {
		return [ Edge2D.fromPointsDirected(a, b), Edge2D.fromPointsDirected(b, c), Edge2D.fromPointsDirected(c, d), Edge2D.fromPointsDirected(d, a)];
	}

    static inline final EPSILON = 1e-12;

	public function toString():String {
		return 'Quad2D(${a}, ${b}, ${c}, ${d})';
	}

    public function hasPointRef(p:Point2D):Bool {
        return a == p || b == p || c == p || d == p;
    }
    public function hasPointVal(p:Point2D):Bool {
        return a.eqval(p) || b.eqval(p) || c.eqval(p) || d.eqval(p);
    }

    public inline function flipQuad() {
        var tmp = b;
        b = d;
        d = tmp;
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



    public inline function calculateCenter() {
        return new Point2D((a.x + b.x + c.x + d.x) * 0.25, (a.y + b.y + c.y + d.y) * 0.25);
    }
    public inline function getOppositePointByRef( p : Point2D ) {
        if (a == p) return c;
        if (b == p) return d;
        if (c == p) return a;
        if (d == p) return b;
        return null;
    }
    public inline function getPointIndex( p : Point2D ) {
        if (a == p) return 0;
        if (b == p) return 1;
        if (c == p) return 2;
        if (d == p) return 3;
        return -1;
    }
}
