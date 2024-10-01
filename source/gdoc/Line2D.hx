package gdoc;

@:forward
abstract Line2D(Point3D) from Point3D {
    public inline static function fromPoints(p1:Point2D, p2:Point2D):Line2D {
        var a = p2.y - p1.y;
        var b = p1.x - p2.x;
        var c = a * p1.x + b * p1.y;
        return new Point3D(a, b, c);
    }

    public inline static function fromCoefficients(a:Float, b:Float, c:Float):Line2D {
        return new Point3D(a, b, c);
    }

    public inline function isPointOn( point:Point2D, epsilon:Float = 1e-12):Bool {
        var lhs:Float = this.x * point.x + this.y * point.y + this.z;
        return Math.abs(lhs) < epsilon;
    }
    public function computeIntersection(line2:Line2D, epsilon:Float = 1e-12):Point2D {
        var a1:Float = this.x;
        var b1:Float = this.y;
        var c1:Float = this.z;

        var a2:Float = line2.x;
        var b2:Float = line2.y;
        var c2:Float = line2.z;

        var determinant:Float = a1 * b2 - a2 * b1;
        if (Math.abs(determinant) < epsilon) {
            // Lines are parallel
            return null;
        }

        var x:Float = (b2 * (-c1) - b1 * (-c2)) / determinant;
        var y:Float = (a1 * (-c2) - a2 * (-c1)) / determinant;
        return new Point2D(x, y);
    }
}