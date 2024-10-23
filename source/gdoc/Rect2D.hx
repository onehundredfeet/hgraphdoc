package gdoc;

class Rect2D {
    // setting min will move the box
    public var xmin:Float;
    public var ymin:Float;

    // setting the max / dimensions will resize the bux
    public var ymax:Float;
    public var xmax:Float;

    public var width(get, set):Float;
    function get_width():Float return this.xmax - this.xmin;
    function set_width(value:Float):Float {
        this.xmax = this.xmin + value;
        return value;
    }

    public var height(get, set):Float;
    function get_height():Float return this.ymax - this.ymin;
    function set_height(value:Float):Float {
        this.ymax = this.ymin + value;
        return value;
    }

    public inline function new(xmin:Float, ymin:Float, xmax:Float, ymax:Float) {
        this.xmin = xmin;
        this.ymin = ymin;
        this.xmax = xmax;
        this.ymax = ymax;
    }

    public function getCenter() : Point2D {
        return new Point2D((this.xmin + this.xmax) * 0.5, (this.ymin + this.ymax) * 0.5);
    }

    public function getMin() : Point2D {
        return new Point2D(this.xmin, this.ymin);
    }
    public function getMax() : Point2D {
        return new Point2D(this.xmax, this.ymax);
    }
    public function getDiagonalLength() : Float {
        var w = this.width;
        var h = this.height;
        return Math.sqrt(w * w + h * h);
    }
    // Compute the bounding box of the polygon
    public static function fromPoints(points:Array<Point2D>):Rect2D {
        if (points.length == 0) {
            return new Rect2D(0, 0, 0, 0);
        }
        var minX = Math.POSITIVE_INFINITY;
        var maxX = Math.NEGATIVE_INFINITY;
        var minY = Math.POSITIVE_INFINITY;
        var maxY = Math.NEGATIVE_INFINITY;
        for (v in points) {
            if (v.x < minX) minX = v.x;
            if (v.x > maxX) maxX = v.x;
            if (v.y < minY) minY = v.y;
            if (v.y > maxY) maxY = v.y;
        }
        return new Rect2D( minX, minY, maxX, maxY );
    }

    public static function fromGraph(g:NodeGraph):Rect2D {
        if (g.nodes.length == 0) {
            return new Rect2D(0, 0, 0, 0);
        }

        var minX = g.nodes[0].x;
        var maxX = g.nodes[0].x;
        var minY = g.nodes[0].y;
        var maxY = g.nodes[0].y;
        for (n in g.nodes) {
            if (n.x < minX) minX = n.x;
            if (n.x > maxX) maxX = n.x;
            if (n.y < minY) minY = n.y;
            if (n.y > maxY) maxY = n.y;
        }

        return new Rect2D( minX, minY, maxX, maxY );
    }

    public inline function expandToInclude(p:Point2D):Void {
        if (p.x < this.xmin) this.xmin = p.x;
        if (p.x > this.xmax) this.xmax = p.x;
        if (p.y < this.ymin) this.ymin = p.y;
        if (p.y > this.ymax) this.ymax = p.y;
    }
    public inline function expandToIncludeXY( x:Float, y:Float ):Void {
        if (x < this.xmin) this.xmin = x;
        if (x > this.xmax) this.xmax = x;
        if (y < this.ymin) this.ymin = y;
        if (y > this.ymax) this.ymax = y;
    }
    public function expandToIncludePoints(points:Array<Point2D>):Void {
        for (p in points) {
            this.expandToInclude(p);
        }
    }
    public function expandToIncludeTriangles(triangles:Array<Triangle2D>):Void {
        for (t in triangles) {
            this.expandToInclude(t.a);
            this.expandToInclude(t.b);
            this.expandToInclude(t.c);
        }
    }

    public function scale( scale:Float ):Void {
        var dx = this.width;
        var dy = this.height;

        var cx = (this.xmin + this.xmax) / 2;
        var cy = (this.ymin + this.ymax) / 2;

        this.xmin = cx - dx * scale / 2;
        this.ymin = cy - dy * scale / 2;
        this.xmax = cx + dx * scale / 2;
        this.ymax = cy + dy * scale / 2;
    }

    public static function infiniteEmpty() : Rect2D {
        return new Rect2D( Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY );
    }

    public function toPolygon() : Polygon2D {
        return [
            new Point2D(this.xmin, this.ymin),
            new Point2D(this.xmax, this.ymin),
            new Point2D(this.xmax, this.ymax),
            new Point2D(this.xmin, this.ymax)
        ];
    }

    public function uniformRandomPoints(numPoints : Int, random:Random = null):Array<Point2D> {
        if (random == null) {
            random = new Random();
        }

        var width = this.width;
        var height = this.height;
        // Initialize points randomly within the bounding box
        var points = new Array<Point2D>();
        for (i in 0...numPoints) {
            var x = random.random() * width + xmin;
            var y = random.random() * height + ymin;
            points.push(new Point2D(x, y));
        }

        return points;
    }
}