package gdoc;


@:forward
@:forward.new
abstract WeightedPoint2D(Point3D) from Point3D to Point3D {
	public static function fromPoint2D(point:Point2D, weight:Float):WeightedPoint2D {
		return new WeightedPoint2D(point.x, point.y, weight);
	}

	public function lift():Point3D {
		var newZ = this.x * this.x + this.y * this.y - this.z;
		return new Point3D(this.x, this.y, newZ);
	}

    public var weight(get,set):Float;
    public inline function get_weight():Float return this.z;
    public inline function set_weight(value:Float):Float {
        this.z = value;
        return value;
    }

}