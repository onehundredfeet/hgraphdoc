package gdoc;

class Intersect2D {
    public static function isTriangleOverlapPolygon(triangle:Triangle2D, polygon:Polygon2D):Bool {
        if (polygon.containsPoint(triangle.a) || polygon.containsPoint(triangle.b) || polygon.containsPoint(triangle.c)) {
            return true;
        }

        return false;
    }

    public static function getOverlapingTrianglesWithPolygon(triangles:Array<Triangle2D>, polygon:Polygon2D):Array<Triangle2D> {
        var result = new Array<Triangle2D>();
        for (triangle in triangles) {
            if (Intersect2D.isTriangleOverlapPolygon(triangle, polygon)) {
                result.push(triangle);
            }
        }
        return result;
    }
}