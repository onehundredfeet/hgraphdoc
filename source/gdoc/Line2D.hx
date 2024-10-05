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


    public static function segmentsIntersect(a:Point2D, b:Point2D, c:Point2D, d:Point2D, includeVertices = false):Bool {
        if (includeVertices) {
            if (a == c || a == d || b == c || b == d) return true;
        } else {
            if (a == c || a == d || b == c || b == d) return false;
        }

        var o1 = Point2D.orientation(a, b, c);
        var o2 = Point2D.orientation(a, b, d);
        var o3 = Point2D.orientation(c, d, a);
        var o4 = Point2D.orientation(c, d, b);

        if (o1 != o2 && o3 != o4) return true;

        return false;
    }

    static inline final EPSILON = 1e-12;

    public static function segmentIntersectsCircle(p1:Point2D, p2:Point2D, center:Point2D, radius:Float):Bool {
        var dx = p2.x - p1.x;
        var dy = p2.y - p1.y;
        var fx = p1.x - center.x;
        var fy = p1.y - center.y;
        
        var a = dx * dx + dy * dy;
        var b = 2 * (fx * dx + fy * dy);
        var c = (fx * fx + fy * fy) - radius * radius;
        
        var discriminant = b * b - 4 * a * c;
        if (discriminant < -EPSILON) {
            return false; 
        }
        
        discriminant = Math.sqrt(Math.max(discriminant, 0)); // Clamp to zero if very small negative due to precision
        
        var t1 = (-b - discriminant) / (2 * a);
        var t2 = (-b + discriminant) / (2 * a);
        
        if ((t1 >= -EPSILON && t1 <= 1 + EPSILON) || (t2 >= -EPSILON && t2 <= 1 + EPSILON)) {
            return true; // Intersection occurs within the segment
        }
        
        return false; 
    }

    public static function segmentOverlapsCircle(p1:Point2D, p2:Point2D, center:Point2D, radius:Float) {
        final r2 = radius * radius;
        var point1Inside = center.withinSqared(p1, r2);
        var point2Inside = center.withinSqared(p2, r2);
        if (point1Inside || point2Inside) return true;

        return segmentIntersectsCircle(p1, p2, center, radius);
    }
}