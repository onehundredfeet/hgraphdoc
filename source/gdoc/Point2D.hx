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
}



function computeCentroid2D(vertices:Array<Point2D>):Point2D {
    var x = 0.0;
    var y = 0.0;
    for (v in vertices) {
        x += v.x;
        y += v.y;
    }
    var n = vertices.length;
    return new Point2D(x / n, y / n);
}
