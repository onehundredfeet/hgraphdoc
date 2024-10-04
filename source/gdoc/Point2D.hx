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

