package gdoc;


class Point2D {
    public var x:Float;
    public var y:Float;

    public inline function new(x:Float, y:Float) {
        this.x = x;
        this.y = y;
    }

    public inline function dot(v:Point2D):Float {
        return x * v.x + y * v.y;
    }
    public function toString():String {
        return 'Point2D(' + x + ', ' + y  + ')';
    }
    public function normalize(): Void {
        var length = Math.sqrt(this.x * this.x + this.y * this.y);
        if (length > 1e-12) { // Prevent division by zero
            this.x /= length;
            this.y /= length;
        }
    }

    public function distanceTo(p:Point2D):Float {
        return Math.sqrt(Math.pow(this.x - p.x, 2) + Math.pow(this.y - p.y, 2));
    }

    // returns positive if p3 is to the left of the line p1->p2
    public static inline function orientation(p1:Point2D, p2:Point2D, p3:Point2D):Float {
        return (p2.x - p1.x) * (p3.y - p1.y) - 
               (p2.y - p1.y) * (p3.x - p1.x);
    }

    public function eqval( p:Point2D, epsilon:Float = 1e-12):Bool {
        return Math.abs(this.x - p.x) < epsilon && Math.abs(this.y - p.y) < epsilon;
    }
    public inline function withinSquaredXY( x:Float, y:Float, distanceSquared:Float):Bool {
        var dx = this.x - x;
        var dy = this.y - y;
        return dx * dx + dy * dy <= distanceSquared;
    }

    public inline function withinSquaredPoint( p:Point2D, distanceSquared:Float):Bool {
        var dx = this.x - p.x;
        var dy = this.y - p.y;
        return dx * dx + dy * dy <= distanceSquared;
    }

    public static inline function withinSquaredXYXY( x:Float, y:Float, px:Float, py:Float, distanceSquared:Float):Bool {
        var dx = x - px;
        var dy = y - py;
        return dx * dx + dy * dy <= distanceSquared;
    }

    static inline final HASH_PRECISION = 1e5;
    static inline final MODULUS = 0x7FFFFFFF; // Example modulus for 32-bit systems

    public inline function getHash():Int {
        var prime1:Int = 23459;
        var prime2:Int = 54323;
        
        // Scale and round coordinates to handle floating-point precision
        var aX:Int = Math.round(x * HASH_PRECISION);
        var aY:Int = Math.round(y * HASH_PRECISION);
        
        // Compute individual hashes for both points using the same primes
        var hashA:Int = (aX * prime1 + aY * prime2) % MODULUS;

        return hashA;
    }

    public inline function subtract(p2:Point2D):Point2D {
        return new Point2D(this.x - p2.x, this.y - p2.y);
    }

    public inline function crossProduct(v2:Point2D):Float {
        return this.x * v2.y - this.y * v2.x;
    }

    public static function computeCentroid2D(vertices:Array<Point2D>):Point2D {
        var x = 0.0;
        var y = 0.0;
        for (v in vertices) {
            x += v.x;
            y += v.y;
        }
        var n = vertices.length;
        return new Point2D(x / n, y / n);
    }
    
}

