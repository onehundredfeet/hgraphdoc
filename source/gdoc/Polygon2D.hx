package gdoc;

@:forward
@:forward.new
abstract Polygon2D(Array<Point2D>) from Array<Point2D> to Array<Point2D> {

     public static function isConvex(prev:Point2D, curr:Point2D, next:Point2D):Bool {
        return Point2D.orientation(prev, curr, next) > 0;
    }
    

    public function copy():Polygon2D {
       return this.copy();
    }
    //  shoelace formula
    public function isCounterClockwise():Bool {
        var sum = 0.0;
        for (i in 0...this.length) {
            var current = this[i];
            var next = this[(i + 1) % this.length];
            sum += (current.x * next.y) - (next.x * current.y);
        }
        return sum > 0;
    }
    
}