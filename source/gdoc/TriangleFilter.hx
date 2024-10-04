package gdoc;


class TriangleFilter {
    public static function filterTriangles(triangles: Array<Triangle2D>, polygons: Array<Polygon2D>): Array<Triangle2D> {
        var filteredTriangles = new Array<Triangle2D>();
        
        for (tri in triangles) {
            var remove = false;
            for (polygon in polygons) {
                if (trianglesOverlapPolygon(tri, polygon)) {
                    remove = true;
                    break; // No need to check other polygons
                }
            }
            if (!remove) {
                filteredTriangles.push(tri);
            }
        }
        
        return filteredTriangles;
    }
    
    private static function trianglesOverlapPolygon(tri: Triangle2D, polygon: Polygon2D): Bool {
        // Check if any edge of the triangle intersects any edge of the polygon
        var triEdges = tri.getEdges();
        var polyEdges = polygon.getAsEdges();
        
        for (triEdge in triEdges) {
            for (polyEdge in polyEdges) {
                if (segmentsIntersect(triEdge.a, triEdge.b, polyEdge.a, polyEdge.b)) {
                    return true; // Overlapping edges detected
                }
            }
        }
        
        // Check if any vertex of the triangle is inside the polygon
        if (polygon.containsPoint(tri.a) || polygon.containsPoint(tri.b) || polygon.containsPoint(tri.c)) {
            return true; // Triangle is partially or entirely inside the polygon
        }
        
        // Check if any vertex of the polygon is inside the triangle
        for (p in polygon) {
            if (tri.containsPoint(p)) {
                return true; // Polygon is partially inside the triangle
            }
        }
        
        return false; // No overlapping or containment detected
    }

    private static function segmentsIntersect(p1: Point2D, p2: Point2D, q1: Point2D, q2: Point2D): Bool {
        var o1 = orientation(p1, p2, q1);
        var o2 = orientation(p1, p2, q2);
        var o3 = orientation(q1, q2, p1);
        var o4 = orientation(q1, q2, p2);
        
        // General case
        if (o1 != o2 && o3 != o4) {
            return true;
        }
        
        // Special Cases
        // p1, p2 and q1 are colinear and q1 lies on segment p1p2
        if (o1 == 0 && onSegment(p1, q1, p2)) return true;
        
        // p1, p2 and q2 are colinear and q2 lies on segment p1p2
        if (o2 == 0 && onSegment(p1, q2, p2)) return true;
        
        // q1, q2 and p1 are colinear and p1 lies on segment q1q2
        if (o3 == 0 && onSegment(q1, p1, q2)) return true;
        
        // q1, q2 and p2 are colinear and p2 lies on segment q1q2
        if (o4 == 0 && onSegment(q1, p2, q2)) return true;
        
        return false; // No intersection
    }
    
    private static function orientation(p: Point2D, q: Point2D, r: Point2D): Int {
        var val = (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x);
        if (val == 0) return 0; // Colinear
        return (val > 0) ? 1 : 2; // Clockwise or Counterclockwise
    }
    
    private static function onSegment(p: Point2D, q: Point2D, r: Point2D): Bool {
        return q.x <= Math.max(p.x, r.x) && q.x >= Math.min(p.x, r.x) &&
               q.y <= Math.max(p.y, r.y) && q.y >= Math.min(p.y, r.y);
    }


}
