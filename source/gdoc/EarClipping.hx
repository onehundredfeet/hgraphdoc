package gdoc;


class EarClipping {
    

    public static function triangulate(vertices:Polygon2D):Array<Triangle2D> {
        var triangles = new Array<Triangle2D>();
        
        
        // Clean the polygon by removing consecutive duplicate points
        var cleaned = removeDuplicatePoints(vertices);
       
        if (cleaned.length < 3) {
            return triangles; // Not a valid polygon
        }

        var remaining = cleaned.copy();
        
        // Ensure the polygon is oriented counter-clockwise
        if (!remaining.isCounterClockwise()) {
            remaining.reverse();
        }
        
        var vertexCount = remaining.length;
        
        // Early exit if the polygon is already a triangle
        if (vertexCount < 3) {
            return triangles; // Not a valid polygon
        } else if (vertexCount == 3) {
            triangles.push(new Triangle2D(remaining[0], remaining[1], remaining[2]));
            return triangles;
        }
        
        var indices = new Array<Int>();
        for (i in 0...remaining.length) {
            indices.push(i);
        }
        
        var count = 0; // Counter to prevent infinite loops
        var maxCount = vertexCount * vertexCount;
        
        while (indices.length > 3 && count < maxCount) {
            var earFound = false;
            var n = indices.length;
            
            for (i in 0...n) {
                var prevIndex = indices[(i - 1 + n) % n];
                var currIndex = indices[i];
                var nextIndex = indices[(i + 1) % n];
                
                var prev = remaining[prevIndex];
                var curr = remaining[currIndex];
                var next = remaining[nextIndex];
                
                if (Polygon2D.isConvex(prev, curr, next)) {
                    // Check if any other point lies inside the triangle
                    var ear = true;
                    for (j in 0...n) {
                        var pointIndex = indices[j];
                        if (pointIndex == prevIndex || pointIndex == currIndex || pointIndex == nextIndex) {
                            continue;
                        }
                        var p = remaining[pointIndex];
                        if (Triangle2D.triangleContainsPoint(p, prev, curr, next)) {
                            ear = false;
                            break;
                        }
                    }
                    
                    if (ear) {
                        // Clip the ear
                        triangles.push(new Triangle2D(prev, curr, next));
                        for (j in i...indices.length) {
                            indices[j] = indices[j + 1];
                        }
                        indices.resize(indices.length - 1);
                        earFound = true;
                        break;
                    }
                }
            }
            
            if (!earFound) {
                // No ear found; possibly a malformed polygon
                break;
            }
            
            count++;
        }
        
        // Add the remaining triangle
        if (indices.length == 3) {
            var a = remaining[indices[0]];
            var b = remaining[indices[1]];
            var c = remaining[indices[2]];
            triangles.push(new Triangle2D(a, b, c));
        }
        
        return triangles;
    }
    

    static function removeDuplicatePoints(polygon:Polygon2D):Polygon2D {
        if (polygon.length == 0) return [];
        var cleaned = [polygon[0]];
        for (i in 1...polygon.length) {
            if (!polygon[i].eqval(cleaned[cleaned.length - 1])) {
                cleaned.push(polygon[i]);
            }
        }
        // Check if first and last points are duplicates
        if (cleaned.length > 1 && cleaned[0].eqval(cleaned[cleaned.length - 1])) {
            cleaned.pop();
        }
        return cleaned;
    }

}
