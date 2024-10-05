package gdoc;

import gdoc.Point2D;


@:forward
@:forward.new
abstract PointField2D(Array<Point2D>) from Array<Point2D> to Array<Point2D> {
    
    public function mergeAndRemap(distance:Float = 1e-6) : {points:PointField2D, indices:Array<Int>} {
        var visited = new Map<Int, Array<{p:Point2D,i:Int}>>();
        var newPoints = new Array<Point2D>();
        var dsquared = distance * distance;

        function getIndex(p:Point2D) : Int{
            var key = p.getHash();
            if (!visited.exists(key)) {
                visited.set(key, []);
            }
            var list = visited.get(key);
            for (c in list) {
                if (c.p.withinSqared(p, dsquared)) {
                    return c.i;
                }
            }
            var idx = newPoints.length;
            visited.get(key).push({p:p, i:idx});
            newPoints.push(p);
            return idx;
        }

        var remap = new Array<Int>();
        for (p in this) {
            var idx = getIndex(p);    
            remap.push(idx);
        }

        return {points:newPoints, indices:remap};
    }

}

