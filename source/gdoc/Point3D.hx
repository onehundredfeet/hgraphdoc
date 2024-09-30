package gdoc;

#if hvector
typedef Point3D = hvector.Float3;
#else
class Point3D {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public inline function new(x:Float, y:Float, z:Float) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public inline function dot(v:Point3D):Float {
        return x * v.x + y * v.y + z * v.z;
    }
    public function toString():String {
        return 'Point3D(' + x + ', ' + y + ', ' + z + ')';
    }
}
#end


function areCoplanar(a:Point3D, b:Point3D, c:Point3D, d:Point3D):Bool {
    var u = new Point3D(b.x - a.x, b.y - a.y, b.z - a.z);
    var v = new Point3D(c.x - a.x, c.y - a.y, c.z - a.z);
    var w = new Point3D(d.x - a.x, d.y - a.y, d.z - a.z);
    var nx = u.y * v.z - u.z * v.y;
    var ny = u.z * v.x - u.x * v.z;
    var nz = u.x * v.y - u.y * v.x;
    var dotProduct = nx * w.x + ny * w.y + nz * w.z;
    return Math.abs(dotProduct) < 1e-6;
}

function computeCentroid(vertices:Array<Point3D>):Point3D {
    var x = 0.0;
    var y = 0.0;
    var z = 0.0;
    for (v in vertices) {
        x += v.x;
        y += v.y;
        z += v.z;
    }
    var n = vertices.length;
    return new Point3D(x / n, y / n, z / n);
}

function computeNormal(a:Point3D, b:Point3D, c:Point3D):Point3D {
    var u = new Point3D(b.x - a.x, b.y - a.y, b.z - a.z);
    var v = new Point3D(c.x - a.x, c.y - a.y, c.z - a.z);
    var nx = u.y * v.z - u.z * v.y;
    var ny = u.z * v.x - u.x * v.z;
    var nz = u.x * v.y - u.y * v.x;

    var length = Math.sqrt(nx * nx + ny * ny + nz * nz);
    nx /= length;
    ny /= length;
    nz /= length;
    return new Point3D(nx, ny, nz);
}

function isPointAbovePlane(normal:Point3D, origin:Point3D,point:Point3D):Bool {
    var dx = point.x - origin.x;
    var dy = point.y - origin.y;
    var dz = point.z - origin.z;
    var dotProduct = normal.x * dx + normal.y * dy + normal.z * dz;
    return dotProduct > 0;
}

function pointToPlaneDistance(normal:Point3D, origin:Point3D, point:Point3D):Float {
    var dx = point.x - origin.x;
    var dy = point.y - origin.y;
    var dz = point.z - origin.z;
    var numerator = Math.abs(normal.x * dx + normal.y * dy + normal.z * dz);
    var denominator = Math.sqrt(normal.x * normal.x + normal.y * normal.y + normal.z * normal.z);
    return numerator / denominator;
}

final   EPSILON = 1e-6;

function areColinear(a:Point3D, b:Point3D, c:Point3D):Bool {
    // Compute components of vectors ab and ac
    var abx = b.x - a.x;
    var aby = b.y - a.y;
    var abz = b.z - a.z;

    var acx = c.x - a.x;
    var acy = c.y - a.y;
    var acz = c.z - a.z;

    // Compute the cross product components of ab × ac
    var cross_x = aby * acz - abz * acy;
    var cross_y = abz * acx - abx * acz;
    var cross_z = abx * acy - aby * acx;

    // Compute the squared length of the cross product vector
    var lengthSquared = cross_x * cross_x + cross_y * cross_y + cross_z * cross_z;

    // Compare the squared length with EPSILON squared
    return lengthSquared < EPSILON * EPSILON;
}
