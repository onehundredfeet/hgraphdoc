package grph;

// Circle.hx
class Circle2D {
    public var x : Float;
    public var y : Float;
    public var radius:Float;

    public function new(x : Float, y : Float, radius:Float) {
        this.x = x;
        this.y = y;
        this.radius = radius;
    }

    public function contains(p:Point2D):Bool {
        var dx = p.x - x;
        var dy = p.y - y;
        return (dx * dx + dy * dy) <= (radius * radius);
    }

    public inline function overlapsSegment(a : Point2D, b : Point2D): Bool {
        return Line2D.segmentOverlapsCircle(a, b, x,y, radius);
    }

}
