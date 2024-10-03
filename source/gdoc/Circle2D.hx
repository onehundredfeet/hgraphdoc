package gdoc;

// Circle.hx
class Circle {
    public var center:Point2D;
    public var radius:Float;

    public function new(center:Point2D, radius:Float) {
        this.center = center;
        this.radius = radius;
    }

    public function contains(p:Point2D):Bool {
        var dx = p.x - center.x;
        var dy = p.y - center.y;
        return (dx * dx + dy * dy) <= (radius * radius);
    }
}
