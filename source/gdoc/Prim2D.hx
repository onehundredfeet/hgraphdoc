package gdoc;

class Prim2D {
    public var a:Point2D;
	public var b:Point2D;
	public var c:Point2D;
    public var d:Point2D;

    public inline function toPrim() : Prim2D{
        return this;
    }

    public inline function getVertCount() : Int {
        return d == null ? 3 : 4;
    }

    public inline function isQuad() : Bool {
        return d != null;
    }

    public inline function isTriangle() : Bool {
        return d == null;
    }

    public inline function getPoint(idx:Int) : Point2D {
        return switch(idx) {
            case 0: a;
            case 1: b;
            case 2: c;
            case 3: d;
            default: throw "Invalid index";
        }
    }
    public inline function getPointSafe(idx:Int) : Point2D {
        var vc = getVertCount();
        while (idx < 0) idx += vc;
        while (idx >= vc) idx = idx % vc;
        return getPoint(idx);
    }

    public inline function isCCW() {
        if (d == null) {
            return Point2D.orientation(a, b, c) > 0;
        }
        var areax2 = 
        (a.x * b.y + b.x * c.y + c.x * d.y + d.x * a.y) -
        (a.y * b.x + b.y * c.x + c.y * d.x + d.y * a.x);
        return areax2 > 0;
        // // Quadrilateral case: Compute the signed area of the entire polygon
        // var area = 0.0;

        // // Sum the signed area using the shoelace formula (determinant method)
        // area += a.x * b.y - b.x * a.y; // Edge a -> b
        // area += b.x * c.y - c.x * b.y; // Edge b -> c
        // area += c.x * d.y - d.x * c.y; // Edge c -> d
        // area += d.x * a.y - a.x * d.y; // Edge d -> a

        // // If the area is positive, the polygon is counterclockwise
        // return area > 0;
    }



    public inline function flip() {
        if (d == null) {
            var tmp = b;
            b = c;
            c = tmp;
        } else {
            var tmp = b;
            b = d;
            d = tmp;
        }
    }
    public function getEdgeIndexFromVerts(oa : Point2D, ob : Point2D) : Int {
        var l = getVertCount();

        for (i in 0...l) {
            if (getPoint(i) == oa) {
                final next = (i+1)%l;
                if (getPoint(next) == ob) return i;
                final prev = (i-1+l)%l;
                if (getPoint(prev) == ob) return prev;
                break;
            }
        }
        return -1;
    }

    public function getVertexIndex(v : Point2D) : Int {
        if (v == a) return 0;
        if (v == b) return 1;
        if (v == c) return 2;
        if (d != null && v == d) return 3;
        return -1;
    }
    
    public function getSharedEdgeLocalIndex(foreignPrim : Prim2D, foreignEdge:Int) : Int {
        var fa = foreignPrim.getPoint(foreignEdge);
        var fb = foreignPrim.getPoint((foreignEdge + 1) % foreignPrim.getVertCount());

        return getEdgeIndexFromVerts(fa, fb);
    }
    public function getCentroid() : Point2D {
        var x = 0.0;
        var y = 0.0;
        
        x = a.x + b.x + c.x;
        y = a.y + b.y + c.y;
        if (d != null) {
            x += d.x;
            y += d.y;
            return new Point2D(x/4, y/4);
        }
        return new Point2D(x/3, y/3);
    }

    public function getInteriorAngles() : Array<Float> 
    {
        if (d == null) {
            return [
                Point2D.angleBetweenPoints(a, b, c),
                Point2D.angleBetweenPoints(b, c, a),
                Point2D.angleBetweenPoints(c, a, b)
            ];
        }
        return [
            Point2D.angleBetweenCCPoints(a, d, b),
            Point2D.angleBetweenCCPoints(b, a, c),
            Point2D.angleBetweenCCPoints(c, b, d),
            Point2D.angleBetweenCCPoints(d, c, a)
        ];
    }
    public inline function arrayGet(n:Int) {
        return switch(n) {
            case 0: a;
            case 1: b;
            case 2: c;
            case 3: d != null ? d : throw "Invalid index";
            default: throw "Invalid index";
        }
    }

    public function arraySet(n:Int, v:Point2D) {
        switch(n) {
            case 0: a = v;
            case 1: b = v;
            case 2: c = v;
            case 3: d = v;
            default: throw "Invalid index";
        }
    }

    public function getOtherPoints(p : Point2D) : Array<Point2D> {
        var result = new Array<Point2D>();
        for (i in 0...getVertCount()) {
            var v = getPoint(i);
            if (v != p) {
                result.push(v);
            }
        }
        return result;
    }

    public function containsEdge(a : Point2D, b : Point2D) : Bool {
        for (i in 0...getVertCount()) {
            if (getPoint(i) == a) {
                if (getPointSafe(i + 1) == b) return true;
                if (getPointSafe(i - 1) == b) return true;
                break;
            }
        }
        return false;
    }

}