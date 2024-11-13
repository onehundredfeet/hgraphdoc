package gdoc;

// Define the Edge class
class Edge2D {
    public var a:Point2D;
    public var b:Point2D;

    public inline function new() {
        
    }

    public inline function getOtherPoint(p:Point2D):Point2D {
        if (a == p) return b;
        if (b == p) return a;
        return null;
    }
    public inline function clone():Edge2D {
        var edge = new Edge2D();
        edge.a = a;
        edge.b = b;
        return edge;
    }

    public inline function setFromPointsDirected(a:Point2D, b:Point2D) {
        this.a = a;
        this.b = b;
    }
    public static function fromPointsDirected(a:Point2D, b:Point2D) {
        var edge = new Edge2D();
        edge.a = a;
        edge.b = b;
        return edge;
    }

    public inline function setFromPointsUndirected(a:Point2D, b:Point2D) {
        // Ensure consistent ordering for comparison
        if (a.x < b.x || (a.x == b.x && a.y < b.y)) {
            this.a = a;
            this.b = b;
        } else {
            this.a = b;
            this.b = a;
        }
    }
    public static function fromPointsUndirected(a:Point2D, b:Point2D) {
        var edge = new Edge2D();
        edge.setFromPointsUndirected(a, b);
        return edge;
    }

    // Equality check based on points
    public function eqref(e:Edge2D):Bool {
        return (this.a == e.a && this.b == e.b) || (this.a == e.b && this.b == e.a);
    }

    public function eqrefdir(e:Edge2D):Bool {
        return (this.a == e.a && this.b == e.b);
    }

    public inline function eqval(e:Edge2D):Bool {
        return (a.eqval(e.a) && b.eqval(e.b)) || (a.eqval(e.b) && b.eqval(e.a));
    }

    public inline function eqvaldir(e:Edge2D):Bool {
        return (a.eqval(e.a) && b.eqval(e.b));
    }

    static inline final HASH_PRECISION = 1e5;
    static inline final MODULUS = 0x7FFFFFFF; // Example modulus for 32-bit systems
    
    public inline function getHash():Int {
        var prime1:Int = 23459;
        var prime2:Int = 54323;
        var prime3:Int = 67867; 
        
        // Scale and round coordinates to handle floating-point precision
        var aX:Int = Math.round(a.x * HASH_PRECISION);
        var aY:Int = Math.round(a.y * HASH_PRECISION);
        var bX:Int = Math.round(b.x * HASH_PRECISION);
        var bY:Int = Math.round(b.y * HASH_PRECISION);
        
        // Compute individual hashes for both points using the same primes
        var hashA:Int = (aX * prime1 + aY * prime2) % MODULUS;
        var hashB:Int = (bX * prime1 + bY * prime2) % MODULUS;
        
        // Combine the two hashes in a consistent order to ensure edge uniqueness
        if (hashA < hashB) {
            return ((hashA * prime3) ^ hashB) % MODULUS;
        } else {
            return ((hashB * prime3) ^ hashA) % MODULUS;
        }
    }
    
    public inline static function fromHashPoints(a:Point2D, b:Point2D):Int {
        return Std.int(a.x * 100000 + a.y) * 100000 + Std.int(b.x * 100000 + b.y);
    }

    public inline function distanceToPoint(p: Point2D): Float {
        return distanceToPointFromEdge( this.a, this.b, p);
    }

    public static function distanceToPointFromEdge(a : Point2D, b: Point2D, p: Point2D): Float {
        var dx = b.x - a.x;
        var dy = b.y - a.y;
    
        var lengthSquared = dx * dx + dy * dy;
    
        // Handle the case where A and B are the same point
        if (lengthSquared == 0) {
            var deltaX = a.x - p.x;
            var deltaY = a.y - p.y;
            return Math.sqrt(deltaX * deltaX + deltaY * deltaY);
        }
    
        // Compute the projection parameter t of point P onto segment AB
        var t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared;
    
        // Determine the closest point on the segment to point P
        if (t < 0) {
            // Closest to point A
            var deltaX = a.x - p.x;
            var deltaY = a.y - p.y;
            return Math.sqrt(deltaX * deltaX + deltaY * deltaY);
        } else if (t > 1) {
            // Closest to point B
            var deltaX = b.x - p.x;
            var deltaY = b.y - p.y;
            return Math.sqrt(deltaX * deltaX + deltaY * deltaY);
        } else {
            // Projection falls on the segment AB
            var projX = a.x + t * dx;
            var projY = a.y + t * dy;
            var deltaX = projX - p.x;
            var deltaY = projY - p.y;
            return Math.sqrt(deltaX * deltaX + deltaY * deltaY);
        }
    }
    
    public inline function intersects(e2a:Point2D, e2b:Point2D):Bool {
        return edgesIntersect(this.a, this.b, e2a, e2b);
    }

    public static function edgesIntersect(e1a:Point2D, e1b:Point2D, e2a:Point2D, e2b:Point2D):Bool {
        if (e1a == e2a || e1a == e2b || e1b == e2a || e1b == e2b) return false;

        var p = e1a;
        var b = e1b;
        var q = e2a;
        var q2 = e2b;

        var o1 = Point2D.orientation(p, b, q);
        var o2 = Point2D.orientation(p, b, q2);
        var o3 = Point2D.orientation(q, q2, p);
        var o4 = Point2D.orientation(q, q2, b);

        if (o1 != o2 && o3 != o4) return true;

        return false;
    }

    public static function edgesIntersectOverlapped(e1a:Point2D, e1b:Point2D, e2a:Point2D, e2b:Point2D):Bool {
        if (e1a == e2a || e1a == e2b || e1b == e2a || e1b == e2b) return false;
        
        var p = e1a;
        var b = e1b;
        var q = e2a;
        var q2 = e2b;

        var o1 = Point2D.orientation(p, b, q);
        var o2 = Point2D.orientation(p, b, q2);
        var o3 = Point2D.orientation(q, q2, p);
        var o4 = Point2D.orientation(q, q2, b);

        if (o1 != o2 && o3 != o4) return true;

        // Special Cases
        // p, b and q are colinear and q lies on segment p-b
        if (o1 == 0 && onSegment(p, q, b)) return true;
        // p, b and q2 are colinear and q2 lies on segment p-b
        if (o2 == 0 && onSegment(p, q2, b)) return true;
        // q, q2 and p are colinear and p lies on segment q-q2
        if (o3 == 0 && onSegment(q, p, q2)) return true;
        // q, q2 and b are colinear and b lies on segment q-q2
        if (o4 == 0 && onSegment(q, b, q2)) return true;

        return false;
    }

    public static function onSegment(p:Point2D, r:Point2D, q:Point2D):Bool {
            return r.x <= Math.max(p.x, q.x) && r.x >= Math.min(p.x, q.x) &&
                   r.y <= Math.max(p.y, q.y) && r.y >= Math.min(p.y, q.y);
        }
    @:op([]) public inline function arrayRead(n:Int) if (n == 0) return a; else return b;

    public inline function hasEndpoints( p1 : Point2D, p2 : Point2D ) {
        return (a == p1 && b == p2) || (a == p2 && b == p1);
    }
    public inline function hasEndpoint( p1 : Point2D ) {
        return a == p1 || b == p1;
    }
}

